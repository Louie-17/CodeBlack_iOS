//
//  ContentView.swift
//  CodeBlack
//
//  루트 라우터. 인증 상태와 역할에 따라 진입 화면을 분기한다.
//  현재는 구급대원(유저) 플로우를 구현한다. 병원(어드민) 플로우는 추후.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthViewModel.self) private var auth

    var body: some View {
        switch auth.state {
        case .idle, .loading:
            SplashView()
        case .authenticated:
            if auth.role?.isHospitalStaff == true {
                NurseFlowView()
            } else {
                ParamedicFlowView()
            }
        case .needsCredentials:
            AuthFlowView()
        }
    }
}

/// 자동 로그인 진행 중 스플래시.
private struct SplashView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cross.case.fill")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(AppColor.brandGreen)
            Text("CodeBlack")
                .font(.heading2)
                .foregroundStyle(AppColor.textPrimary)
            ProgressView()
                .tint(AppColor.brandGreen)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.bgWhite)
    }
}


#Preview {
    ContentView()
        .environment(AuthViewModel())
}
