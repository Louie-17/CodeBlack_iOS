//
//  CTAButton.swift
//  CodeBlack
//
//  하단 풀폭 CTA 버튼. 그린(기본)/레드/아웃라인 스타일.
//

import SwiftUI

struct CTAButton: View {

    enum Style {
        case green      // 메인 초록 채움
        case red        // 응급 레드 채움
        case outline    // 회색 보더 (보조 액션)
        case outlineRed // 레드 보더 (취소성 액션)
    }

    let title: String
    var style: Style = .green
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.heading6)
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(background)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(borderColor, lineWidth: borderWidth)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }

    private var foreground: Color {
        switch style {
        case .green, .red: return .white
        case .outline: return AppColor.textPrimary
        case .outlineRed: return AppColor.emergencyRed
        }
    }

    private var background: Color {
        switch style {
        case .green: return AppColor.brandGreen
        case .red: return AppColor.emergencyRed
        case .outline, .outlineRed: return .clear
        }
    }

    private var borderColor: Color {
        switch style {
        case .green, .red: return .clear
        case .outline: return AppColor.border
        case .outlineRed: return AppColor.emergencyRed
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .green, .red: return 0
        case .outline, .outlineRed: return 1
        }
    }
}
