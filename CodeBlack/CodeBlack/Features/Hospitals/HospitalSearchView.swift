//
//  HospitalSearchView.swift
//  CodeBlack
//
//  화면 2 — 가까운 응급실 찾기. 정렬 탭 + 병원 카드 리스트.
//

import SwiftUI

struct HospitalSearchView: View {
    @Environment(LocationProvider.self) private var location
    @AppStorage(AppConfig.activeRequestKey) private var activeRequestId: Int = 0
    @State private var viewModel = HospitalListViewModel()
    /// 요청 대상으로 선택한 병원들(순서 유지, 첫 항목이 우선 병원).
    @State private var selected: [SelectedHospital] = []

    /// 병원 정보(ⓘ) 탭 → 상세로 이동.
    let onSelect: (SelectedHospital) -> Void
    /// 선택한 병원들에 동시 요청 → 음성 입력으로.
    let onRequest: ([SelectedHospital]) -> Void
    /// 현재 상태 보기 → 진행 중인 요청 상태 화면으로.
    let onShowStatus: (Int64) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            sortTabs
            content
        }
        .background(AppColor.bgGray)
        .safeAreaInset(edge: .bottom) {
            if !selected.isEmpty {
                requestBar
            }
        }
        .task {
            await location.resolveOnce()
            if case .idle = viewModel.loadState {
                await viewModel.load(coordinate: location.current)
            }
        }
    }

    // MARK: 헤더

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColor.brandGreen)
                Text("현재 위치 · \(location.placeName ?? "확인 중…")")
                    .font(.caption4)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
                Spacer(minLength: 8)
            }

            HStack(alignment: .center) {
                Text("가까운 병원 찾기")
                    .font(.heading3)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer(minLength: 8)
                if activeRequestId != 0 {
                    Button {
                        onShowStatus(Int64(activeRequestId))
                    } label: {
                        Text("현재 상태 보기")
                            .font(.heading8)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(AppColor.brandGreen))
                    }
                    .buttonStyle(.plain)
                }
            }
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
                            let item = selection(from: hospital)
                            HospitalCard(
                                hospital: hospital,
                                viewModel: viewModel,
                                isSelected: isSelected(item),
                                onInfo: { onSelect(item) }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture { toggle(item) }
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

    // MARK: 선택 / 요청 바

    private func isSelected(_ hospital: SelectedHospital) -> Bool {
        selected.contains { $0.hospitalId == hospital.hospitalId }
    }

    private func toggle(_ hospital: SelectedHospital) {
        if let index = selected.firstIndex(where: { $0.hospitalId == hospital.hospitalId }) {
            selected.remove(at: index)
        } else {
            selected.append(hospital)
        }
    }

    private var requestBar: some View {
        VStack(spacing: 0) {
            Divider().background(AppColor.border)
            CTAButton(title: "선택한 \(selected.count)개 병원에 요청") {
                onRequest(selected)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(AppColor.bgWhite)
    }
}

// MARK: - 병원 카드

private struct HospitalCard: View {
    let hospital: HospitalRecommendationResponse
    /// 병상 값을 직접 관찰하기 위해 뷰모델을 참조한다(LazyVStack 갱신 누락 방지).
    let viewModel: HospitalListViewModel
    /// 요청 대상 선택 여부.
    let isSelected: Bool
    /// 정보(ⓘ) 버튼 탭 → 상세 화면.
    let onInfo: () -> Void

    /// 표시할 가용병상 수(상세 API 정확값 우선). 셀 body에서 직접 읽어 관찰한다.
    private var availableBeds: Int? { viewModel.displayBeds(for: hospital) }

    private var congestion: Congestion { Congestion(availableBeds: availableBeds) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? AppColor.brandGreen : AppColor.border)
                Text(hospital.name ?? "이름 미상")
                    .font(.heading7)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                CongestionBadge(congestion: congestion)
                Button(action: onInfo) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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
                .fill(isSelected ? AppColor.greenBg : AppColor.bgWhite)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isSelected ? AppColor.brandGreen : AppColor.border, lineWidth: isSelected ? 1.5 : 1)
        )
        .task { await viewModel.loadAccurateBeds(for: hospital.hospitalId) }
    }
}
