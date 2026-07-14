//
//  CardStyle.swift
//  CodeBlack
//
//  카드 컨테이너 공통 스타일(흰 배경 + 보더 + 소프트 그린틴트 그림자).
//  디자인 토큰: radius 16, border #DDDDE3, shadow #1E2D14 @ y5 blur12.
//

import SwiftUI

extension View {
    func cardStyle(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppColor.bgWhite)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(AppColor.border, lineWidth: 1)
            )
            .shadow(color: Color(hex: 0x1E2D14).opacity(0.10), radius: 12, x: 0, y: 5)
    }
}
