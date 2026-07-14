//
//  HospitalRequestListViewModel.swift
//  CodeBlack
//
//  수신된 요청 목록 뷰모델. GET /api/hospital/requests?loginId=.
//

import CoreLocation
import Observation

@MainActor
@Observable
final class HospitalRequestListViewModel {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var requests: [HospitalRequestResponse] = []

    private let service = HospitalRequestService()

    func load(loginId: String) async {
        loadState = .loading
        do {
            requests = try await service.list(loginId: loginId)
            loadState = .loaded
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            loadState = .failed(message)
        }
    }

    /// 병원 좌표 기준 환자까지 거리(km). 좌표 없으면 nil.
    static func distanceKilometers(
        from hospital: CLLocationCoordinate2D?,
        toLatitude latitude: Double?,
        longitude: Double?
    ) -> Double? {
        guard let hospital, let latitude, let longitude else { return nil }
        let a = CLLocation(latitude: hospital.latitude, longitude: hospital.longitude)
        let b = CLLocation(latitude: latitude, longitude: longitude)
        return a.distance(from: b) / 1000
    }
}
