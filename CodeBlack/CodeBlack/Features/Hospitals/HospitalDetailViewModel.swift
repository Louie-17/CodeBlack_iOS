//
//  HospitalDetailViewModel.swift
//  CodeBlack
//
//  병원 정보(상세) 화면 뷰모델.
//

import Foundation
import Observation

@MainActor
@Observable
final class HospitalDetailViewModel {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var detail: HospitalDetailResponse?

    private let service = HospitalService()

    func load(hospitalId: String) async {
        loadState = .loading
        do {
            detail = try await service.detail(hospitalId: hospitalId)
            loadState = .loaded
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            loadState = .failed(message)
        }
    }
}
