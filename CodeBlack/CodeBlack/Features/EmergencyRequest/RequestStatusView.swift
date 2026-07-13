//
//  RequestStatusView.swift
//  CodeBlack
//
//  화면 5 — 요청 상태(폴링). 진행 스텝(전송완료→확인대기→이송준비) + 수락 병원.
//

import SwiftUI

struct RequestStatusView: View {
    let requestId: Int64
    /// 메인(검색)으로 돌아가기.
    let onDone: () -> Void

    @State private var viewModel = RequestStatusViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 28) {
                    headline
                    stepIndicator
                    if viewModel.isAccepted {
                        acceptedCard
                    }
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption5)
                            .foregroundStyle(AppColor.emergencyRed)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
            }
            bottomBar
        }
        .background(AppColor.bgGray)
        .task { viewModel.startPolling(requestId: requestId) }
        .onDisappear { viewModel.stop() }
    }

    // MARK: 헤드라인

    private var headline: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(viewModel.isAccepted ? AppColor.greenBg : AppColor.greenBg2)
                    .frame(width: 96, height: 96)
                if viewModel.isAccepted {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(AppColor.systemGreen)
                } else {
                    ProgressView()
                        .controlSize(.large)
                        .tint(AppColor.brandGreen)
                }
            }

            Text(viewModel.isAccepted ? "병원 수락 완료" : "병원 확인 대기 중")
                .font(.heading3)
                .foregroundStyle(AppColor.textPrimary)

            Text(viewModel.isAccepted
                 ? "\(viewModel.acceptedHospitalName ?? "병원")에서 환자를 수용합니다."
                 : "가장 빨리 수용 가능한 병원을 확인하고 있습니다.")
                .font(.body5)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: 진행 스텝

    private var stepIndicator: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(RequestStatusViewModel.Step.allCases, id: \.rawValue) { step in
                stepNode(step)
                if step != RequestStatusViewModel.Step.allCases.last {
                    connector(after: step)
                }
            }
        }
    }

    private func stepNode(_ step: RequestStatusViewModel.Step) -> some View {
        let state = stepState(step)
        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(state == .pending ? AppColor.bgGray2 : AppColor.brandGreen)
                    .frame(width: 36, height: 36)
                if state == .done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                } else if state == .active {
                    Circle().fill(.white).frame(width: 12, height: 12)
                } else {
                    Text("\(step.rawValue + 1)")
                        .font(.heading9)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            Text(step.title)
                .font(.caption5)
                .foregroundStyle(state == .pending ? AppColor.textSecondary : AppColor.textPrimary)
        }
        .frame(width: 72)
    }

    private func connector(after step: RequestStatusViewModel.Step) -> some View {
        Rectangle()
            .fill(stepState(step) == .done ? AppColor.brandGreen : AppColor.border)
            .frame(height: 2)
            .frame(maxWidth: .infinity)
            .padding(.top, 17)
    }

    private enum StepState { case done, active, pending }

    private func stepState(_ step: RequestStatusViewModel.Step) -> StepState {
        let current = viewModel.currentStep.rawValue
        if step.rawValue < current { return .done }
        if step.rawValue == current {
            // 수락(이송준비)에 도달하면 마지막 스텝도 완료로 표시.
            return viewModel.isAccepted && step == .ready ? .done : .active
        }
        return .pending
    }

    // MARK: 수락 병원 카드

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

    // MARK: 하단

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().background(AppColor.border)
            VStack(spacing: 10) {
                CTAButton(title: viewModel.isAccepted ? "이송 시작" : "메인으로", style: .green) {
                    viewModel.stop()
                    onDone()
                }
                if !viewModel.isAccepted {
                    CTAButton(title: "요청 취소", style: .outlineRed) {
                        viewModel.stop()
                        onDone()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(AppColor.bgWhite)
    }
}
