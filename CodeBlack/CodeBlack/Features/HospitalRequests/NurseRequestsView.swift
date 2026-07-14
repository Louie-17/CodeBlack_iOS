//
//  NurseRequestsView.swift
//  CodeBlack
//
//  화면 — 수신된 요청 목록(병원 담당자). 소속 병원 + 가용병상 + 요청 카드 리스트.
//

import SwiftUI
import CoreLocation

struct NurseRequestsView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(NurseHospitalInfo.self) private var hospital

    @State private var viewModel = HospitalRequestListViewModel()

    let onSelect: (NurseRequestItem) -> Void
    let onLogout: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .background(AppColor.bgGray)
        .task {
            guard let loginId = auth.loginId else { return }
            // 최초 1회는 스피너와 함께 로드, 이후 15초 주기로 갱신 + Live Activity 동기화.
            if case .idle = viewModel.loadState {
                await viewModel.load(loginId: loginId)
            }
            NurseLiveActivityManager.shared.sync(hospitalName: hospital.name ?? "", hospitalCoordinate: hospital.coordinate, requests: viewModel.requests)
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                await viewModel.refresh(loginId: loginId)
                NurseLiveActivityManager.shared.sync(hospitalName: hospital.name ?? "", hospitalCoordinate: hospital.coordinate, requests: viewModel.requests)
            }
        }
    }

    // MARK: 헤더

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColor.brandGreen)
                Text("소속 병원 · \(hospital.name ?? "-")")
                    .font(.caption4)
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                Button {
                    NurseLiveActivityManager.shared.end()
                    onLogout()
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.textSecondary)
                }
                .buttonStyle(.plain)
            }
            HStack(alignment: .center) {
                Text("수신된 요청")
                    .font(.heading3)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                bedBadge
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(AppColor.bgWhite)
    }

    private var bedBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 12))
            Text("\(hospital.availableBeds ?? 0)")
                .font(.heading8)
        }
        .foregroundStyle(AppColor.brandGreenDark)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(AppColor.greenBg2))
    }

    // MARK: 콘텐츠

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            Spacer()
            ProgressView().tint(AppColor.brandGreen)
            Spacer()
        case .failed(let message):
            errorState(message)
        case .loaded:
            if viewModel.requests.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(viewModel.requests) { request in
                            let item = NurseRequestItem(from: request)
                            Button {
                                onSelect(item)
                            } label: {
                                RequestCard(
                                    item: item,
                                    hospitalCoordinate: hospital.coordinate
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(AppColor.warningYellow)
            Text("요청을 불러오지 못했습니다")
                .font(.heading7)
                .foregroundStyle(AppColor.textPrimary)
            Text(message)
                .font(.caption5)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
            Button("다시 시도") {
                if let loginId = auth.loginId {
                    Task { await viewModel.load(loginId: loginId) }
                }
            }
            .font(.heading8)
            .foregroundStyle(AppColor.brandGreenDark)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundStyle(AppColor.textSecondary)
            Text("수신된 요청이 없습니다")
                .font(.heading7)
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
        }
    }
}

// MARK: - 요청 카드

private struct RequestCard: View {
    let item: NurseRequestItem
    let hospitalCoordinate: CLLocationCoordinate2D?

    @State private var placeName: String?

    private var distanceText: String {
        guard let km = HospitalRequestListViewModel.distanceKilometers(
            from: hospitalCoordinate, toLatitude: item.latitude, longitude: item.longitude
        ) else { return "거리 정보 없음" }
        return "\(HospitalFormat.distance(km))  \(HospitalFormat.eta(km)) 남음"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("위치 : \(placeName ?? "확인 중…")")
                .font(.heading6)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
            Text(distanceText)
                .font(.caption4)
                .foregroundStyle(AppColor.textSecondary)

            Divider().background(AppColor.border)

            HStack {
                Text("\(HospitalFormat.relativeTime(iso: item.createdAt)) 요청함")
                    .font(.caption4)
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                HStack(spacing: 4) {
                    Text("확인")
                        .font(.heading8)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(AppColor.brandGreen))
            }
        }
        .padding(16)
        .cardStyle()
        .task {
            if let lat = item.latitude, let lng = item.longitude {
                placeName = await ReverseGeocoder.placeName(latitude: lat, longitude: lng) ?? "환자 발생 위치"
            } else {
                placeName = "환자 발생 위치"
            }
        }
    }
}