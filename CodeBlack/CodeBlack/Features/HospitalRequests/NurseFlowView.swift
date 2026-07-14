//
//  NurseFlowView.swift
//  CodeBlack
//
//  간호사(병원) 플로우 루트. 하단 글래스 탭바(받은 요청/완료 요청) + 요청 상세.
//  요청 데이터 로드/폴링 + Live Activity 동기화를 이곳에서 소유한다.
//

import SwiftUI

struct NurseFlowView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var path = NavigationPath()
    @State private var hospital = NurseHospitalInfo()
    @State private var viewModel = HospitalRequestListViewModel()
    @State private var notifications = NotificationsViewModel()
    @State private var tab: NurseTab = .received
    @State private var showNotifications = false
    /// 로컬 알림을 이미 발송한 알림 ID(중복 발송 방지).
    @State private var seenNotificationIds: Set<Int64> = []

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                Group {
                    switch tab {
                    case .received:
                        NurseRequestsView(kind: .received, viewModel: viewModel, onSelect: openDetail, onLogout: logout, unreadCount: notifications.unreadCount, onBell: { showNotifications = true })
                    case .completed:
                        NurseRequestsView(kind: .completed, viewModel: viewModel, onSelect: openDetail, onLogout: logout, unreadCount: notifications.unreadCount, onBell: { showNotifications = true })
                    }
                }
                NurseGlassTabBar(selected: $tab)
                    .padding(.bottom, 6)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: NurseRoute.self) { route in
                destination(for: route)
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
        .environment(hospital)
        .sheet(isPresented: $showNotifications) {
            if let loginId = auth.loginId {
                NurseNotificationsView(
                    viewModel: notifications,
                    loginId: loginId,
                    onOpenRequest: openRequestFromNotification
                )
                .presentationDetents([.large])
            }
        }
        .task { await bootstrap() }
    }

    private func openDetail(_ item: NurseRequestItem) {
        path.append(NurseRoute.detail(item))
    }

    /// 알림 → 해당 병원요청 상세로 이동(목록에 있으면).
    private func openRequestFromNotification(_ hospitalRequestId: Int64) {
        showNotifications = false
        if let request = viewModel.requests.first(where: { $0.hospitalRequestId == hospitalRequestId }) {
            path.append(NurseRoute.detail(NurseRequestItem(from: request)))
        }
    }

    private func logout() {
        NurseLiveActivityManager.shared.end()
        auth.logout()
    }

    /// 소속 병원 정보 로드 후, 요청/알림 폴링 + Live Activity/로컬 알림 동기화.
    private func bootstrap() async {
        await hospital.load(hospitalId: auth.actor?.hospitalId, fallbackName: auth.actor?.hospitalName)
        guard let loginId = auth.loginId else { return }
        if case .idle = viewModel.loadState {
            await viewModel.load(loginId: loginId)
        }
        await notifications.load(loginId: loginId)
        // 최초 로드분은 이미 지난 알림이므로 발송하지 않고 seen 처리.
        seenNotificationIds = Set(notifications.notifications.compactMap { $0.notificationId })
        await LocalNotifier.shared.requestAuthorization()
        LocalNotifier.shared.setBadge(notifications.unreadCount)
        syncLiveActivity()
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(15))
            await viewModel.refresh(loginId: loginId)
            await notifications.refresh(loginId: loginId)
            fireNewNotifications()
            LocalNotifier.shared.setBadge(notifications.unreadCount)
            syncLiveActivity()
        }
    }

    /// 새로 도착한 알림에 대해 로컬 알림을 발송한다.
    private func fireNewNotifications() {
        for notification in notifications.notifications {
            guard let id = notification.notificationId, !seenNotificationIds.contains(id) else { continue }
            seenNotificationIds.insert(id)
            if notification.read != true {
                LocalNotifier.shared.notify(
                    title: notification.title ?? "새 환자 수용 요청",
                    body: notification.message ?? ""
                )
            }
        }
    }

    private func syncLiveActivity() {
        NurseLiveActivityManager.shared.sync(
            hospitalName: hospital.name ?? "",
            hospitalCoordinate: hospital.coordinate,
            requests: viewModel.requests
        )
    }

    @ViewBuilder
    private func destination(for route: NurseRoute) -> some View {
        switch route {
        case .detail(let item):
            NurseRequestDetailView(item: item, onBack: { path.removeLast() })
        }
    }
}
