//
//  AppColor.swift
//  CodeBlack
//
//  디자인 컬러 팔레트 (구급대원 플로우 시안 기준).
//  의미(브랜드/응급/뉴트럴/배경)별 시맨틱 토큰으로 제공한다.
//
//  사용법:
//      .foregroundStyle(AppColor.brandGreen)
//      RoundedRectangle(...).fill(AppColor.greenBg)
//

import SwiftUI

enum AppColor {

    // MARK: 브랜드 그린
    static let brandGreen = Color(hex: 0x86C55A)   // 메인
    static let brandGreenAlt = Color(hex: 0x7FBF4C)
    static let brandGreenDeep = Color(hex: 0x5A8C41)
    static let brandGreenDark = Color(hex: 0x4E8A2B)   // 진한(강조 텍스트/버튼)
    static let systemGreen = Color(hex: 0x34C759)      // iOS 그린

    // MARK: 연녹 배경
    static let greenBg = Color(hex: 0xEEF7E8)
    static let greenBg2 = Color(hex: 0xE7F3DC)

    // MARK: 응급 / 레드
    static let emergencyRed = Color(hex: 0xFF3131)     // 녹음·경고
    static let redAlt = Color(hex: 0xE5533C)
    static let redDeep = Color(hex: 0xBE3E2A)
    static let redBg = Color(hex: 0xFBE3DE)            // 연빨강 배경

    // MARK: 경고 옐로
    static let warningYellow = Color(hex: 0xFFD60A)

    // MARK: 텍스트 / 뉴트럴
    static let textPrimary = Color(hex: 0x141414)      // 본문
    static let textPrimaryAlt = Color(hex: 0x1C1C1E)
    static let textSecondary = Color(hex: 0x848491)    // 보조
    static let labelSecondary = Color(hex: 0x3C3C43).opacity(0.6)  // iOS 라벨
    static let separator = Color(hex: 0xC6C6CE)
    static let border = Color(hex: 0xDDDDE3)

    // MARK: 배경
    static let bgWhite = Color(hex: 0xFFFFFF)
    static let bgGray = Color(hex: 0xF9F9F9)
    static let bgGray2 = Color(hex: 0xF5F5F7)

    // MARK: 녹음 화면(다크)
    /// 환자 상태 녹음 화면의 다크 배경 그라디언트(중앙이 살짝 밝은 세로 밴드).
    static let recordingBackground = LinearGradient(
        colors: [Color(hex: 0x312329), Color(hex: 0x3E2F35), Color(hex: 0x312329)],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - 혼잡도 상태 (여유 / 보통 / 혼잡)

/// 응급실 병상 혼잡도. 색/라벨을 함께 제공한다.
enum Congestion {
    case spare      // 여유
    case normal     // 보통
    case crowded    // 혼잡

    /// 가용병상 수 기준 혼잡도 산정. (여유 ≥ 6, 보통 3~5, 혼잡 ≤ 2)
    init(availableBeds: Int?) {
        switch availableBeds ?? 0 {
        case 6...: self = .spare
        case 3...5: self = .normal
        default: self = .crowded
        }
    }

    var label: String {
        switch self {
        case .spare: return "여유"
        case .normal: return "보통"
        case .crowded: return "혼잡"
        }
    }

    var color: Color {
        switch self {
        case .spare: return AppColor.systemGreen
        case .normal: return AppColor.warningYellow
        case .crowded: return AppColor.emergencyRed
        }
    }

    /// 배지 배경(연한 톤).
    var tintBackground: Color { color.opacity(0.15) }
}

// MARK: - Color(hex:)

extension Color {
    /// 0xRRGGBB 정수로 색 생성.
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
