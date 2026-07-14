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
                VStack(spacing: 20) {
                    headline
                    if viewModel.isNoResponse {
                        // 무응답: AI 발신 카드를 헤드라인 바로 아래에 크게 노출.
                        if viewModel.aiCallStarted {
                            aiCallCard
                        }
                        noResponseCard
                        if !viewModel.callCandidates.isEmpty {
                            callCandidatesCard
                        }
                    } else if viewModel.isAccepted {
                        acceptedCard
                    }
                    timelineCard
                    if !viewModel.hospitals.isEmpty {
                        hospitalsCard
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
            Text(viewModel.isAccepted ? "병원 수락 완료" : viewModel.isNoResponse ? "미응답으로 마감" : "병원 확인 대기 중")
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
        if viewModel.isNoResponse {
            return "수용 가능한 응급실의 응답이 없어 요청이 마감되었습니다"
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
        } else if viewModel.isNoResponse {
            ZStack {
                Circle().fill(AppColor.bgGray2).frame(width: 96, height: 96)
                Image(systemName: "xmark")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(AppColor.textSecondary)
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

    // MARK: 미응답 마감

    private var noResponseCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppColor.textSecondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("미응답 마감")
                    .font(.caption6)
                    .foregroundStyle(AppColor.textSecondary)
                Text("응답한 병원이 없습니다")
                    .font(.heading7)
                    .foregroundStyle(AppColor.textPrimary)
            }
            Spacer()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(AppColor.bgGray2))
    }

    // MARK: AI 순차 발신

    private var aiCallCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "phone.arrow.up.right.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColor.brandGreenDark)
                Text("AI 순차 발신")
                    .font(.heading7)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                if let status = viewModel.aiCallStatus?.status ?? viewModel.aiCall?.status {
                    Text(aiCallStatusLabel(status))
                        .font(.heading9)
                        .foregroundStyle(AppColor.brandGreenDark)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(AppColor.brandGreenDark.opacity(0.12)))
                }
            }
            if viewModel.aiCallStatus?.connected == true {
                HStack(spacing: 6) {
                    Image(systemName: "phone.connection.fill")
                        .font(.system(size: 12))
                    Text("병원이 전화를 받았습니다")
                        .font(.heading9)
                }
                .foregroundStyle(AppColor.brandGreenDark)
            } else {
                Text("수용 가능성이 높은 순으로 병원에 자동으로 전화해 AI가 환자 안내를 진행합니다.")
                    .font(.caption5)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let name = viewModel.aiCallStatus?.currentHospitalName ?? viewModel.aiCall?.currentHospitalName {
                aiCallInfoRow("현재 발신 병원", name)
            }
            if let number = viewModel.aiCall?.dialedNumber {
                aiCallInfoRow("발신 번호", number)
            }
            if let target = viewModel.aiCallStatus?.targetCount, target > 0 {
                let idx = min((viewModel.aiCallStatus?.currentIndex ?? 0) + 1, target)
                aiCallInfoRow("발신 진행", "\(idx) / \(target) 순위")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(AppColor.greenBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16).strokeBorder(AppColor.brandGreen, lineWidth: 1.5)
        )
    }

    private func aiCallInfoRow(_ title: String, _ value: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption6)
                .foregroundStyle(AppColor.textSecondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.heading8)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
        }
    }

    private func aiCallStatusLabel(_ status: String) -> String {
        switch status {
        case "CALLING": return "발신 중"
        case "COMPLETED": return "연결됨"
        case "EXHAUSTED": return "모두 미응답"
        default: return status
        }
    }

    // MARK: 직접 연락 후보 병원

    private var callCandidatesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("직접 연락 가능한 병원")
                .font(.heading7)
                .foregroundStyle(AppColor.textPrimary)
            Text("자동 수용이 되지 않아, 아래 병원에 직접 연락해 주세요")
                .font(.caption5)
                .foregroundStyle(AppColor.textSecondary)
                .padding(.top, 4)
                .padding(.bottom, 12)
            ForEach(Array(viewModel.callCandidates.enumerated()), id: \.element.id) { index, candidate in
                if index > 0 {
                    Divider().background(AppColor.border)
                        .padding(.vertical, 10)
                }
                candidateRow(candidate)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func candidateRow(_ candidate: CallCandidateResponse) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 16))
                .foregroundStyle(AppColor.textSecondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(candidate.hospitalName ?? "이름 미상")
                    .font(.heading8)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                if let beds = candidate.availableBeds {
                    Text("가용병상 \(beds)")
                        .font(.caption5)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            Spacer(minLength: 8)
            if let url = telURL(candidate.phoneNumber) {
                Link(destination: url) {
                    HStack(spacing: 5) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("전화")
                            .font(.heading9)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(AppColor.brandGreen))
                }
            }
        }
    }

    private func telURL(_ phone: String?) -> URL? {
        guard let phone else { return nil }
        let digits = phone.filter { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel://\(digits)")
    }

    // MARK: 요청 병원 현황

    private var hospitalsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("요청 병원 현황")
                .font(.heading7)
                .foregroundStyle(AppColor.textPrimary)
                .padding(.bottom, 12)
            ForEach(Array(viewModel.hospitals.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Divider().background(AppColor.border)
                        .padding(.vertical, 10)
                }
                hospitalRow(item)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func hospitalRow(_ item: HospitalRequestSummary) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 16))
                .foregroundStyle(AppColor.textSecondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.hospitalName ?? "이름 미상")
                    .font(.heading8)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                if let beds = item.availableBeds {
                    Text("가용병상 \(beds)")
                        .font(.caption5)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            Spacer(minLength: 8)
            hospitalStatusBadge(item.status)
        }
    }

    private func hospitalStatusBadge(_ status: HospitalRequestStatus?) -> some View {
        let (label, color): (String, Color) = {
            switch status {
            case .accepted: return ("수락", AppColor.brandGreenDark)
            case .pending, .none: return ("대기 중", AppColor.textSecondary)
            case .canceled: return ("취소", AppColor.emergencyRed)
            case .noResponse: return ("미응답", AppColor.textSecondary)
            case .unknown: return ("-", AppColor.textSecondary)
            }
        }()
        return Text(label)
            .font(.heading9)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(color.opacity(0.12)))
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
