//
//  Badges.swift
//  CodeBlack
//
//  배지/태그 컴포넌트. 혼잡도 배지, AI 추천 태그, 진료 태그 칩.
//  공통 pad=(6,2), gap 4 스펙을 따른다.
//

import SwiftUI

/// 혼잡도 배지 (여유/보통/혼잡).
struct CongestionBadge: View {
    let congestion: Congestion

    var body: some View {
        Text(congestion.label)
            .font(.heading10)
            .foregroundStyle(congestion.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(congestion.tintBackground)
            )
    }
}

/// AI 추천 태그.
struct AIRecommendBadge: View {
    var score: Int?

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 11, weight: .semibold))
            Text(score.map { "AI 추천 \($0)" } ?? "AI 추천")
                .font(.heading10)
        }
        .foregroundStyle(AppColor.brandGreenDark)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule().fill(AppColor.greenBg2)
        )
    }
}

/// 수용 가능 진료/장비 태그 칩.
struct TagChip: View {
    let text: String
    var filled: Bool = false

    var body: some View {
        Text(text)
            .font(.caption5)
            .foregroundStyle(filled ? AppColor.brandGreenDark : AppColor.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(filled ? AppColor.greenBg : AppColor.bgGray2)
            )
    }
}
