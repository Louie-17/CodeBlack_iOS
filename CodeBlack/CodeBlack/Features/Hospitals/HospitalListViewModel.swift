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
    var sort: HospitalSort = .distance   // 기본 정렬: 거리순

    private let service = HospitalService()

    /// 병원별 상세 API 정확 가용병상 캐시(hospitalId → beds).
    private(set) var accurateBeds: [String: Int] = [:]
    /// 상세 조회 중복 방지용 진행 중 집합.
    @ObservationIgnored private var inFlightBeds: Set<String> = []

    /// 정렬 탭 표시 순서.
    static let sortTabs: [HospitalSort] = [.distance, .beds, .recommendation]

    static func tabTitle(_ sort: HospitalSort) -> String {
        switch sort {
        case .distance: return "거리순"
        case .beds: return "병상순"
        case .recommendation: return "AI 추천"
        }
    }

    /// 현재 좌표 + 지역(시도/시군구) 기준 추천 병원 조회.
    /// 지역은 서버 실시간 병상 조회에 필요하다(없으면 500이 날 수 있음).
    func load(coordinate: CLLocationCoordinate2D, city: String? = nil, district: String? = nil) async {
        loadState = .loading
        do {
            hospitals = try await service.recommendations(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                city: city,
                district: district,
                sort: sort
            )
            loadState = .loaded
            prefetchBeds(count: HospitalListViewModel.prefetchCount)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            loadState = .failed(message)
        }
    }

    /// 정렬 변경 후 재조회.
    func changeSort(
        _ newSort: HospitalSort,
        coordinate: CLLocationCoordinate2D,
        city: String? = nil,
        district: String? = nil
    ) async {
        guard newSort != sort else { return }
        sort = newSort
        await load(coordinate: coordinate, city: city, district: district)
    }

    /// 첫 화면에서 미리 상세 병상을 당겨올 병원 수.
    static let prefetchCount = 15

    /// 상위 N개 병원의 정확 병상을 병렬로 미리 조회한다(서버가 느려 초기 지연 완화).
    private func prefetchBeds(count: Int) {
        for hospital in hospitals.prefix(count) {
            Task { await loadAccurateBeds(for: hospital.hospitalId) }
        }
    }

    /// 셀에 표시할 가용병상 수. 상세 API로 받은 정확한 값이 있으면 그걸, 없으면 추천 값을 쓴다.
    func displayBeds(for hospital: HospitalRecommendationResponse) -> Int? {
        guard let id = hospital.hospitalId else { return hospital.availableBeds }
        return accurateBeds[id] ?? hospital.availableBeds
    }

    /// 병원 상세를 조회해 정확한 가용병상 수를 캐시한다. (셀 표시 시 1회)
    func loadAccurateBeds(for hospitalId: String?) async {
        guard let hospitalId, accurateBeds[hospitalId] == nil, !inFlightBeds.contains(hospitalId) else { return }
        inFlightBeds.insert(hospitalId)
        defer { inFlightBeds.remove(hospitalId) }
        if let detail = try? await service.detail(hospitalId: hospitalId), let beds = detail.availableBeds {
            accurateBeds[hospitalId] = beds
        }
    }
}
