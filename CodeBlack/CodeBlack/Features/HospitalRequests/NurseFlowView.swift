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

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                Group {
                    switch tab {
                    case .received:
                        NurseRequestsView(kind: .received, viewModel: viewModel, onSelect: openDetail, unreadCount: notifications.unreadCount, onBell: { showNotifications = true })
                    case .completed:
                        NurseRequestsView(kind: .completed, viewModel: viewModel, onSelect: openDetail, unreadCount: notifications.unreadCount, onBell: { showNotifications = true })
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

    // 헤더 로그아웃 버튼은 제거됨(테스트용 플로팅 로그아웃 사용).

    /// 소속 병원 정보 로드 후, 요청/알림 폴링 + Live Activity/로컬 알림 동기화.
    private func bootstrap() async {
        await hospital.load(hospitalId: auth.actor?.hospitalId, fallbackName: auth.actor?.hospitalName)
        guard let loginId = auth.loginId else { return }
        if case .idle = viewModel.loadState {
            await viewModel.load(loginId: loginId)
        }
        await notifications.load(loginId: loginId)
        await LocalNotifier.shared.requestAuthorization()
        LocalNotifier.shared.setBadge(notifications.unreadCount)
        syncLiveActivity()
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(6))
            await viewModel.refresh(loginId: loginId)
            await notifications.refresh(loginId: loginId)
            fireRequestReminders()
            LocalNotifier.shared.setBadge(notifications.unreadCount)
            syncLiveActivity()
        }
    }

    /// 대기 중(PENDING) 요청 전부에 로컬 알림을 발송한다.
    /// 6초 폴링마다 호출 → 수락되거나(=PENDING 아님) 만료(NO_RESPONSE)되면 자동으로 멈춘다.
    private func fireRequestReminders() {
        for request in viewModel.requests where request.status == .pending {
            LocalNotifier.shared.notify(
                title: "새 환자 수용 요청",
                body: "응급 환자가 발생했습니다. 수용 가능한 응급실로 판단되어 요청합니다."
            )
        }
    }

    private func syncLiveActivity() {
        NurseLiveActivityManager.shared.sync(
            hospitalName: hospital.name ?? "",
            hospitalCoordinate: hospital.coordinate,
            requests: viewModel.requests,
            loginId: auth.loginId ?? ""
        )
    }

    @ViewBuilder
    private func destination(for route: NurseRoute) -> some View {
        switch route {
        case .detail(let item):
            NurseRequestDetailView(
                item: item,
                onBack: { path.removeLast() },
                onAccepted: {
                    tab = .completed
                    if !path.isEmpty { path.removeLast() }
                    if let loginId = auth.loginId {
                        Task { await viewModel.refresh(loginId: loginId) }
                    }
                }
            )
        }
    }
}
