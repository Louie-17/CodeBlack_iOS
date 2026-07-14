//
//  LocalNotifier.swift
//  CodeBlack
//
//  로컬 알림. 폴링 중 새 요청/알림이 도착하면 배너+소리로 알린다.
//  (원격 APNs 푸시는 백엔드의 디바이스 토큰 등록/발송이 필요하므로 별도.)
//

import Foundation
import UserNotifications

@MainActor
final class LocalNotifier: NSObject, UNUserNotificationCenterDelegate {

    static let shared = LocalNotifier()
    private override init() { super.init() }

    private(set) var isAuthorized = false

    /// 앱 시작 시 1회 호출. 포그라운드 배너 표시를 위해 델리게이트를 등록한다.
    func configure() {
        UNUserNotificationCenter.current().delegate = self
    }

    /// 알림 권한 요청(alert/sound/badge).
    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        isAuthorized = granted
    }

    /// 즉시 로컬 알림 발송.
    func notify(title: String, body: String, identifier: String = UUID().uuidString) {
        guard isAuthorized else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    /// 앱 아이콘 배지 수 갱신.
    func setBadge(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(max(0, count))
    }

    /// 요청 수락 알림. 요청 ID 단위로 1회만 발송(화면 무관 중복 방지).
    func notifyAcceptedRequest(requestId: Int64, hospitalName: String?) {
        let defaults = UserDefaults.standard
        guard defaults.integer(forKey: AppConfig.notifiedAcceptedRequestKey) != Int(requestId) else { return }
        defaults.set(Int(requestId), forKey: AppConfig.notifiedAcceptedRequestKey)
        notify(
            title: "이송 준비 완료",
            body: "\(hospitalName ?? "병원")에서 환자를 수용합니다. 이송을 준비하세요."
        )
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// 포그라운드에서도 배너/소리 표시.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}
