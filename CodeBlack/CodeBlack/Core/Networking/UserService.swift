//
//  UserService.swift
//  CodeBlack
//
//  Users 태그 API. 사용자 생성/로그인/조회.
//  비밀번호 없이 로그인 아이디로 식별한다. (토큰/Bearer 미사용)
//

import Foundation

struct UserService {

    var client = APIClient(baseURL: AppConfig.baseURL)

    /// POST /api/signup — 회원가입. 간호사는 병원 HPID/병원명을 함께 전달.
    func signup(_ request: CreateUserRequest) async throws -> ActorResponse {
        try await client.send(.post, "/api/signup", body: request)
    }

    /// POST /api/auth/login — 로그인 아이디만으로 사용자 정보 조회.
    func login(loginId: String) async throws -> ActorResponse {
        try await client.send(.post, "/api/auth/login", body: LoginRequest(loginId: loginId))
    }

    /// GET /api/me — X-Login-Id 헤더로 내 정보 조회.
    func me(loginId: String) async throws -> ActorResponse {
        try await client.send(.get, "/api/me", headers: ["X-Login-Id": loginId])
    }

    /// GET /api/paramedics/{loginId} — 구급대원 조회.
    func paramedic(loginId: String) async throws -> ActorResponse {
        let segment = APIClient.encodePathSegment(loginId)
        return try await client.send(.get, "/api/paramedics/\(segment)")
    }

    /// GET /api/nurses/{loginId} — 간호사 조회.
    func nurse(loginId: String) async throws -> ActorResponse {
        let segment = APIClient.encodePathSegment(loginId)
        return try await client.send(.get, "/api/nurses/\(segment)")
    }

    /// GET /api/actors — 등록된 사용자 목록 조회.
    func actors() async throws -> [ActorResponse] {
        try await client.send(.get, "/api/actors")
    }
}
