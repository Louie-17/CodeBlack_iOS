//
//  EmergencyRequestService.swift
//  CodeBlack
//
//  Emergency Requests 태그 API. 구급대원 환자 수용 요청 생성/현황.
//

import Foundation

struct EmergencyRequestService {

    var client = APIClient(baseURL: AppConfig.baseURL)

    /// POST /api/emergency-requests — 선택한 병원들에게 환자 수용 요청 생성.
    func create(_ request: CreateEmergencyRequest) async throws -> EmergencyRequestResponse {
        try await client.send(.post, "/api/emergency-requests", body: request)
    }

    /// GET /api/emergency-requests/{requestId} — 요청 + 대상 병원별 상태 조회.
    func detail(requestId: Int64) async throws -> EmergencyRequestResponse {
        try await client.send(.get, "/api/emergency-requests/\(requestId)")
    }

    /// GET /api/emergency-requests/{requestId}/status — 폴링용 현황 조회.
    func status(requestId: Int64) async throws -> EmergencyRequestStatusResponse {
        try await client.send(.get, "/api/emergency-requests/\(requestId)/status")
    }
}
