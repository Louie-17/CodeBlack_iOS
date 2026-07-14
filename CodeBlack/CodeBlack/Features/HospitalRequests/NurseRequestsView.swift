//
//  NurseRequestsView.swift
//  CodeBlack
//
//  화면 — 병원 담당자 요청 목록. 탭(받은 요청/완료 요청)에 따라 필터링해 표시한다.
//  데이터 로드/폴링/Live Activity는 상위 NurseFlowView가 소유한다.
//

import SwiftUI
import CoreLocation

struct NurseRequestsView: View {
    let kind: NurseTab
    let viewModel: HospitalRequestListViewModel

    @Environment(AuthViewModel.self) private var auth
    @Environment(NurseHospitalInfo.self) private var hospital

    let onSelect: (NurseRequestItem) -> Void
    /// 안 읽은 알림 수(헤더 배지).
    let unreadCount: Int
    /// 알림 버튼 탭 → 알림 시트 열기.
    let onBell: () -> Void

    private var title: String { kind == .received ? "수신된 요청" : "완료 요청" }
    private var emptyText: String { kind == .received ? "수신된 요청이 없습니다" : "완료된 요청이 없습니다" }

    private var filtered: [HospitalRequestResponse] {
        switch kind {
        case .received: return viewModel.requests.filter { $0.status == .pending }
        case .completed: return viewModel.requests.filter { $0.status != .pending }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .background(AppColor.bgGray)
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
            }
            HStack(alignment: .center, spacing: 8) {
                Text(title)
                    .font(.heading3)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                bedBadge
                bellBadge
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(AppColor.bgWhite)
    }

    private var bellBadge: some View {
        Button(action: onBell) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColor.brandGreenDark)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(AppColor.greenBg2))
                if unreadCount > 0 {
                    Text(unreadCount > 99 ? "99+" : "\(unreadCount)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(AppColor.emergencyRed))
                        .offset(x: 5, y: -5)
                }
            }
        }
        .buttonStyle(.plain)
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
            if filtered.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(filtered) { request in
                            let item = NurseRequestItem(from: request)
                            Button {
                                onSelect(item)
                            } label: {
                                RequestCard(
                                    item: item,
                                    kind: kind,
                                    hospitalCoordinate: hospital.coordinate
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 110)   // 하단 플로팅 탭바 여백
                }
                .refreshable {
                    if let loginId = auth.loginId {
                        await viewModel.refresh(loginId: loginId)
                    }
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
            Image(systemName: kind == .received ? "tray" : "checkmark.circle")
                .font(.system(size: 28))
                .foregroundStyle(AppColor.textSecondary)
            Text(emptyText)
                .font(.heading7)
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
        }
    }
}

// MARK: - 요청 카드

private struct RequestCard: View {
    let item: NurseRequestItem
    let kind: NurseTab
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
                trailing
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

    @ViewBuilder
    private var trailing: some View {
        if kind == .received {
            HStack(spacing: 4) {
                Text("확인").font(.heading8)
                Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(AppColor.brandGreen))
        } else {
            let info = Self.statusInfo(item.status)
            Text(info.text)
                .font(.heading8)
                .foregroundStyle(info.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(info.color.opacity(0.15)))
        }
    }

    private static func statusInfo(_ status: HospitalRequestStatus?) -> (text: String, color: Color) {
        switch status {
        case .accepted: return ("수락함", AppColor.brandGreenDark)
        case .canceled: return ("취소됨", AppColor.textSecondary)
        case .noResponse: return ("미응답", AppColor.emergencyRed)
        default: return ("처리됨", AppColor.textSecondary)
        }
    }
}
