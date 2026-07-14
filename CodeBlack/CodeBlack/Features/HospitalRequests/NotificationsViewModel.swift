//
//  NotificationsViewModel.swift
//  CodeBlack
//
//  병원 담당자 요청 알림 목록/읽음 처리 뷰모델.
//

import Foundation
import Observation

@MainActor
@Observable
final class NotificationsViewModel {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var notifications: [NotificationResponse] = []

    private let service = NotificationService()

    var unreadCount: Int { notifications.filter { $0.read != true }.count }

    func load(loginId: String) async {
        loadState = .loading
        do {
            notifications = try await service.list(loginId: loginId)
            loadState = .loaded
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            loadState = .failed(message)
        }
    }

    /// 스피너 없이 갱신(폴링용).
    func refresh(loginId: String) async {
        if let result = try? await service.list(loginId: loginId) {
            notifications = result
            if loadState != .loaded { loadState = .loaded }
        }
    }

    /// 알림 하나 읽음 처리(로컬 + 서버).
    func markRead(notificationId: Int64, loginId: String) async {
        guard let index = notifications.firstIndex(where: { $0.notificationId == notificationId }),
              notifications[index].read != true else { return }
        if let updated = try? await service.markRead(notificationId: notificationId, loginId: loginId) {
            notifications[index] = updated
        }
    }

    /// 모든 안 읽은 알림 읽음 처리.
    func markAllRead(loginId: String) async {
        for notification in notifications where notification.read != true {
            if let id = notification.notificationId {
                await markRead(notificationId: id, loginId: loginId)
            }
        }
    }
}
