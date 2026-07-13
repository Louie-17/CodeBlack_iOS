//
//  HospitalRequestService.swift
//  CodeBlack
//
//  Hospital Requests 태그 API. 병원 담당자(간호사) 요청 조회/수락.
//  JWT 도입 전까지 loginId 쿼리로 담당자를 식별한다.
//

import Foundation

struct HospitalRequestService {

    var client = APIClient(baseURL: AppConfig.baseURL)

    /// GET /api/hospital/requests — 소속 병원에 접수된 요청 목록.
    func list(loginId: String) async throws -> [HospitalRequestResponse] {
        try await client.send(.get, "/api/hospital/requests", query: ["loginId": loginId])
    }

    /// GET /api/hospital/requests/{requestId} — 요청 상세(환자 정보) 조회.
    func detail(requestId: Int64, loginId: String) async throws -> HospitalRequestResponse {
        try await client.send(
            .get, "/api/hospital/requests/\(requestId)",
            query: ["loginId": loginId]
        )
    }

    /// POST /api/hospital/requests/{requestId}/accept — 요청 수락.
    /// 수락 시 같은 환자 요청의 다른 병원 요청은 자동 취소된다.
    func accept(requestId: Int64, loginId: String) async throws -> HospitalRequestResponse {
        try await client.send(
            .post, "/api/hospital/requests/\(requestId)/accept",
            query: ["loginId": loginId]
        )
    }
}
