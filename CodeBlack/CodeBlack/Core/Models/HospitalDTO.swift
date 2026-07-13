//
//  HospitalDTO.swift
//  CodeBlack
//
//  Hospitals 태그 DTO. 병원 검색/상세/추천.
//

import Foundation

/// GET /api/hospitals/search 응답 항목. 공공데이터 응급의료기관 검색 결과.
struct HospitalSearchResponse: Decodable, Identifiable {
    /// 공공데이터 병원 HPID
    let hospitalId: String?
    let name: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let phoneNumber: String?

    var id: String { hospitalId ?? UUID().uuidString }
}

/// GET /api/hospitals/{hospitalId} 응답. 병원 상세.
struct HospitalDetailResponse: Decodable, Identifiable {
    let hospitalId: String?
    let name: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    /// 남은 병상 수
    let availableBeds: Int?
    /// 당직 여부
    let onDuty: Bool?
    /// 응급 수용 가능 여부
    let emergencyAvailable: Bool?
    let phoneNumber: String?
    /// 보유 장비
    let equipmentTypes: [EquipmentType]?

    var id: String { hospitalId ?? UUID().uuidString }
}

/// GET /api/hospitals/recommendations 응답 항목. 추천 점수 포함.
struct HospitalRecommendationResponse: Decodable, Identifiable {
    let hospitalId: String?
    let name: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    /// 현재 위치 기준 거리(km)
    let distanceKilometers: Double?
    let availableBeds: Int?
    let onDuty: Bool?
    let emergencyAvailable: Bool?
    /// 추천 점수
    let recommendationScore: Int?
    let equipmentTypes: [EquipmentType]?

    var id: String { hospitalId ?? UUID().uuidString }
}
