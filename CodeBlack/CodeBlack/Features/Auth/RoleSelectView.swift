//
//  RoleSelectView.swift
//  CodeBlack
//
//  회원가입 2단계 — 사용자 유형 선택 후 가입 완료.
//  구급대원(PARAMEDIC) / 간호사(NURSE) 중 선택 → POST /api/signup.
//

import SwiftUI

struct RoleSelectView: View {
    let loginId: String
    let onBack: () -> Void
    /// 간호사 선택 시 근무 병원 선택 화면으로. (구급대원은 즉시 가입)
    let onNurseNext: (String) -> Void

    @Environment(AuthViewModel.self) private var auth
    @State private var selected: ActorRole?
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BackChevronBar(onBack: onBack)

            Text("사용자 유형 선택")
                .font(.heading3)
                .foregroundStyle(AppColor.textPrimary)
                .padding(.horizontal, 20)
                .padding(.top, 8)

            VStack(spacing: 12) {
                roleCard(
                    role: .paramedic,
                    emoji: "🚑",
                    caption: "구급 요청이 필요하다면?",
                    title: "구급대원으로 시작하기"
                )
                roleCard(
                    role: .nurse,
                    emoji: "💉",
                    caption: "병원에서 일한다면?",
                    title: "간호사로 시작하기"
                )
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
                title: isSubmitting ? "가입 중…" : "완료하기",
                isEnabled: selected != nil && !isSubmitting,
                action: submit
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(AppColor.bgWhite)
    }

    private func roleCard(role: ActorRole, emoji: String, caption: String, title: String) -> some View {
        let isSelected = selected == role
        return Button {
            selected = role
        } label: {
            HStack(spacing: 14) {
                Text(emoji)
                    .font(.system(size: 28))
                VStack(alignment: .leading, spacing: 3) {
                    Text(caption)
                        .font(.caption6)
                        .foregroundStyle(AppColor.textSecondary)
                    Text(title)
                        .font(.heading7)
                        .foregroundStyle(AppColor.textPrimary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColor.brandGreen)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? AppColor.greenBg : AppColor.bgGray2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? AppColor.brandGreen : AppColor.border, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func submit() {
        guard let role = selected else { return }
        switch role {
        case .nurse:
            // 간호사는 API를 바로 보내지 않고 근무 병원 선택 화면으로 이동.
            onNurseNext(loginId)
        case .paramedic:
            isSubmitting = true
            errorMessage = nil
            Task {
                do {
                    try await auth.register(loginId: loginId, role: .paramedic)
                    // 성공 시 auth.state = .authenticated → 루트가 앱 플로우로 전환.
                } catch {
                    errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    isSubmitting = false
                }
            }
        }
    }
}

#Preview {
    RoleSelectView(loginId: "nurse1", onBack: {}, onNurseNext: { _ in })
        .environment(AuthViewModel())
}
