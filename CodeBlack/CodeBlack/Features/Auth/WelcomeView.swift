//
//  WelcomeView.swift
//  CodeBlack
//
//  온보딩 첫 화면 — 브랜드 소개(초록) + 로그인 카드(흰색).
//  아이디 입력 포커스 시 키보드 회피로 하단 카드가 위로 올라온다(기본 keyboard avoidance).
//

import SwiftUI

struct WelcomeView: View {
    @Environment(AuthViewModel.self) private var auth
    /// 회원가입 플로우로 이동.
    let onSignup: () -> Void

    @State private var loginId = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focused: Bool

    private var trimmed: String {
        loginId.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 0) {
            greenHeader
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            loginCard
        }
        .background(AppColor.brandGreen.ignoresSafeArea())
    }

    // MARK: 초록 헤더

    private var greenHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button(action: onSignup) {
                    Text("회원가입")
                        .font(.heading8)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(.white.opacity(0.22)))
                }
                .buttonStyle(.plain)
            }

            Text("빠르고\n간단한\nCodeBlack")
                .font(.heading1)
                .foregroundStyle(.white)
                .padding(.top, 16)

            Text("거절없이 빠르고 간단하게\n응급실을 찾아가는 방법")
                .font(.body4)
                .foregroundStyle(.white.opacity(0.95))
                .padding(.top, 16)

            Spacer(minLength: 0)

            Image("WelcomeAmbulance")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .contentShape(Rectangle())
        .onTapGesture { focused = false }
    }

    // MARK: 로그인 카드

    private var loginCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("아이디")
                .font(.heading5)
                .foregroundStyle(AppColor.textPrimary)

            TextField("아이디 입력", text: $loginId)
                .font(.body5)
                .foregroundStyle(AppColor.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .focused($focused)
                .onSubmit(submit)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 14).fill(AppColor.bgGray2))
                .padding(.top, 14)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption5)
                    .foregroundStyle(AppColor.emergencyRed)
                    .padding(.top, 8)
            }

            HStack(spacing: 4) {
                Text("혹시 계정이 없으신가요?")
                    .font(.caption4)
                    .foregroundStyle(AppColor.textSecondary)
                Button(action: onSignup) {
                    Text("회원가입")
                        .font(.heading8)
                        .underline()
                        .foregroundStyle(AppColor.brandGreenDark)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 22)

            CTAButton(
                title: isLoading ? "로그인 중…" : "로그인",
                isEnabled: !trimmed.isEmpty && !isLoading,
                action: submit
            )
            .padding(.top, 12)
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 28,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 28
            )
            .fill(AppColor.bgWhite)
            .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: 액션

    private func submit() {
        guard !trimmed.isEmpty else { return }
        focused = false
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await auth.authenticate(loginId: trimmed)
                // 성공 시 auth.state = .authenticated → 루트가 앱 플로우로 전환.
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                isLoading = false
            }
        }
    }
}

#Preview {
    WelcomeView(onSignup: {})
        .environment(AuthViewModel())
}
