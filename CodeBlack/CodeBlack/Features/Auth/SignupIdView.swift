//
//  SignupIdView.swift
//  CodeBlack
//
//  회원가입 1단계 — 아이디 생성. 유니크 로그인 아이디를 입력한다.
//

import SwiftUI

struct SignupIdView: View {
    let onBack: () -> Void
    /// 다음 단계(사용자 유형 선택)로 입력한 아이디 전달.
    let onNext: (String) -> Void

    @State private var loginId = ""
    @FocusState private var focused: Bool

    private var trimmed: String {
        loginId.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BackChevronBar(onBack: onBack)

            Text("아이디 생성")
                .font(.heading3)
                .foregroundStyle(AppColor.textPrimary)
                .padding(.horizontal, 20)
                .padding(.top, 8)

            Text("로그인에 사용할 유니크한 아이디를 입력하세요.")
                .font(.body5)
                .foregroundStyle(AppColor.textSecondary)
                .padding(.horizontal, 20)
                .padding(.top, 8)

            TextField("아이디 입력", text: $loginId)
                .font(.body5)
                .foregroundStyle(AppColor.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused($focused)
                .onSubmit(next)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 12).fill(AppColor.bgGray2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(focused ? AppColor.brandGreen : AppColor.border, lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.top, 24)

            Spacer()

            CTAButton(title: "다음", isEnabled: !trimmed.isEmpty, action: next)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .background(AppColor.bgWhite)
    }

    private func next() {
        guard !trimmed.isEmpty else { return }
        focused = false
        onNext(trimmed)
    }
}

#Preview {
    SignupIdView(onBack: {}, onNext: { _ in })
}
