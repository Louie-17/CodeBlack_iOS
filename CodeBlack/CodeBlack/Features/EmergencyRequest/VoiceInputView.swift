//
//  VoiceInputView.swift
//  CodeBlack
//
//  화면 4 — 환자 상태 녹음(다크 테마). 녹음중 배지 + 파형 + 타이머, 완료/다시 녹음/다음.
//  STT 결과는 전송 전 확인용으로 화면에 노출된다.
//

import SwiftUI

struct VoiceInputView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(LocationProvider.self) private var location

    let hospital: SelectedHospital
    let onBack: () -> Void
    let onSubmitted: (Int64) -> Void

    @State private var speech = SpeechRecognizer()
    @State private var viewModel = VoiceInputViewModel()
    @State private var draft = ""   // 권한 거부 시 수동 입력

    var body: some View {
        ZStack {
            AppColor.recordingBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer()
                content
                Spacer()

                if let error = submitError {
                    Text(error)
                        .font(.caption5)
                        .foregroundStyle(AppColor.emergencyRed)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }

                controls
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }

        .onDisappear { speech.cancel() }
    }

    // MARK: 상단 바

    private var header: some View {
        ZStack {
            Text("환자 상태 녹음")
                .font(.heading6)
                .foregroundStyle(.white)
            HStack {
                Button(action: cancel) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .frame(height: 52)
        .padding(.horizontal, 12)
    }

    // MARK: 상태별 콘텐츠

    @ViewBuilder
    private var content: some View {
        switch speech.status {
        case .idle:
            idleState
        case .recording:
            recordingState
        case .finished:
            finishedState
        case .denied:
            manualEntryState(
                title: "마이크·음성 인식 권한이 필요합니다",
                message: "설정에서 권한을 허용하거나 아래에 직접 입력하세요."
            )
        case .unavailable:
            manualEntryState(
                title: "음성 인식을 사용할 수 없습니다",
                message: "네트워크·기기 설정을 확인하거나 아래에 직접 입력하세요."
            )
        }
    }

    private var idleState: some View {
        VStack(spacing: 16) {
            Button {
                Task { await speech.start() }
            } label: {
                ZStack {
                    Circle()
                        .fill(AppColor.brandGreen)
                        .frame(width: 116, height: 116)
                    Circle()
                        .strokeBorder(AppColor.brandGreenDeep, lineWidth: 5)
                        .frame(width: 116, height: 116)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)

            Text("클릭하여 환자 상태 녹음")
                .font(.heading4)
                .foregroundStyle(.white)
                .padding(.top, 8)
            Text("예: 개방성 골절")
                .font(.body5)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var recordingState: some View {
        VStack(spacing: 20) {
            recordingBadge
            Text("환자 상태를\n말씀해 주세요")
                .font(.heading3)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text("예: 다발성 외상 의심")
                .font(.body5)
                .foregroundStyle(.white.opacity(0.6))
            WaveformView(level: speech.audioLevel)
                .frame(height: 56)
                .padding(.horizontal, 60)
                .padding(.top, 4)
            Text(timeText)
                .font(.heading4)
                .monospacedDigit()
                .foregroundStyle(.white)
        }
    }

    private var finishedState: some View {
        VStack(spacing: 20) {
            Text("녹음 완료")
                .font(.heading3)
                .foregroundStyle(.white)
            WaveformView(level: 0.6)
                .frame(height: 56)
                .padding(.horizontal, 60)
            Text(timeText)
                .font(.heading4)
                .monospacedDigit()
                .foregroundStyle(.white)
            if !speech.transcript.isEmpty {
                Text(speech.transcript)
                    .font(.caption5)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, 4)
            }
        }
    }

    private func manualEntryState(title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.slash.fill")
                .font(.system(size: 32))
                .foregroundStyle(.white.opacity(0.7))
            Text(title)
                .font(.heading7)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.caption5)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            TextField("환자 상태 입력", text: $draft, axis: .vertical)
                .font(.body5)
                .foregroundStyle(.white)
                .tint(.white)
                .lineLimit(3...6)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.1)))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.2), lineWidth: 1))
                .padding(.top, 8)
        }
        .padding(.horizontal, 28)
    }

    private var recordingBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(AppColor.emergencyRed)
                .frame(width: 7, height: 7)
            Text(speech.isRecording ? "녹음중" : "준비 중")
                .font(.heading10)
                .foregroundStyle(AppColor.emergencyRed)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(AppColor.redBg))
    }

    // MARK: 하단 컨트롤

    @ViewBuilder
    private var controls: some View {
        switch speech.status {
        case .idle:
            EmptyView()   // 시작은 중앙 마이크 버튼으로
        case .recording:
            CTAButton(title: "완료", style: .green) { speech.stop() }
        case .finished:
            VStack(spacing: 12) {
                CTAButton(title: "다시 녹음", style: .outlineGreen, action: restart)
                CTAButton(
                    title: viewModel.isSubmitting ? "전송 중…" : "다음",
                    style: .green,
                    isEnabled: hasText(speech.transcript) && !viewModel.isSubmitting
                ) { confirm(text: speech.transcript) }
            }
        case .denied, .unavailable:
            VStack(spacing: 12) {
                CTAButton(title: "다시 시도", style: .outlineGreen) {
                    Task { await speech.start() }
                }
                CTAButton(
                    title: viewModel.isSubmitting ? "전송 중…" : "다음",
                    style: .green,
                    isEnabled: hasText(draft) && !viewModel.isSubmitting
                ) { confirm(text: draft) }
            }
        }
    }

    private var submitError: String? {
        if case let .failed(message) = viewModel.submitState { return message }
        return nil
    }

    private var timeText: String {
        let total = Int(speech.elapsed)
        return "\(total / 60) : \(String(format: "%02d", total % 60))"
    }

    private func hasText(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: 액션

    private func cancel() {
        speech.cancel()
        onBack()
    }

    private func restart() {
        draft = ""
        Task { await speech.start() }
    }

    private func confirm(text: String) {
        let loginId = auth.loginId ?? auth.actor?.loginId ?? ""
        Task {
            if let requestId = await viewModel.submit(
                symptomText: text,
                paramedicLoginId: loginId,
                target: hospital,
                coordinate: location.current
            ) {
                onSubmitted(requestId)
            }
        }
    }
}

// MARK: - 파형

private struct WaveformView: View {
    /// 0...1 오디오 레벨. 녹음 중엔 실시간 값, 완료 상태엔 고정값.
    let level: CGFloat

    private static let barCount = 28

    /// 중앙이 높은 봉우리 + 잔물결의 안정적(비랜덤) 파형 패턴.
    private static let multipliers: [CGFloat] = (0..<barCount).map { index in
        let envelope = 0.4 + 0.6 * sin(.pi * CGFloat(index) / CGFloat(barCount - 1))
        let ripple = 0.6 + 0.4 * abs(sin(CGFloat(index) * 0.9))
        return envelope * ripple
    }

    var body: some View {
        GeometryReader { geo in
            let scale = 0.2 + 0.8 * min(1, max(0, level))
            HStack(alignment: .center, spacing: 4) {
                ForEach(0..<Self.barCount, id: \.self) { index in
                    Capsule()
                        .fill(AppColor.brandGreen)
                        .frame(width: 4, height: max(4, geo.size.height * scale * Self.multipliers[index]))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeOut(duration: 0.12), value: level)
        }
    }
}
