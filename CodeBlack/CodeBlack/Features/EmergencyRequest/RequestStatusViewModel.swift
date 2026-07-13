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

    /// 진행 스텝. (전송완료 → 확인대기 → 이송준비)
    enum Step: Int, CaseIterable {
        case sent = 0      // 전송완료
        case waiting = 1   // 확인대기
        case ready = 2     // 이송준비

        var title: String {
            switch self {
            case .sent: return "전송완료"
            case .waiting: return "확인대기"
            case .ready: return "이송준비"
            }
        }
    }

    private(set) var status: EmergencyRequestStatusResponse?
    private(set) var errorMessage: String?
    private(set) var isClosed = false

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
        pollingTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.fetch(requestId: requestId)
                if self.isAccepted || self.isClosed { break }
                try? await Task.sleep(nanoseconds: self.pollInterval * 1_000_000_000)
            }
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
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
