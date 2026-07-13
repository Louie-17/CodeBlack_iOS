//
//  NurseHospitalViewModel.swift
//  CodeBlack
//
//  간호사 회원가입 — 근무 병원 검색 뷰모델. GET /api/hospitals/search.
//

import Foundation
import Observation

@MainActor
@Observable
final class NurseHospitalViewModel {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var results: [HospitalSearchResponse] = []

    private let service = HospitalService()

    /// 병원명 키워드로 검색.
    func search(keyword: String) async {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            loadState = .idle
            return
        }
        loadState = .loading
        do {
            results = try await service.search(keyword: trimmed)
            loadState = .loaded
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            loadState = .failed(message)
        }
    }
}
