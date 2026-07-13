//
//  WelcomeView.swift
//  CodeBlack
//
//  온보딩 첫 화면 — 환영 + 로그인/회원가입 진입.
//

import SwiftUI

struct WelcomeView: View {
    let onLogin: () -> Void
    let onSignup: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppColor.brandGreen)
                Text("CodeBlack")
                    .font(.heading7)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(.top, 24)

            Text("CodeBlack에\n오신 것을 환영합니다")
                .font(.heading2)
                .foregroundStyle(AppColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 20)

            Text("응급 이송을 더 빠르게. 지금 시작하세요.")
                .font(.body5)
                .foregroundStyle(AppColor.textSecondary)
                .padding(.top, 10)

            Spacer()

            VStack(spacing: 12) {
                CTAButton(title: "로그인", style: .green, action: onLogin)
                CTAButton(title: "회원가입", style: .outlineGreen, action: onSignup)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.bgWhite)
    }
}

#Preview {
    WelcomeView(onLogin: {}, onSignup: {})
}
