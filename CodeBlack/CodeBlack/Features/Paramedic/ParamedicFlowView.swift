//
//  ParamedicFlowView.swift
//  CodeBlack
//
//  구급대원 플로우 루트. 응급실 찾기 → 병원 정보 → 음성 입력 → 요청 상태.
//

import SwiftUI

struct ParamedicFlowView: View {
    @State private var path = NavigationPath()
    @State private var location = LocationProvider()
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
