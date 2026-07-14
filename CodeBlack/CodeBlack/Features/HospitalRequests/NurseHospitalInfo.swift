//
//  NurseHospitalInfo.swift
//  CodeBlack
//
//  간호사 소속 병원 정보(이름/좌표/가용병상). 요청 목록·상세에서 공유한다.
//

import CoreLocation
import Observation

@MainActor
@Observable
final class NurseHospitalInfo {

    private(set) var hospitalId: String?
    private(set) var name: String?
    private(set) var coordinate: CLLocationCoordinate2D?
    private(set) var availableBeds: Int?

    private let service = HospitalService()

    /// 소속 병원 상세를 조회해 이름/좌표/병상을 채운다. 실패해도 fallbackName은 유지.
    func load(hospitalId: String?, fallbackName: String?) async {
        self.hospitalId = hospitalId
        self.name = fallbackName
        guard let hospitalId, !hospitalId.isEmpty else { return }
        guard let detail = try? await service.detail(hospitalId: hospitalId) else { return }
        name = detail.name ?? fallbackName
        availableBeds = detail.availableBeds
        if let lat = detail.latitude, let lng = detail.longitude {
            coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
    }
}
