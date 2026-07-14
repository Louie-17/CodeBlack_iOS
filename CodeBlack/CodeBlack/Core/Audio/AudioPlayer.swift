//
//  AudioPlayer.swift
//  CodeBlack
//
//  원격 음성(환자 상태 녹음) 다운로드 후 재생. 재생 상태/진행/길이를 노출한다.
//

import Foundation
import AVFoundation
import Observation

@MainActor
@Observable
final class AudioPlayer {

    enum LoadState: Equatable {
        case idle
        case loading
        case ready
        case failed
        case empty   // 음성 없음(hasVoice=false 등)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var isPlaying = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0

    private var player: AVAudioPlayer?
    private var timer: Timer?

    /// 0...1 재생 진행률.
    var progress: Double { duration > 0 ? min(1, max(0, currentTime / duration)) : 0 }

    /// 원격 음성을 내려받아 재생 준비한다.
    func load(url: URL) async {
        guard loadState != .loading, loadState != .ready else { return }
        loadState = .loading
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                loadState = http.statusCode == 404 ? .empty : .failed
                return
            }
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            let newPlayer = try AVAudioPlayer(data: data)
            newPlayer.prepareToPlay()
            player = newPlayer
            duration = newPlayer.duration
            currentTime = 0
            loadState = .ready
        } catch {
            loadState = .failed
        }
    }

    /// 재생/일시정지 토글.
    func toggle() {
        guard let player else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
            stopTimer()
        } else {
            if currentTime >= duration { currentTime = 0; player.currentTime = 0 }
            try? AVAudioSession.sharedInstance().setActive(true)
            player.play()
            isPlaying = true
            startTimer()
        }
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
        currentTime = 0
        stopTimer()
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let player = self.player else { return }
                self.currentTime = player.currentTime
                if !player.isPlaying {
                    self.isPlaying = false
                    self.stopTimer()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
