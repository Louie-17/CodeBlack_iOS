//
//  HospitalRequestDetailViewModel.swift
//  CodeBlack
//
//  수신된 요청 상세 뷰모델. 요청 수락 처리.
//

import Foundation
import Observation

@MainActor
@Observable
final class HospitalRequestDetailViewModel {

    enum AcceptState: Equatable {
        case idle
        case accepting
        case failed(String)
    }

    private(set) var acceptState: AcceptState = .idle
    /// 수락 후 갱신된 상태.
    private(set) var updatedStatus: HospitalRequestStatus?

    private let service = HospitalRequestService()

    var isAccepting: Bool { acceptState == .accepting }

    /// POST accept. 성공 시 updatedStatus 갱신.
    func accept(requestId: Int64, loginId: String) async {
        acceptState = .accepting
        do {
            let result = try await service.accept(requestId: requestId, loginId: loginId)
            updatedStatus = result.status ?? .accepted
            acceptState = .idle
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            acceptState = .failed(message)
        }
    }
}
