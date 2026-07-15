//
//  ParamedicFlowView.swift
//  CodeBlack
//
//  구급대원 플로우 루트. 응급실 찾기 → 병원 정보 → 음성 입력 → 요청 상태.
//

import SwiftUI

struct ParamedicFlowView: View {
    @State private var path = NavigationPath()
    @State private var location = LocationProvider.shared
    @AppStorage(AppConfig.activeRequestKey) private var activeRequestId: Int = 0

    var body: some View {
        NavigationStack(path: $path) {
            HospitalSearchView(
                onSelect: { path.append(ParamedicRoute.detail($0)) },
                onRequest: { hospitals in
                    path.append(ParamedicRoute.voiceInput(hospitals))
                },
                onShowStatus: { requestId in
                    path.append(ParamedicRoute.requestStatus(requestId: requestId))
                }
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ParamedicRoute.self) { route in
                destination(for: route)
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
        .environment(location)
        // 어느 화면에 있든(메인 포함) 활성 요청의 수락을 감지해 알림을 띄운다.
        .task(id: activeRequestId) { await pollActiveRequestForAcceptance() }
    }

    /// 활성 요청 상태를 백그라운드 폴링. 어느 화면에 있든 수락 알림/무응답 AI 발신을 자동 처리 후 종료.
    private func pollActiveRequestForAcceptance() async {
        guard activeRequestId != 0 else { return }
        let requestId = Int64(activeRequestId)
        let service = EmergencyRequestService()
        await LocalNotifier.shared.requestAuthorization()
        while !Task.isCancelled {
            if let status = try? await service.status(requestId: requestId) {
                switch status.status {
                case .accepted:
                    LocalNotifier.shared.notifyAcceptedRequest(requestId: requestId, hospitalName: status.acceptedHospitalName)
                    return
                case .closed:
                    if status.acceptedHospitalName != nil {
                        LocalNotifier.shared.notifyAcceptedRequest(requestId: requestId, hospitalName: status.acceptedHospitalName)
                    } else {
                        // 수락 없이 마감(전부 미응답) → AI 순차 발신 자동 시작.
                        await startAICallIfNeeded(requestId: requestId, service: service)
                    }
                    return
                default:
                    break
                }
            }
            try? await Task.sleep(for: .seconds(5))
        }
    }

    /// 무응답 마감 시 AI 순차 발신을 자동 시작한다(요청당 1회, 상태화면 트리거와 UserDefaults로 중복 방지).
    private func startAICallIfNeeded(requestId: Int64, service: EmergencyRequestService) async {
        let defaults = UserDefaults.standard
        guard defaults.integer(forKey: AppConfig.aiCallStartedRequestKey) != Int(requestId) else { return }
        if let response = try? await service.startAICall(requestId: requestId) {
            defaults.set(Int(requestId), forKey: AppConfig.aiCallStartedRequestKey)
            if let sessionId = response.sessionId {
                defaults.set(Int(sessionId), forKey: AppConfig.aiCallSessionKey)
            }
        }
    }

    @ViewBuilder
    private func destination(for route: ParamedicRoute) -> some View {
        switch route {
        case .detail(let hospital):
            HospitalDetailView(
                hospital: hospital,
                onBack: { path.removeLast() },
                onCall: { path.append(ParamedicRoute.voiceInput([$0])) }
            )
        case .voiceInput(let hospitals):
            VoiceInputView(
                hospitals: hospitals,
                onBack: { path.removeLast() },
                onSubmitted: { requestId in
                    // 생성된 요청을 활성 요청으로 저장하고, 스택을 초기화한 뒤 상태 화면을 depth 1로 띄운다.
                    activeRequestId = Int(requestId)
                    path = NavigationPath()
                    path.append(ParamedicRoute.requestStatus(requestId: requestId))
                }
            )
        case .requestStatus(let requestId):
            RequestStatusView(
                requestId: requestId,
                onBack: { path.removeLast() }
            )
        }
    }
}
