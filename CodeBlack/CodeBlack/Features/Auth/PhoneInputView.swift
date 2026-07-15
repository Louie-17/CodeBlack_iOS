//
//  PhoneInputView.swift
//  CodeBlack
//
//  구급대원 회원가입 마지막 단계 — 전화번호 입력.
//  010 - 국번 - 뒷번호 3칸으로 나눠 입력받아 "010-1234-5678" 형식으로 가입 요청한다.
//

import SwiftUI

struct PhoneInputView: View {
    let loginId: String
    let onBack: () -> Void

    private enum Field { case first, second, third }

    @Environment(AuthViewModel.self) private var auth
    @State private var part1 = "010"
    @State private var part2 = ""
    @State private var part3 = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @FocusState private var focus: Field?

    private var phoneNumber: String { "\(part1)-\(part2)-\(part3)" }
    /// 국번 3~4자리 + 뒷번호 4자리면 유효.
    private var isValid: Bool { part1.count >= 2 && part2.count >= 3 && part3.count == 4 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BackChevronBar(onBack: onBack)

            Text("전화번호 입력")
                .font(.heading3)
                .foregroundStyle(AppColor.textPrimary)
                .padding(.horizontal, 20)
                .padding(.top, 8)

            HStack(spacing: 10) {
                digitField(text: $part1, field: .first, max: 3)
                dash
                digitField(text: $part2, field: .second, max: 4)
                dash
                digitField(text: $part3, field: .third, max: 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)

            Spacer()

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption5)
                    .foregroundStyle(AppColor.emergencyRed)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }

            CTAButton(
                title: isSubmitting ? "가입 중…" : "다음",
                isEnabled: isValid && !isSubmitting,
                action: submit
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(AppColor.bgWhite)
        .onAppear { focus = .second }
    }

    private var dash: some View {
        Text("-")
            .font(.heading6)
            .foregroundStyle(AppColor.textSecondary)
    }

    private func digitField(text: Binding<String>, field: Field, max: Int) -> some View {
        TextField("", text: text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.body4)
            .foregroundStyle(AppColor.textPrimary)
            .focused($focus, equals: field)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 12).fill(AppColor.bgGray2))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(focus == field ? AppColor.brandGreen : AppColor.border, lineWidth: 1)
            )
            .onChange(of: text.wrappedValue) { _, newValue in
                // 숫자만, 최대 자릿수로 제한하고 채워지면 다음 칸으로 자동 이동.
                let digits = String(newValue.filter(\.isNumber).prefix(max))
                if digits != newValue { text.wrappedValue = digits }
                if digits.count >= max { advance(from: field) }
            }
    }

    private func advance(from field: Field) {
        switch field {
        case .first: focus = .second
        case .second: focus = .third
        case .third: break
        }
    }

    private func submit() {
        guard isValid, !isSubmitting else { return }
        focus = nil
        isSubmitting = true
        errorMessage = nil
        Task {
            do {
                try await auth.register(loginId: loginId, role: .paramedic, phoneNumber: phoneNumber)
                // 성공 시 auth.state = .authenticated → 루트가 앱 플로우로 전환.
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                isSubmitting = false
            }
        }
    }
}

#Preview {
    PhoneInputView(loginId: "paramedic1", onBack: {})
        .environment(AuthViewModel())
}
