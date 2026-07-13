//
//  HealthDTO.swift
//  CodeBlack
//
//  Health 태그 DTO. 서버 상태 확인.
//

import Foundation

/// GET /api/health 응답. 서버 상태.
struct HealthResponse: Decodable {
    /// 서버 상태 (예: "UP")
    let status: String?
}
