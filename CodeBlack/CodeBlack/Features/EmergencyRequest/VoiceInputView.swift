//
//  VoiceInputView.swift
//  CodeBlack
//
//  화면 4 — 환자 상태 음성 입력. 녹음 파형 + 타이머, 취소/정지/확인.
//  STT 결과는 전송 전 확인/수정 단계를 거친다.
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
    @State private var draft = ""

    var body: some View {
        VStack(spacing: 0) {
            BackBar(title: "환자 상태 입력") { cancel() }

            targetChip
                .padding(.horizontal, 20)
                .padding(.top, 4)

            Spacer()
            content
            Spacer()

            if let error = submitError {
                Text(error)
                    .font(.caption5)
                    .foregroundStyle(AppColor.emergencyRed)
                    .padding(.bottom, 8)
            }

            controls
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .background(AppColor.bgWhite)
        .onChange(of: speech.status) { _, newValue in
            if newValue == .finished { draft = speech.transcript }
        }
        .onDisappear { speech.cancel() }
    }

    // MARK: 전송 대상

    private var targetChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "cross.case.fill")
                .font(.system(size: 12))
            Text("전송 대상 · \(hospital.name)")
                .font(.caption5)
        }
        .foregroundStyle(AppColor.brandGreenDark)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(AppColor.greenBg))
    }

    // MARK: 상태별 콘텐츠

    @ViewBuilder
    private var content: some View {
        switch speech.status {
        case .idle:
            promptState
        case .recording:
            recordingState
        case .finished:
            confirmState
        case .denied:
            deniedState
        case .unavailable:
            messageState(icon: "mic.slash", title: "음성 인식을 사용할 수 없습니다",
                         message: "네트워크 또는 기기 설정을 확인하세요.")
        }
    }

    private var promptState: some View {
        VStack(spacing: 14) {
            Image(systemName: "waveform")
                .font(.system(size: 40))
                .foregroundStyle(AppColor.brandGreen)
            Text("말씀해 주세요")
                .font(.heading3)
                .foregroundStyle(AppColor.textPrimary)
            Text("환자 상태를 음성으로 입력하면\n텍스트로 변환됩니다.")
                .font(.body5)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var recordingState: some View {
        VStack(spacing: 20) {
            Text("듣고 있어요…")
                .font(.heading4)
                .foregroundStyle(AppColor.emergencyRed)
            WaveformView(level: speech.audioLevel)
                .frame(height: 64)
                .padding(.horizontal, 40)
            Text(HospitalFormat.timecode(speech.elapsed))
                .font(.heading5)
                .monospacedDigit()
                .foregroundStyle(AppColor.textPrimary)
            if !speech.transcript.isEmpty {
                Text(speech.transcript)
                    .font(.body5)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
    }

    private var confirmState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("변환된 환자 상태")
                .font(.heading7)
                .foregroundStyle(AppColor.textPrimary)
            Text("전송 전 내용을 확인하고 필요하면 수정하세요.")
                .font(.caption5)
                .foregroundStyle(AppColor.textSecondary)
            TextEditor(text: $draft)
                .font(.body5)
                .foregroundStyle(AppColor.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(12)
                .frame(minHeight: 160)
                .background(RoundedRectangle(cornerRadius: 12).fill(AppColor.bgGray2))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(AppColor.border, lineWidth: 1))
        }
        .padding(.horizontal, 20)
    }

    private var deniedState: some View {
        VStack(alignment: .leading, spacing: 12) {
            messageState(icon: "mic.slash.fill", title: "마이크·음성 인식 권한이 필요합니다",
                         message: "설정에서 권한을 허용하거나, 아래에 직접 입력하세요.")
            TextEditor(text: $draft)
                .font(.body5)
                .foregroundStyle(AppColor.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(12)
                .frame(minHeight: 120)
                .background(RoundedRectangle(cornerRadius: 12).fill(AppColor.bgGray2))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(AppColor.border, lineWidth: 1))
        }
        .padding(.horizontal, 20)
    }

    private func messageState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundStyle(AppColor.textSecondary)
            Text(title)
                .font(.heading7)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.caption5)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: 하단 컨트롤

    @ViewBuilder
    private var controls: some View {
        switch speech.status {
        case .idle:
            CTAButton(title: "녹음 시작", style: .red) {
                Task { await speech.start() }
            }
        case .recording:
            HStack(spacing: 12) {
                CTAButton(title: "취소", style: .outline) { cancel() }
                CTAButton(title: "정지", style: .green) { speech.stop() }
            }
        case .finished, .denied, .unavailable:
            HStack(spacing: 12) {
                CTAButton(title: "다시 녹음", style: .outline) {
                    draft = ""
                    Task { await speech.start() }
                }
                CTAButton(
                    title: viewModel.isSubmitting ? "전송 중…" : "확인",
                    style: .green,
                    isEnabled: !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isSubmitting,
                    action: confirm
                )
            }
        }
    }

    private var submitError: String? {
        if case let .failed(message) = viewModel.submitState { return message }
        return nil
    }

    // MARK: 액션

    private func cancel() {
        speech.cancel()
        onBack()
    }

    private func confirm() {
        let loginId = auth.loginId ?? auth.actor?.loginId ?? ""
        Task {
            if let requestId = await viewModel.submit(
                symptomText: draft,
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
    let level: CGFloat

    private let bars = 28
    private let multipliers: [CGFloat] = (0..<28).map { _ in CGFloat.random(in: 0.35...1.0) }

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 4) {
                ForEach(0..<bars, id: \.self) { index in
                    Capsule()
                        .fill(AppColor.emergencyRed)
                        .frame(
                            width: 4,
                            height: max(6, geo.size.height * level * multipliers[index])
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeOut(duration: 0.12), value: level)
        }
    }
}
