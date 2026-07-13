//
//  NotificationService.swift
//  CodeBlack
//
//  Notifications 태그 API. 병원 담당자 요청 알림 조회/읽음 처리.
//  JWT 도입 전까지 loginId 쿼리로 담당자를 식별한다.
//

import Foundation

struct NotificationService {

    var client = APIClient(baseURL: AppConfig.baseURL)

    /// GET /api/hospital/notifications — 소속 병원 요청 알림 목록.
    /// - Parameter unreadOnly: true면 안 읽은 알림만 조회.
    func list(loginId: String, unreadOnly: Bool = false) async throws -> [NotificationResponse] {
        try await client.send(
            .get, "/api/hospital/notifications",
            query: ["loginId": loginId, "unreadOnly": String(unreadOnly)]
        )
    }

    /// PATCH /api/hospital/notifications/{notificationId}/read — 알림 하나 읽음 처리.
    func markRead(notificationId: Int64, loginId: String) async throws -> NotificationResponse {
        try await client.send(
            .patch, "/api/hospital/notifications/\(notificationId)/read",
            query: ["loginId": loginId]
        )
    }
}
