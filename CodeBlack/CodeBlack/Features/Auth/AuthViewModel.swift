//
//  AuthViewModel.swift
//  CodeBlack
//
//  인증 뷰모델. 비밀번호 없이 로그인 아이디로 식별하고, 토큰 대신 로그인 아이디를
//  세션 식별자로 Keychain에 보관한다.
//  한 번 로그인하면 세션 만료(AppConfig.Session.validity) 전까지 재입력 없이 자동 로그인한다.
//

import Foundation
import Observation

@MainActor
@Observable
final class AuthViewModel {

    enum State: Equatable {
        case idle
        case loading
        case authenticated(name: String, role: String)
        case needsCredentials      // 저장된 세션 없음/만료 → 로그인 화면
        case failed(String)
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

    /// 앱 진입 시 호출. 자동 로그인을 시도한다(화면 없음).
    func bootstrap() async {
        // 1) 개발용 자동 로그인 아이디가 설정돼 있으면 우선 사용.
        if AppConfig.AutoLogin.isConfigured {
            await login(loginId: AppConfig.AutoLogin.loginId)
            return
        }
        // 2) 저장된 세션이 만료 전이면 재입력 없이 자동 로그인.
        if hasValidSession, let saved = loginId {
            await login(loginId: saved)
            return
        }
        // 3) 저장된 세션 없음/만료 → 로그인 화면.
        clearSession()
        state = .needsCredentials
    }

    /// 로그인 아이디로 `POST /api/auth/login` 을 호출하고, 성공 시 세션을 저장/연장한다.
    func login(loginId rawLoginId: String) async {
        let loginId = rawLoginId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !loginId.isEmpty else {
            state = .failed("로그인 아이디를 입력하세요.")
            return
        }
        state = .loading
        do {
            let result = try await userService.login(loginId: loginId)
            self.actor = result

            let identifier = result.loginId ?? loginId
            saveSession(loginId: identifier)

            let display = result.hospitalName ?? identifier
            let role = result.role?.rawValue ?? ""
            state = .authenticated(name: display, role: role)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            state = .failed(message)
        }
    }

    /// 로그아웃: 저장된 세션을 삭제하고 초기 상태로.
    func logout() {
        clearSession()
        actor = nil
        state = .idle
    }

    // MARK: - 세션 저장

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
