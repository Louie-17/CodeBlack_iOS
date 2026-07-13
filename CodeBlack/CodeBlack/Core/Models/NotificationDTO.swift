//
//  NotificationDTO.swift
//  CodeBlack
//
//  Notifications 태그 DTO. 병원 담당자 요청 알림.
//

import Foundation

/// GET /api/hospital/notifications, PATCH /{notificationId}/read 응답.
struct NotificationResponse: Decodable, Identifiable {
    let notificationId: Int64?
    /// 관련 병원 요청 ID
    let hospitalRequestId: Int64?
    /// 관련 환자 요청 ID
    let emergencyRequestId: Int64?
    /// 알림 종류
    let type: NotificationType?
    let title: String?
    let message: String?
    /// 읽음 여부
    let read: Bool?
    /// 알림 생성 시각 (ISO8601)
    let createdAt: String?
    /// 읽음 처리 시각 (ISO8601)
    let readAt: String?

    var id: Int64 { notificationId ?? -1 }
}
