//
//  NavBar.swift
//  CodeBlack
//
//  상단 커스텀 back 바. 뒤로가기 + 타이틀. (gap 10 스펙)
//

import SwiftUI

struct BackBar: View {
    let title: String
    var trailing: AnyView? = nil
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(title)
                .font(.heading6)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()

            if let trailing {
                trailing
            }
        }
        .frame(height: 52)
        .padding(.horizontal, 12)
    }
}

/// 타이틀 없는 back 전용 상단 바(온보딩 화면용). 좌측 상단 chevron만.
struct BackChevronBar: View {
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(height: 52)
        .padding(.horizontal, 8)
    }
}
