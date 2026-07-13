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

    var body: some View {
        NavigationStack(path: $path) {
            HospitalSearchView(
                onSelect: { path.append(ParamedicRoute.detail($0)) }
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
                onCall: { path.append(ParamedicRoute.voiceInput($0)) }
            )
        case .voiceInput(let hospital):
            VoiceInputView(
                hospital: hospital,
                onBack: { path.removeLast() },
                onSubmitted: { requestId in
                    path.append(ParamedicRoute.requestStatus(requestId: requestId))
                }
            )
        case .requestStatus(let requestId):
            RequestStatusView(
                requestId: requestId,
                onDone: { path = NavigationPath() }
            )
        }
    }
}
