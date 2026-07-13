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
}
