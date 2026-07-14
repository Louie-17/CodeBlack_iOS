//
//  HospitalFormatting.swift
//  CodeBlack
//
//  병원 표시용 포맷 유틸. 거리/예상 도착시간 문자열.
//

import Foundation

enum HospitalFormat {

    /// 구급차 평균 주행 속도(km/h) 가정치 — 예상 도착시간 추정용.
    private static let averageSpeedKmh: Double = 40

    /// 거리 문자열. 예: "2.3km", "800m".
    static func distance(_ kilometers: Double?) -> String {
        guard let kilometers else { return "-" }
        if kilometers < 1 {
            return "\(Int((kilometers * 1000).rounded()))m"
        }
        return String(format: "%.1fkm", kilometers)
    }

    /// 예상 도착시간 문자열. 예: "약 4분".
    static func eta(_ kilometers: Double?) -> String {
        guard let kilometers, kilometers > 0 else { return "-" }
        let minutes = max(1, Int((kilometers / averageSpeedKmh * 60).rounded()))
        return "약 \(minutes)분"
    }

    /// 장비 코드 → 한글 라벨.
    static func equipmentLabel(_ type: EquipmentType) -> String {
        switch type {
        case .ct: return "CT"
        case .mri: return "MRI"
        case .ventilator: return "인공호흡기"
        case .operatingRoom: return "수술실"
        }
    }

    /// 녹음/경과 시간 mm:ss 포맷.
    static func timecode(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
    /// ISO8601 문자열 파싱(소수 초 유무 모두 허용).
    static func parseISO(_ string: String?) -> Date? {
        guard let string else { return nil }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: string) { return date }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: string)
    }

    /// 상대 시각. 예: "방금 전", "4분 전", "2시간 전", "3일 전".
    static func relativeTime(iso: String?, now: Date = Date()) -> String {
        guard let date = parseISO(iso) else { return "-" }
        let seconds = max(0, now.timeIntervalSince(date))
        switch seconds {
        case ..<60: return "방금 전"
        case ..<3600: return "\(Int(seconds / 60))분 전"
        case ..<86400: return "\(Int(seconds / 3600))시간 전"
        default: return "\(Int(seconds / 86400))일 전"
        }
    }

    /// 재생 진행 표기. 예: "00:06 / 00:18".
    static func playback(_ current: TimeInterval, _ total: TimeInterval) -> String {
        "\(timecode(current)) / \(timecode(total))"
    }
}
