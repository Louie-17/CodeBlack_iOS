//
//  HospitalDetailView.swift
//  CodeBlack
//
//  화면 3 — 병원 정보. 거리/가용병상, 주소·대표번호, 수용가능 진료 태그, 하단 "호출하기".
//

import SwiftUI

struct HospitalDetailView: View {
    let hospital: SelectedHospital
    let onBack: () -> Void
    /// "호출하기" → 음성 입력 화면으로.
    let onCall: (SelectedHospital) -> Void

    @State private var viewModel = HospitalDetailViewModel()

    private var congestion: Congestion {
        Congestion(availableBeds: viewModel.detail?.availableBeds)
    }

    var body: some View {
        VStack(spacing: 0) {
            BackBar(title: "병원 정보", onBack: onBack)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    titleBlock
                    statsRow
                    infoSection
                    equipmentSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

            callBar
        }
        .background(AppColor.bgGray)
        .task { await viewModel.load(hospitalId: hospital.hospitalId) }
    }

    // MARK: 타이틀

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(viewModel.detail?.name ?? hospital.name)
                    .font(.heading3)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer(minLength: 8)
                CongestionBadge(congestion: congestion)
            }
            if let available = viewModel.detail?.emergencyAvailable {
                HStack(spacing: 4) {
                    Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(available ? "응급 수용 가능" : "응급 수용 불가")
                }
                .font(.caption5)
                .foregroundStyle(available ? AppColor.brandGreenDark : AppColor.emergencyRed)
            }
        }
    }

    // MARK: 통계 (거리 / 가용병상)

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(
                title: "거리",
                value: HospitalFormat.distance(hospital.distanceKilometers),
                caption: HospitalFormat.eta(hospital.distanceKilometers),
                tint: AppColor.brandGreenDark
            )
            statCard(
                title: "가용병상",
                value: "\(viewModel.detail?.availableBeds ?? 0)",
                caption: congestion.label,
                tint: congestion.color
            )
        }
    }

    private func statCard(title: String, value: String, caption: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption6)
                .foregroundStyle(AppColor.textSecondary)
            Text(value)
                .font(.heading3)
                .foregroundStyle(tint)
            Text(caption)
                .font(.caption5)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(AppColor.bgWhite)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14).strokeBorder(AppColor.border, lineWidth: 1)
        )
    }

    // MARK: 주소 / 대표번호

    private var infoSection: some View {
        VStack(spacing: 0) {
            infoRow(icon: "mappin.circle.fill", title: "주소", value: viewModel.detail?.address ?? "-")
            Divider().background(AppColor.border)
            infoRow(
                icon: "phone.circle.fill",
                title: "대표번호",
                value: viewModel.detail?.phoneNumber ?? "-",
                link: phoneURL
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 14).fill(AppColor.bgWhite)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14).strokeBorder(AppColor.border, lineWidth: 1)
        )
    }

    private func infoRow(icon: String, title: String, value: String, link: URL? = nil) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(AppColor.brandGreen)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption6)
                    .foregroundStyle(AppColor.textSecondary)
                Text(value)
                    .font(.body5)
                    .foregroundStyle(AppColor.textPrimary)
            }
            Spacer()
            if let link {
                Link(destination: link) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.brandGreenDark)
                }
            }
        }
        .padding(16)
    }

    private var phoneURL: URL? {
        guard let raw = viewModel.detail?.phoneNumber else { return nil }
        let digits = raw.filter { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel://\(digits)")
    }

    // MARK: 수용 가능 진료/장비

    @ViewBuilder
    private var equipmentSection: some View {
        let equipment = viewModel.detail?.equipmentTypes ?? []
        if !equipment.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("수용 가능 진료·장비")
                    .font(.heading7)
                    .foregroundStyle(AppColor.textPrimary)
                FlowRow(spacing: 8) {
                    ForEach(equipment, id: \.self) { item in
                        TagChip(text: HospitalFormat.equipmentLabel(item), filled: true)
                    }
                }
            }
        }
    }

    // MARK: 하단 CTA

    private var callBar: some View {
        VStack(spacing: 0) {
            Divider().background(AppColor.border)
            CTAButton(title: "호출하기") { onCall(hospital) }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
        .background(AppColor.bgWhite)
    }
}

// MARK: - 태그 자동 줄바꿈 레이아웃

/// 태그 칩을 폭에 맞춰 자동 줄바꿈하는 간단한 Layout.
struct FlowRow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [CGFloat] = [0]
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var x: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                totalHeight += rowHeight + spacing
                rowHeight = 0
                x = 0
                rows.append(0)
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
