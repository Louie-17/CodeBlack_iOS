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
        switch status?.status {
        case .accepted: return .ready
        case .closed: return .ready
        case .waiting, .unknown, .none: return .waiting
        }
    }

    var acceptedHospitalName: String? { status?.acceptedHospitalName }
    var isAccepted: Bool { status?.status == .accepted }

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
    }

    private func fetch(requestId: Int64) async {
        do {
            let result = try await service.status(requestId: requestId)
            status = result
            errorMessage = nil
            if result.status == .closed { isClosed = true }
            if result.status == .accepted, !didNotifyAccepted {
                didNotifyAccepted = true
                notifyAcceptedIfNeeded(requestId: requestId, hospitalName: result.acceptedHospitalName)
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// 이 요청 ID로 수락 알림을 아직 안 보냈을 때만 발송한다(화면 재진입/재생성 시 중복 방지).
    private func notifyAcceptedIfNeeded(requestId: Int64, hospitalName: String?) {
        let defaults = UserDefaults.standard
        guard defaults.integer(forKey: AppConfig.notifiedAcceptedRequestKey) != Int(requestId) else { return }
        defaults.set(Int(requestId), forKey: AppConfig.notifiedAcceptedRequestKey)
        LocalNotifier.shared.notify(
            title: "이송 준비 완료",
            body: "\(hospitalName ?? "병원")에서 환자를 수용합니다. 이송을 준비하세요."
        )
    }
}
