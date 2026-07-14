//
//  NurseFlowView.swift
//  CodeBlack
//
//  간호사(병원) 플로우 루트. 수신된 요청 목록 → 요청 상세(수락).
//

import SwiftUI

struct NurseFlowView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var path = NavigationPath()
    @State private var hospital = NurseHospitalInfo()

    var body: some View {
        NavigationStack(path: $path) {
            NurseRequestsView(
                onSelect: { path.append(NurseRoute.detail($0)) },
                onLogout: { auth.logout() }
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: NurseRoute.self) { route in
                destination(for: route)
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
        .environment(hospital)
        .task {
            await hospital.load(
                hospitalId: auth.actor?.hospitalId,
                fallbackName: auth.actor?.hospitalName
            )
        }
    }

    @ViewBuilder
    private func destination(for route: NurseRoute) -> some View {
        switch route {
        case .detail(let item):
            NurseRequestDetailView(item: item, onBack: { path.removeLast() })
        }
    }
}
