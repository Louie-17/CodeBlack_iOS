//
//  HospitalSearchView.swift
//  CodeBlack
//
//  화면 2 — 가까운 응급실 찾기. 정렬 탭 + 병원 카드 리스트.
//

import SwiftUI

struct HospitalSearchView: View {
    @Environment(LocationProvider.self) private var location
    @Environment(AuthViewModel.self) private var auth
    @State private var viewModel = HospitalListViewModel()

    /// 병원 선택 시 상세로 이동.
    let onSelect: (SelectedHospital) -> Void
    /// 병원 선택 시 상세로 이동은 onSelect 로 처리.

    var body: some View {
        VStack(spacing: 0) {
            header
            sortTabs
            content
        }
        .background(AppColor.bgGray)
        .task {
            await location.resolveOnce()
            if case .idle = viewModel.loadState {
                await viewModel.load(coordinate: location.current)
            }
        }
    }

    // MARK: 헤더

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("가까운 응급실 찾기")
                    .font(.heading4)
                    .foregroundStyle(AppColor.textPrimary)
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 11))
                    Text(location.placeName ?? "위치 확인 중…")
                        .font(.caption6)
                }
                .foregroundStyle(AppColor.textSecondary)
            }
            Spacer(minLength: 8)
            Button {
                auth.logout()
            } label: {
                Text("로그아웃")
                    .font(.caption6)
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .overlay(
                        Capsule().strokeBorder(AppColor.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(AppColor.bgWhite)
    }

    // MARK: 정렬 탭

    private var sortTabs: some View {
        HStack(spacing: 8) {
            ForEach(HospitalListViewModel.sortTabs, id: \.self) { tab in
                let selected = viewModel.sort == tab
                Button {
                    Task { await viewModel.changeSort(tab, coordinate: location.current) }
                } label: {
                    Text(HospitalListViewModel.tabTitle(tab))
                        .font(.heading8)
                        .foregroundStyle(selected ? .white : AppColor.textSecondary)
                        .padding(.horizontal, 16)
                        .frame(height: 36)
                        .background(
                            Capsule().fill(selected ? AppColor.brandGreen : AppColor.bgGray2)
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppColor.bgWhite)
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
            if viewModel.hospitals.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.hospitals) { hospital in
                            Button {
                                onSelect(selection(from: hospital))
                            } label: {
                                HospitalCard(hospital: hospital, availableBeds: viewModel.displayBeds(for: hospital))
                            }
                            .buttonStyle(.plain)
                            .onAppear {
                                Task { await viewModel.loadAccurateBeds(for: hospital.hospitalId) }
                            }
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
            Text("병원을 불러오지 못했습니다")
                .font(.heading7)
                .foregroundStyle(AppColor.textPrimary)
            Text(message)
                .font(.caption5)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
            Button("다시 시도") {
                Task { await viewModel.load(coordinate: location.current) }
            }
            .font(.heading8)
            .foregroundStyle(AppColor.brandGreenDark)
            .padding(.top, 4)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "building.2")
                .font(.system(size: 28))
                .foregroundStyle(AppColor.textSecondary)
            Text("주변 응급실이 없습니다")
                .font(.heading7)
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
        }
    }

    private func selection(from hospital: HospitalRecommendationResponse) -> SelectedHospital {
        SelectedHospital(
            hospitalId: hospital.hospitalId ?? "",
            name: hospital.name ?? "이름 미상",
            latitude: hospital.latitude,
            longitude: hospital.longitude,
            distanceKilometers: hospital.distanceKilometers,
            availableBeds: viewModel.displayBeds(for: hospital)
        )
    }
}

// MARK: - 병원 카드

private struct HospitalCard: View {
    let hospital: HospitalRecommendationResponse
    /// 표시할 가용병상 수(상세 API 정확값 우선).
    let availableBeds: Int?

    private var congestion: Congestion { Congestion(availableBeds: availableBeds) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(hospital.name ?? "이름 미상")
                    .font(.heading7)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                CongestionBadge(congestion: congestion)
            }

            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColor.brandGreenDark)
                Text(HospitalFormat.distance(hospital.distanceKilometers))
                    .font(.caption4)
                    .foregroundStyle(AppColor.textPrimary)
                Text("·")
                    .foregroundStyle(AppColor.separator)
                Text(HospitalFormat.eta(hospital.distanceKilometers))
                    .font(.caption4)
                    .foregroundStyle(AppColor.textSecondary)
            }

            BedGauge(availableBeds: availableBeds)

            if hospital.recommendationScore != nil || !(hospital.equipmentTypes ?? []).isEmpty {
                HStack(spacing: 6) {
                    if let score = hospital.recommendationScore {
                        AIRecommendBadge(score: score)
                    }
                    ForEach((hospital.equipmentTypes ?? []).prefix(3), id: \.self) { equipment in
                        TagChip(text: HospitalFormat.equipmentLabel(equipment))
                    }
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColor.bgWhite)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColor.border, lineWidth: 1)
        )
    }
}
