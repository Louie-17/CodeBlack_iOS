//
//  APICommon.swift
//  CodeBlack
//
//  CodeBlack API 공통 응답 봉투 및 도메인 공용 열거형.
//  (OpenAPI: "CodeBlack API" v1 — 응급환자 병원 수용 요청 서비스)
//
//  참고: 날짜/시간(date-time) 필드는 서버 직렬화 포맷 편차에 견고하도록
//  DTO에서 ISO8601 문자열(String)로 그대로 보관한다. 표시/계산이 필요하면
//  소비 측에서 ISO8601DateFormatter 로 파싱한다.
//

import Foundation

/// 서버 공통 응답 봉투. 성공 시 `data`, 실패 시 `message` 가 온다.
/// (`code` 는 스펙에 없지만 하위호환을 위해 옵셔널로 둔다.)
struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let message: String?
    let code: String?
}

/// 페이지네이션 응답 래퍼. 목록(recommendations/search 등) 응답의 data 가 이 형태로 온다.
struct PageResponse<T: Decodable>: Decodable {
    let content: [T]?
    let page: Int?
    let size: Int?
    let totalCount: Int?
    let hasNext: Bool?

    /// 항목 배열(없으면 빈 배열).
    var items: [T] { content ?? [] }
}

// MARK: - 사용자 역할

/// 사용자 역할(와이어 값). 구급대원 / 간호사(병원 담당자).
enum ActorRole: String, Codable, CaseIterable {
    case paramedic = "PARAMEDIC"
    case nurse = "NURSE"

    /// 병원(어드민) 플로우 사용자 여부. 간호사 = 병원 담당자.
    var isHospitalStaff: Bool { self == .nurse }
    /// 구급대원(유저) 플로우 사용자 여부.
    var isParamedic: Bool { self == .paramedic }
}

// MARK: - 병원 장비 / 정렬

/// 병원 보유·필요 장비 유형.
enum EquipmentType: String, Codable, CaseIterable {
    case ct = "CT"
    case mri = "MRI"
    case ventilator = "VENTILATOR"
    case operatingRoom = "OPERATING_ROOM"
}

/// 추천 병원 목록 정렬 기준.
enum HospitalSort: String, CaseIterable {
    case recommendation = "RECOMMENDATION"
    case distance = "DISTANCE"
    case beds = "BEDS"
}

// MARK: - 상태 열거형 (미지값 방어 포함)

/// 병원별 요청 상태.
enum HospitalRequestStatus: String, Codable {
    case pending = "PENDING"
    case accepted = "ACCEPTED"
    case canceled = "CANCELED"
    case noResponse = "NO_RESPONSE"
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = HospitalRequestStatus(rawValue: raw) ?? .unknown
    }
}

/// 환자 요청 전체 상태.
enum EmergencyRequestStatus: String, Codable {
    case waiting = "WAITING"
    case accepted = "ACCEPTED"
    case closed = "CLOSED"
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = EmergencyRequestStatus(rawValue: raw) ?? .unknown
    }
}

/// 병원 알림 종류.
enum NotificationType: String, Codable {
    case requestReceived = "REQUEST_RECEIVED"
    case requestCanceled = "REQUEST_CANCELED"
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = NotificationType(rawValue: raw) ?? .unknown
    }
}
