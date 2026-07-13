//
//  HospitalService.swift
//  CodeBlack
//
//  Hospitals 태그 API. 병원 검색/상세/추천.
//

import Foundation

struct HospitalService {

    var client = APIClient(baseURL: AppConfig.baseURL)

    /// GET /api/hospitals/search — 공공데이터 응급의료기관 검색.
    /// - Parameters:
    ///   - city: 시도, district: 시군구, keyword: 검색어(모두 선택)
    ///   - page: 1부터, size: 1...100 (기본 20)
    func search(
        city: String? = nil,
        district: String? = nil,
        keyword: String? = nil,
        page: Int = 1,
        size: Int = 20
    ) async throws -> [HospitalSearchResponse] {
        try await client.send(
            .get, "/api/hospitals/search",
            query: [
                "city": city,
                "district": district,
                "keyword": keyword,
                "page": String(page),
                "size": String(size)
            ]
        )
    }

    /// GET /api/hospitals/{hospitalId} — 병원 상세 조회.
    func detail(hospitalId: String) async throws -> HospitalDetailResponse {
        let segment = APIClient.encodePathSegment(hospitalId)
        return try await client.send(.get, "/api/hospitals/\(segment)")
    }

    /// GET /api/hospitals/recommendations — 현재 위치·지역·장비 기준 추천 병원.
    /// - Parameters:
    ///   - latitude: -90...90, longitude: -180...180 (필수)
    ///   - sort: 정렬 기준(기본 추천점수)
    ///   - requiredEquipment: 필요 장비 필터
    func recommendations(
        latitude: Double,
        longitude: Double,
        city: String? = nil,
        district: String? = nil,
        keyword: String? = nil,
        sort: HospitalSort = .recommendation,
        requiredEquipment: [EquipmentType] = []
    ) async throws -> [HospitalRecommendationResponse] {
        var query: [String: String?] = [
            "latitude": String(latitude),
            "longitude": String(longitude),
            "city": city,
            "district": district,
            "keyword": keyword,
            "sort": sort.rawValue
        ]
        // 배열 쿼리(requiredEquipment)는 Spring이 콤마 구분 문자열을 List<Enum>으로
        // 바인딩하므로 콤마로 조인해 전달한다. (예: "CT,MRI")
        if !requiredEquipment.isEmpty {
            query["requiredEquipment"] = requiredEquipment.map(\.rawValue).joined(separator: ",")
        }
        return try await client.send(.get, "/api/hospitals/recommendations", query: query)
    }
}
