//
//  HealthService.swift
//  CodeBlack
//
//  Health 태그 API. 서버 상태 확인.
//

import Foundation

struct HealthService {

    var client = APIClient(baseURL: AppConfig.baseURL)

    /// GET /api/health — 서버 정상 동작 여부 확인.
    func check() async throws -> HealthResponse {
        try await client.send(.get, "/api/health")
    }
}
