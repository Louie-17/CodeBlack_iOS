//
//  LoginView.swift
//  CodeBlack
//
//  화면 1 — 구급대원 로그인. 비밀번호 없이 로그인 아이디만 입력한다.
//

import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var loginId = ""
    @FocusState private var focused: Bool

    private var isLoading: Bool {
        if case .loading = auth.state { return true }
        return false
    }

    private var errorMessage: String? {
        if case let .failed(message) = auth.state { return message }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(AppColor.brandGreen)
                Text("CodeBlack")
                    .font(.heading2)
                    .foregroundStyle(AppColor.textPrimary)
            }

            Text("구급대원 로그인하기")
                .font(.heading4)
                .foregroundStyle(AppColor.textPrimary)
                .padding(.top, 28)

            Text("발급받은 구급대원 아이디를 입력하세요.")
                .font(.body5)
                .foregroundStyle(AppColor.textSecondary)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 8) {
                Text("구급대원 아이디")
                    .font(.heading9)
                    .foregroundStyle(AppColor.labelSecondary)

                TextField("예: gangnam-3025", text: $loginId)
                    .font(.body5)
                    .foregroundStyle(AppColor.textPrimary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .focused($focused)
                    .onSubmit(submit)
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColor.bgGray2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(focused ? AppColor.brandGreen : AppColor.border, lineWidth: 1)
                    )
            }
            .padding(.top, 32)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption5)
                    .foregroundStyle(AppColor.emergencyRed)
                    .padding(.top, 12)
            }

            Spacer()

            CTAButton(
                title: isLoading ? "로그인 중…" : "구급대원 로그인하기",
                isEnabled: !loginId.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading,
                action: submit
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(AppColor.bgWhite)
    }

    private func submit() {
        focused = false
        Task { await auth.login(loginId: loginId) }
    }
}

#Preview {
    LoginView()
        .environment(AuthViewModel())
}
