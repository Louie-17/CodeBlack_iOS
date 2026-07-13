//
//  HospitalListViewModel.swift
//  CodeBlack
//
//  가까운 응급실 찾기 화면 뷰모델.
//  정렬 탭(거리순/병상순/AI 추천) → 추천 API sort 파라미터로 조회.
//

import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class HospitalListViewModel {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var hospitals: [HospitalRecommendationResponse] = []
    var sort: HospitalSort = .recommendation

    private let service = HospitalService()

    /// 정렬 탭 표시 순서.
    static let sortTabs: [HospitalSort] = [.distance, .beds, .recommendation]

    static func tabTitle(_ sort: HospitalSort) -> String {
        switch sort {
        case .distance: return "거리순"
        case .beds: return "병상순"
        case .recommendation: return "AI 추천"
        }
    }

    /// 현재 좌표 기준 추천 병원 조회.
    func load(coordinate: CLLocationCoordinate2D) async {
        loadState = .loading
        do {
            hospitals = try await service.recommendations(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                sort: sort
            )
            loadState = .loaded
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            loadState = .failed(message)
        }
    }

    /// 정렬 변경 후 재조회.
    func changeSort(_ newSort: HospitalSort, coordinate: CLLocationCoordinate2D) async {
        guard newSort != sort else { return }
        sort = newSort
        await load(coordinate: coordinate)
    }
}
