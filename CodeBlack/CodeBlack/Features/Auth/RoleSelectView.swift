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
    /// 구급대원 선택 시 전화번호 입력 화면으로.
    let onParamedicNext: (String) -> Void
    /// 간호사 선택 시 근무 병원 선택 화면으로.
    let onNurseNext: (String) -> Void

    @State private var selected: ActorRole?

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

            CTAButton(
                title: "다음",
                isEnabled: selected != nil,
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
            // 간호사: 전화번호 없이 근무 병원 선택 화면으로.
            onNurseNext(loginId)
        case .paramedic:
            // 구급대원: 전화번호 입력 화면으로.
            onParamedicNext(loginId)
        }
    }
}

#Preview {
    RoleSelectView(loginId: "nurse1", onBack: {}, onParamedicNext: { _ in }, onNurseNext: { _ in })
        .environment(AuthViewModel())
}
