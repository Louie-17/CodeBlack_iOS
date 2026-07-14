//
//  RequestStatusView.swift
//  CodeBlack
//
//  화면 — 요청 상태(폴링). 상단 back + 진행 세로 타임라인.
//

import SwiftUI

struct RequestStatusView: View {
    let requestId: Int64
    let onBack: () -> Void

    @State private var viewModel = RequestStatusViewModel()
    @State private var spin: Double = 0

    private typealias Step = RequestStatusViewModel.Step

    var body: some View {
        VStack(spacing: 0) {
            BackBar(title: "요청 상태", onBack: onBack)
            ScrollView {
                VStack(spacing: 28) {
                    headline
                    timelineCard
                    if viewModel.isAccepted {
                        acceptedCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
        }
        .background(AppColor.bgGray)
        .task {
            viewModel.startPolling(requestId: requestId)
            spin = 360
        }
        .onDisappear { viewModel.stop() }
    }

    // MARK: 헤드라인

    private var headline: some View {
        VStack(spacing: 14) {
            statusIcon
                .frame(height: 96)
            Text(viewModel.isAccepted ? "병원 수락 완료" : "병원 확인 대기 중")
                .font(.heading3)
                .foregroundStyle(AppColor.textPrimary)
            Text(headlineSubtitle)
                .font(.body5)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var headlineSubtitle: String {
        if viewModel.isAccepted {
            return "\(viewModel.acceptedHospitalName ?? "병원")에서 환자를 수용합니다"
        }
        return "요청을 전송한 후 대기중입니다"
    }

    @ViewBuilder
    private var statusIcon: some View {
        if viewModel.isAccepted {
            ZStack {
                Circle().fill(AppColor.greenBg).frame(width: 96, height: 96)
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(AppColor.brandGreen)
            }
        } else {
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(AppColor.brandGreen, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .frame(width: 88, height: 88)
                    .rotationEffect(.degrees(spin))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: spin)
                Image(systemName: "location.north.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(AppColor.brandGreen)
                    .rotationEffect(.degrees(45))
            }
        }
    }

    // MARK: 타임라인

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepRow(.sent)
            stepRow(.waiting)
            stepRow(.ready, isLast: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func stepRow(_ step: Step, isLast: Bool = false) -> some View {
        let state = stepState(step)
        return HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                dot(state)
                if !isLast {
                    Rectangle()
                        .fill(connectorColor(step))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 26)

            VStack(alignment: .leading, spacing: 3) {
                Text(step.title)
                    .font(.heading7)
                    .foregroundStyle(titleColor(state))
                Text(step == .sent ? (viewModel.sentTime ?? step.subtitle) : step.subtitle)
                    .font(.caption5)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(.bottom, isLast ? 0 : 22)

            Spacer()
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func dot(_ state: StepState) -> some View {
        switch state {
        case .done:
            ZStack {
                Circle().fill(AppColor.brandGreen).frame(width: 26, height: 26)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
        case .active:
            Circle()
                .strokeBorder(AppColor.brandGreen, lineWidth: 3)
                .frame(width: 26, height: 26)
        case .pending:
            Circle()
                .strokeBorder(AppColor.separator, lineWidth: 2)
                .frame(width: 26, height: 26)
        }
    }

    // MARK: 수락 병원

    private var acceptedCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppColor.brandGreenDark)
            VStack(alignment: .leading, spacing: 2) {
                Text("수락 병원")
                    .font(.caption6)
                    .foregroundStyle(AppColor.textSecondary)
                Text(viewModel.acceptedHospitalName ?? "-")
                    .font(.heading7)
                    .foregroundStyle(AppColor.textPrimary)
            }
            Spacer()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(AppColor.greenBg))
    }

    // MARK: 스텝 상태

    private enum StepState { case done, active, pending }

    private func stepState(_ step: Step) -> StepState {
        let current = viewModel.currentStep.rawValue
        if step.rawValue < current { return .done }
        if step.rawValue == current {
            return viewModel.isAccepted && step == .ready ? .done : .active
        }
        return .pending
    }

    private func titleColor(_ state: StepState) -> Color {
        switch state {
        case .done: return AppColor.textPrimary
        case .active: return AppColor.brandGreenDark
        case .pending: return AppColor.textSecondary
        }
    }

    private func connectorColor(_ step: Step) -> Color {
        switch stepState(step) {
        case .done: return AppColor.brandGreen
        case .active: return AppColor.brandGreen.opacity(0.35)
        case .pending: return AppColor.border
        }
    }
}
