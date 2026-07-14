//
//  NurseGlassTabBar.swift
//  CodeBlack
//
//  간호사 하단 플로팅 탭바 — 완료 요청 / 받은 요청. Liquid Glass(glassEffect) 적용.
//

import SwiftUI

struct NurseGlassTabBar: View {
    @Binding var selected: NurseTab

    var body: some View {
        HStack(spacing: 4) {
            tabButton(.completed, title: "완료 요청", icon: "checkmark")
            tabButton(.received, title: "받은 요청", icon: "paperplane.fill")
        }
        .padding(6)
        .glassEffect(.regular, in: .capsule)
    }

    private func tabButton(_ tab: NurseTab, title: String, icon: String) -> some View {
        let active = selected == tab
        return Button {
            selected = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.heading9)
            }
            .foregroundStyle(active ? AppColor.brandGreen : AppColor.textSecondary)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
