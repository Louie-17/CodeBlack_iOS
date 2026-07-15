//
//  AuthFlowView.swift
//  CodeBlack
//
//  온보딩 플로우 루트. 웰컴(로그인) → 아이디 생성 → 사용자 유형 선택 → 가입 완료.
//  가입/로그인 성공 시 AuthViewModel.state = .authenticated 가 되어 루트가 앱 플로우로 전환된다.
//

import SwiftUI

struct AuthFlowView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(
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
        case .signupId:
            SignupIdView(
                onBack: { path.removeLast() },
                onNext: { loginId in path.append(AuthRoute.phoneInput(loginId: loginId)) }
            )
        case .phoneInput(let loginId):
            PhoneInputView(
                loginId: loginId,
                onBack: { path.removeLast() },
                onNext: { phoneNumber in
                    path.append(AuthRoute.roleSelect(loginId: loginId, phoneNumber: phoneNumber))
                }
            )
        case .roleSelect(let loginId, let phoneNumber):
            RoleSelectView(
                loginId: loginId,
                phoneNumber: phoneNumber,
                onBack: { path.removeLast() },
                onNurseNext: { id in path.append(AuthRoute.nurseHospital(loginId: id, phoneNumber: phoneNumber)) }
            )
        case .nurseHospital(let loginId, let phoneNumber):
            NurseHospitalView(loginId: loginId, phoneNumber: phoneNumber, onBack: { path.removeLast() })
        }
    }
}

/// 온보딩 라우트.
enum AuthRoute: Hashable {
    case signupId
    case phoneInput(loginId: String)
    case roleSelect(loginId: String, phoneNumber: String)
    case nurseHospital(loginId: String, phoneNumber: String)
}
