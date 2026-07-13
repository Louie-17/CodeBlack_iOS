//
//  AuthViewModel.swift
//  CodeBlack
//
//  인증 뷰모델. 비밀번호 없이 로그인 아이디로 식별하고, 토큰 대신 로그인 아이디를
//  세션 식별자로 Keychain에 보관한다.
//  한 번 로그인/가입하면 세션 만료(AppConfig.Session.validity) 전까지 재입력 없이 자동 로그인한다.
//
//  대화형 로그인/가입(authenticate/register)은 실패 시 throw 하고 전역 state를 흔들지 않는다.
//  → 온보딩 NavigationStack이 유지되고, 각 화면이 로컬에서 에러를 표시한다.
//

import Foundation
import Observation

@MainActor
@Observable
final class AuthViewModel {

    enum State: Equatable {
        case idle
        case loading          // 콜드 스타트 자동 로그인 중
        case authenticated
        case needsCredentials // 온보딩(웰컴/로그인/가입) 화면 표시
    }

    private(set) var state: State = .idle
    private(set) var actor: ActorResponse?

    private let userService = UserService()

    /// 현재 세션의 로그인 아이디(RBAC 호출용). 없으면 미로그인.
    var loginId: String? { KeychainStore.read(KeychainKey.loginId) }
    /// 현재 사용자 역할.
    var role: ActorRole? { actor?.role }
    var isAuthenticated: Bool {
        if case .authenticated = state { return true }
        return false
    }

    /// 저장된 세션 만료 시각.
    private var sessionExpiry: Date? {
        guard let raw = KeychainStore.read(KeychainKey.sessionExpiry),
              let epoch = TimeInterval(raw) else { return nil }
        return Date(timeIntervalSince1970: epoch)
    }

    /// 저장된 로그인 세션이 아직 유효한지(아이디 있음 + 만료 전).
    var hasValidSession: Bool {
        guard let saved = loginId, !saved.isEmpty, let expiry = sessionExpiry else { return false }
        return expiry > Date()
    }

    /// 앱 진입 시 호출. 저장된 세션이 있으면 재입력 없이 자동 로그인, 없으면 온보딩.
    func bootstrap() async {
        if AppConfig.AutoLogin.isConfigured {
            await silentLogin(AppConfig.AutoLogin.loginId)
            return
        }
        if hasValidSession, let saved = loginId {
            await silentLogin(saved)
            return
        }
        clearSession()
        state = .needsCredentials
    }

    /// 콜드 스타트 자동 로그인. 실패하면 온보딩으로(세션은 유지해 다음 실행에 재시도).
    private func silentLogin(_ loginId: String) async {
        state = .loading
        do {
            try await authenticate(loginId: loginId)
        } catch {
            state = .needsCredentials
        }
    }

    /// 로그인. 성공 시 세션 저장 + authenticated, 실패 시 throw(전역 state 유지).
    func authenticate(loginId rawLoginId: String) async throws {
        let loginId = rawLoginId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !loginId.isEmpty else { throw AuthError.emptyLoginId }
        let result = try await userService.login(loginId: loginId)
        apply(result, fallbackLoginId: loginId)
    }

    /// 회원가입. 성공 시 세션 저장 + authenticated, 실패 시 throw.
    /// 간호사는 근무 병원 HPID/병원명을 함께 전달한다(구급대원은 nil).
    func register(
        loginId rawLoginId: String,
        role: ActorRole,
        hospitalId: String? = nil,
        hospitalName: String? = nil
    ) async throws {
        let loginId = rawLoginId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !loginId.isEmpty else { throw AuthError.emptyLoginId }
        let result = try await userService.signup(
            CreateUserRequest(loginId: loginId, role: role, hospitalId: hospitalId, hospitalName: hospitalName)
        )
        apply(result, fallbackLoginId: loginId)
    }

    /// 로그아웃: 저장된 세션 삭제 후 온보딩으로.
    func logout() {
        clearSession()
        actor = nil
        state = .needsCredentials
    }

    // MARK: - 내부

    private func apply(_ result: ActorResponse, fallbackLoginId: String) {
        self.actor = result
        saveSession(loginId: result.loginId ?? fallbackLoginId)
        state = .authenticated
    }

    /// 로그인 아이디 저장 + 만료 시각을 지금부터 유효기간만큼 연장(슬라이딩).
    private func saveSession(loginId: String) {
        KeychainStore.save(loginId, for: KeychainKey.loginId)
        let expiry = Date().addingTimeInterval(AppConfig.Session.validity)
        KeychainStore.save(String(expiry.timeIntervalSince1970), for: KeychainKey.sessionExpiry)
    }

    private func clearSession() {
        KeychainStore.delete(KeychainKey.loginId)
        KeychainStore.delete(KeychainKey.sessionExpiry)
    }
}

/// 인증 입력 검증 오류.
enum AuthError: LocalizedError {
    case emptyLoginId

    var errorDescription: String? {
        switch self {
        case .emptyLoginId: return "아이디를 입력하세요."
        }
    }
}
