//
//  AuthFlowView.swift
//  CodeBlack
//
//  온보딩 플로우 루트. 웰컴 → 로그인 / 웰컴 → 아이디 생성 → 사용자 유형 선택 → 가입 완료.
//  가입/로그인 성공 시 AuthViewModel.state = .authenticated 가 되어 루트가 앱 플로우로 전환된다.
//

import SwiftUI

struct AuthFlowView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(
                onLogin: { path.append(AuthRoute.login) },
                onSignup: { path.append(AuthRoute.signupId) }
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AuthRoute.self) { route in
                destination(for: route)
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
    }

    @ViewBuilder
    private func destination(for route: AuthRoute) -> some View {
        switch route {
        case .login:
            LoginView(onBack: { path.removeLast() })
        case .signupId:
            SignupIdView(
                onBack: { path.removeLast() },
                onNext: { loginId in path.append(AuthRoute.roleSelect(loginId: loginId)) }
            )
        case .roleSelect(let loginId):
            RoleSelectView(
                loginId: loginId,
                onBack: { path.removeLast() },
                onNurseNext: { id in path.append(AuthRoute.nurseHospital(loginId: id)) }
            )
        case .nurseHospital(let loginId):
            NurseHospitalView(loginId: loginId, onBack: { path.removeLast() })
        }
    }
}

/// 온보딩 라우트.
enum AuthRoute: Hashable {
    case login
    case signupId
    case roleSelect(loginId: String)
    case nurseHospital(loginId: String)
}
