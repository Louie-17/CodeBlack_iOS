//
//  RequestStatusViewModel.swift
//  CodeBlack
//
//  요청 상태(폴링) 화면 뷰모델.
//  주기적으로 status API를 호출해 수락 병원 확정 여부를 확인한다.
//

import Foundation
import Observation

@MainActor
@Observable
final class RequestStatusViewModel {

    /// 진행 스텝. (요청 전송 완료 → 병원 확인 대기 중 → 이송 준비)
    enum Step: Int, CaseIterable {
        case sent = 0
        case waiting = 1
        case ready = 2

        var title: String {
            switch self {
            case .sent: return "요청 전송 완료"
            case .waiting: return "병원 확인 대기 중"
            case .ready: return "이송 준비"
            }
        }

        var subtitle: String {
            switch self {
            case .sent: return "구급대원 요청 전송"
            case .waiting: return "담당 의료진에게 요청 도착"
            case .ready: return "수용 승인 시 안내"
            }
        }
    }

    private(set) var status: EmergencyRequestStatusResponse?
    private(set) var errorMessage: String?
    private(set) var isClosed = false
    /// 수락 로컬 알림 중복 발송 방지.
    private var didNotifyAccepted = false
    /// 요청 전송 시각 표기(예: "오후 3:24").
    private(set) var sentTime: String?
    /// 미응답 마감 시 직접 연락할 후보 병원(call-candidates).
    private(set) var callCandidates: [CallCandidateResponse] = []
    /// AI 순차 발신 시작 응답(무응답 자동 트리거).
    private(set) var aiCall: AiCallStartResponse?
    /// 이 요청에 AI 발신이 시작되었는지(응답 상세 없이도 표시용).
    private(set) var aiCallStarted = false
    /// 이번 세션에서 AI 발신을 이미 시도했는지(중복 POST 방지).
    private var didAttemptAICall = false
    /// AI 발신 세션 실시간 상태(전화 걸림/받음).
    private(set) var aiCallStatus: AiCallStatusResponse?
    private var aiCallStatusTask: Task<Void, Never>?

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"
        return formatter
    }()

    private let service = EmergencyRequestService()
    private var pollingTask: Task<Void, Never>?

    /// 폴링 주기(초).
    private let pollInterval: UInt64 = 3

    /// 현재 활성 스텝. WAITING → 확인대기, ACCEPTED → 이송준비.
    var currentStep: Step {
        if isAccepted { return .ready }
        if isNoResponse { return .waiting }   // 미응답 마감은 이송준비로 진행하지 않음
        switch status?.status {
        case .accepted, .closed: return .ready
        case .waiting, .unknown, .none: return .waiting
        }
    }

    var acceptedHospitalName: String? { status?.acceptedHospitalName }
    /// 수락됨(ACCEPTED 또는 수락 병원 확정).
    var isAccepted: Bool { status?.status == .accepted || status?.acceptedHospitalName != nil }
    /// 수용 병원 없이 마감(전체 미응답). CLOSED인데 수락 병원 없음.
    var isNoResponse: Bool { status?.status == .closed && status?.acceptedHospitalName == nil }
    /// 대상 병원별 현황(수락/대기/미응답 등).
    var hospitals: [HospitalRequestSummary] { status?.hospitals ?? [] }
    /// AI 순차 발신 중 병원이 전화를 받음(연결 성공/통화 완료).
    var aiCallConnected: Bool {
        aiCallStatus?.connected == true || aiCallStatus?.status == "COMPLETED"
    }

    /// 요청 상태 폴링 시작. 수락/종료 시 자동 중단.
    func startPolling(requestId: Int64) {
        stop()
        Task { await LocalNotifier.shared.requestAuthorization() }
        Task { [weak self] in await self?.loadSentTime(requestId: requestId) }
        pollingTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.fetch(requestId: requestId)
                if self.isAccepted || self.isClosed { break }
                try? await Task.sleep(nanoseconds: self.pollInterval * 1_000_000_000)
            }
        }
    }

    /// 요청 상세에서 전송 시각(createdAt)을 한 번 가져와 표기용으로 저장한다.
    private func loadSentTime(requestId: Int64) async {
        guard sentTime == nil else { return }
        if let detail = try? await service.detail(requestId: requestId),
           let date = HospitalFormat.parseISO(detail.createdAt) {
            sentTime = Self.timeFormatter.string(from: date)
        }
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
        aiCallStatusTask?.cancel()
        aiCallStatusTask = nil
    }

    private func fetch(requestId: Int64) async {
        do {
            let result = try await service.status(requestId: requestId)
            status = result
            errorMessage = nil
            if result.status == .closed { isClosed = true }
            if result.status == .accepted, !didNotifyAccepted {
                didNotifyAccepted = true
                LocalNotifier.shared.notifyAcceptedRequest(requestId: requestId, hospitalName: result.acceptedHospitalName)
            }
            if isNoResponse, callCandidates.isEmpty {
                await loadCallCandidates(requestId: requestId)
            }
            if isNoResponse {
                await startAICallIfNeeded(requestId: requestId)
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// 미응답 마감 시 직접 연락 후보 병원을 조회한다.
    private func loadCallCandidates(requestId: Int64) async {
        if let list = try? await service.callCandidates(requestId: requestId) {
            callCandidates = list
        }
    }

    /// 무응답 마감 시 AI 순차 발신을 자동으로 시작한다(요청당 1회, 재진입 시 재발신 방지).
    private func startAICallIfNeeded(requestId: Int64) async {
        guard !didAttemptAICall else { return }
        didAttemptAICall = true
        let defaults = UserDefaults.standard
        // 이미 시작한 요청이면 재발신하지 않는다(재진입).
        if defaults.integer(forKey: AppConfig.aiCallStartedRequestKey) == Int(requestId) {
            aiCallStarted = true
            // 재진입 — 저장된 세션으로 상태 폴링을 재개한다.
            let sessionId = defaults.integer(forKey: AppConfig.aiCallSessionKey)
            if sessionId != 0 { startAICallStatusPolling(sessionId: Int64(sessionId)) }
            return
        }
        if let response = try? await service.startAICall(requestId: requestId) {
            defaults.set(Int(requestId), forKey: AppConfig.aiCallStartedRequestKey)
            aiCall = response
            aiCallStarted = true
            if let sessionId = response.sessionId {
                defaults.set(Int(sessionId), forKey: AppConfig.aiCallSessionKey)
                startAICallStatusPolling(sessionId: sessionId)
            }
        } else {
            didAttemptAICall = false   // 실패 시 다음 폴링에서 재시도
        }
    }

    /// AI 발신 세션 상태를 3초 간격으로 폴링한다. COMPLETED/EXHAUSTED면 종료.
    private func startAICallStatusPolling(sessionId: Int64) {
        aiCallStatusTask?.cancel()
        aiCallStatusTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                if let status = try? await self.service.aiCallStatus(sessionId: sessionId) {
                    self.aiCallStatus = status
                    if status.status == "COMPLETED" || status.status == "EXHAUSTED" { break }
                }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }

}
