//
//  SpeechRecognizer.swift
//  CodeBlack
//
//  환자 상태 음성 입력용 STT. SFSpeechRecognizer(ko-KR) + AVAudioEngine.
//  실시간 전사(transcript), 경과 시간(elapsed), 오디오 레벨(audioLevel: 파형)을 제공한다.
//  변환 텍스트는 전송 전 사용자 확인 단계를 반드시 거친다.
//

import Foundation
import Speech
import AVFoundation
import Observation

@MainActor
@Observable
final class SpeechRecognizer {

    enum Status: Equatable {
        case idle
        case recording
        case finished
        case denied        // 마이크/음성인식 권한 거부
        case unavailable   // 인식기 사용 불가
    }

    private(set) var status: Status = .idle
    private(set) var transcript: String = ""
    private(set) var elapsed: TimeInterval = 0
    /// 파형 렌더링용 정규화 오디오 레벨(0...1).
    private(set) var audioLevel: CGFloat = 0

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var timer: Timer?
    private var startedAt: Date?
    private var audioFile: AVAudioFile?
    /// 방금 녹음한 음성 파일 URL(정지 후 유효). 서버 전송용.
    private(set) var recordedFileURL: URL?

    var isRecording: Bool { status == .recording }

    // MARK: - 공개 제어

    /// 녹음 + 실시간 전사 시작.
    func start() async {
        guard status != .recording else { return }
        guard await requestAuthorization() else { status = .denied; return }
        guard let recognizer, recognizer.isAvailable else { status = .unavailable; return }

        transcript = ""
        elapsed = 0
        cleanupRecording()
        do {
            try beginSession(with: recognizer)
            status = .recording
            startTimer()
        } catch {
            teardownEngine()
            status = .unavailable
        }
    }

    /// 녹음 정지(전사 확정). 결과 transcript는 유지된다.
    func stop() {
        teardownEngine()
        stopTimer()
        audioLevel = 0
        if status == .recording { status = .finished }
    }

    /// 취소: 녹음/전사를 버리고 초기 상태로.
    func cancel() {
        task?.cancel()
        teardownEngine()
        stopTimer()
        cleanupRecording()
        transcript = ""
        elapsed = 0
        audioLevel = 0
        status = .idle
    }

    /// 사용자가 확인 화면에서 텍스트를 직접 수정할 수 있게 한다.
    func updateTranscript(_ text: String) {
        transcript = text
    }

    // MARK: - 세션 구성

    private func beginSession(with recognizer: SFSpeechRecognizer) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        // 전송용 음성 파일 기록(선택). 실패해도 STT는 계속한다.
        // 재생 호환을 위해 AAC(.m4a, ftyp 컨테이너)로 인코딩한다. (CAF/PCM은 브라우저 재생 불가)
        let fileURL = SpeechRecognizer.makeVoiceFileURL()
        let aacSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: format.channelCount,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let recordingFile = try? AVAudioFile(
            forWriting: fileURL,
            settings: aacSettings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        self.audioFile = recordingFile
        self.recordedFileURL = recordingFile == nil ? nil : fileURL

        // 오디오 스레드에서 호출되는 탭. 로컬 캡처로 self 격리 프로퍼티 접근을 피한다.
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
            try? recordingFile?.write(from: buffer)
            let level = SpeechRecognizer.normalizedLevel(buffer)
            Task { @MainActor [weak self] in self?.audioLevel = level }
        }

        audioEngine.prepare()
        try audioEngine.start()

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil {
                    self.stop()
                }
            }
        }
    }

    private func teardownEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.finish()
        task = nil
        request = nil
        audioFile = nil   // 파일 핸들 해제 → 기록 파일 마무리(flush)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// 기록 중이던/직전 음성 파일을 삭제하고 참조를 비운다.
    private func cleanupRecording() {
        audioFile = nil
        if let url = recordedFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordedFileURL = nil
    }

    nonisolated private static func makeVoiceFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("codeblack-voice-\(UUID().uuidString).m4a")
    }

    // MARK: - 타이머

    private func startTimer() {
        startedAt = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let startedAt = self.startedAt else { return }
                self.elapsed = Date().timeIntervalSince(startedAt)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        startedAt = nil
    }

    // MARK: - 권한

    private func requestAuthorization() async -> Bool {
        let speechAuthorized = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard speechAuthorized else { return false }

        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - 오디오 레벨 계산 (nonisolated)

    nonisolated private static func normalizedLevel(_ buffer: AVAudioPCMBuffer) -> CGFloat {
        guard let channel = buffer.floatChannelData?[0] else { return 0 }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return 0 }

        var sumSquares: Float = 0
        for index in 0..<count {
            let sample = channel[index]
            sumSquares += sample * sample
        }
        let rms = sqrt(sumSquares / Float(count))
        let decibels = 20 * log10(max(rms, 1e-7))
        // 대략 -50dB(무음) ~ 0dB(최대)를 0...1로 정규화.
        let clamped = max(-50, min(0, decibels))
        return CGFloat((clamped + 50) / 50)
    }
}
