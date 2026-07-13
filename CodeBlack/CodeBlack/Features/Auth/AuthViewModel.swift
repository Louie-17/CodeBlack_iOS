//
//  AuthViewModel.swift
//  CodeBlack
//
//  앱 실행 시 로그인 화면 없이 자동으로 로그인 API를 호출하는 인증 뷰모델.
//  서버는 비밀번호 없이 로그인 아이디만으로 사용자를 식별하고, 토큰 대신
//  로그인 아이디를 세션 식별자로 보관한다.
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
        case needsCredentials      // AppConfig.AutoLogin 미설정
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

    /// 앱 진입 시 호출. 자동 로그인을 수행한다(화면 없음).
    func bootstrap() async {
        await autoLogin()
    }

    /// AppConfig.AutoLogin 아이디로 `POST /api/auth/login` 을 자동 호출한다.
    /// 아이디가 미설정이면 로그인 화면 입력을 기다린다(needsCredentials).
    func autoLogin() async {
        guard AppConfig.AutoLogin.isConfigured else {
            state = .needsCredentials
            return
        }
        await login(loginId: AppConfig.AutoLogin.loginId)
    }

    /// 로그인 화면에서 입력한 아이디로 `POST /api/auth/login` 을 호출한다.
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
            KeychainStore.save(identifier, for: KeychainKey.loginId)

            let display = result.hospitalName ?? identifier
            let role = result.role?.rawValue ?? ""
            state = .authenticated(name: display, role: role)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            state = .failed(message)
        }
    }

    /// 로그아웃: 세션 아이디 삭제 후 초기 상태로.
    func logout() {
        KeychainStore.delete(KeychainKey.loginId)
        actor = nil
        state = .idle
    }
}
