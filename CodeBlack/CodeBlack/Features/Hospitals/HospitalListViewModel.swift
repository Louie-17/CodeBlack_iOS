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
    /// 정렬별 조회 결과 캐시. 이미 조회한 정렬로 재전환 시 재조회 없이 사용(갱신은 당겨서 새로고침).
    @ObservationIgnored private var sortCache: [HospitalSort: [HospitalRecommendationResponse]] = [:]

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
            let result = try await service.recommendations(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                sort: sort
            )
            hospitals = result
            sortCache[sort] = result
            loadState = .loaded
            prefetchBeds(count: HospitalListViewModel.prefetchCount)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            loadState = .failed(message)
        }
    }

    /// 스피너로 화면을 교체하지 않고 목록만 갱신(당겨서 새로고침용). 실패 시 기존 데이터 유지.
    func refresh(coordinate: CLLocationCoordinate2D) async {
        if let result = try? await service.recommendations(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            sort: sort
        ) {
            hospitals = result
            sortCache[sort] = result
            accurateBeds = [:]   // 정확 병상 캐시 초기화 → 최신값 재조회
            if loadState != .loaded { loadState = .loaded }
            prefetchBeds(count: HospitalListViewModel.prefetchCount)
        }
    }

    /// 정렬 변경. 이미 조회한 정렬이면 캐시값 사용(재조회 안 함), 처음이면 조회.
    func changeSort(_ newSort: HospitalSort, coordinate: CLLocationCoordinate2D) async {
        guard newSort != sort else { return }
        sort = newSort
        if let cached = sortCache[newSort] {
            hospitals = cached
            loadState = .loaded
        } else {
            await load(coordinate: coordinate)
        }
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
