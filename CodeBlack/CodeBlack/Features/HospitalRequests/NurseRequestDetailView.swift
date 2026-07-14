//
//  NurseRequestDetailView.swift
//  CodeBlack
//
//  화면 — 수신된 요청 상세. 위치/음성 재생+전사/지도/수락.
//

import SwiftUI
import CoreLocation
import MapKit

struct NurseRequestDetailView: View {
    let item: NurseRequestItem
    let onBack: () -> Void

    @Environment(AuthViewModel.self) private var auth
    @Environment(NurseHospitalInfo.self) private var hospital

    @State private var viewModel = HospitalRequestDetailViewModel()
    @State private var audio = AudioPlayer()
    @State private var placeName: String?
    @State private var showFullMap = false

    private let requestService = HospitalRequestService()

    private var patientCoordinate: CLLocationCoordinate2D? {
        guard let lat = item.latitude, let lng = item.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    private var currentStatus: HospitalRequestStatus? {
        viewModel.updatedStatus ?? item.status
    }

    var body: some View {
        VStack(spacing: 0) {
            BackChevronBar(onBack: onBack)
            ScrollView {
                VStack(spacing: 16) {
                    locationCard
                    voiceCard
                    mapCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            acceptBar
        }
        .background(AppColor.bgGray)
        .task {
            if let lat = item.latitude, let lng = item.longitude {
                placeName = await ReverseGeocoder.placeName(latitude: lat, longitude: lng) ?? "환자 발생 위치"
            } else {
                placeName = "환자 발생 위치"
            }
            if item.hasVoice, let url = requestService.voiceURL(emergencyRequestId: item.emergencyRequestId) {
                await audio.load(url: url)
            }
        }
        .onDisappear { audio.stop() }
    }

    // MARK: 위치

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("현 위치 : \(placeName ?? "확인 중…")")
                .font(.heading6)
                .foregroundStyle(AppColor.textPrimary)
            Text(distanceText)
                .font(.caption4)
                .foregroundStyle(AppColor.textSecondary)
            Divider().background(AppColor.border)
            Text("\(HospitalFormat.relativeTime(iso: item.createdAt)) 요청함")
                .font(.caption4)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var distanceText: String {
        guard let km = HospitalRequestListViewModel.distanceKilometers(
            from: hospital.coordinate, toLatitude: item.latitude, longitude: item.longitude
        ) else { return "거리 정보 없음" }
        return "\(HospitalFormat.distance(km))  \(HospitalFormat.eta(km)) 남음"
    }

    // MARK: 음성 + 전사

    private var voiceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("환자 상태 녹음")
                    .font(.heading6)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                if item.hasVoice {
                    Text("음성녹음 · \(HospitalFormat.timecode(audio.duration))")
                        .font(.caption5)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }

            if item.hasVoice {
                player
            }

            if !item.symptomText.isEmpty {
                Text("\"\(item.symptomText)\"")
                    .font(.body4)
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(5)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var player: some View {
        HStack(spacing: 14) {
            Button {
                audio.toggle()
            } label: {
                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(AppColor.brandGreen))
            }
            .buttonStyle(.plain)
            .disabled(audio.loadState != .ready)
            .opacity(audio.loadState == .ready ? 1 : 0.5)

            PlaybackWaveform(progress: audio.progress)
                .frame(height: 34)

            Text(HospitalFormat.playback(audio.currentTime, audio.duration))
                .font(.caption5)
                .monospacedDigit()
                .foregroundStyle(AppColor.textPrimary)
        }
        .padding(.vertical, 4)
    }

    // MARK: 지도

    private var mapCard: some View {
        RouteMapView(patient: patientCoordinate, hospital: hospital.coordinate, interactive: false)
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16).strokeBorder(AppColor.border, lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(AppColor.bgWhite.opacity(0.9)))
                    .padding(10)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16))
            .onTapGesture { showFullMap = true }
            .fullScreenCover(isPresented: $showFullMap) {
                FullRouteMapView(patient: patientCoordinate, hospital: hospital.coordinate)
            }
    }

    // MARK: 하단 수락

    @ViewBuilder
    private var acceptBar: some View {
        VStack(spacing: 0) {
            Divider().background(AppColor.border)
            Group {
                switch currentStatus {
                case .accepted:
                    statusLabel("이미 수락한 요청입니다", color: AppColor.brandGreenDark)
                case .canceled:
                    statusLabel("다른 병원에서 수락되어 취소된 요청입니다", color: AppColor.textSecondary)
                case .noResponse:
                    statusLabel("미응답으로 마감된 요청입니다", color: AppColor.textSecondary)
                default:
                    VStack(spacing: 8) {
                        if case let .failed(message) = viewModel.acceptState {
                            Text(message)
                                .font(.caption5)
                                .foregroundStyle(AppColor.emergencyRed)
                        }
                        CTAButton(
                            title: viewModel.isAccepting ? "수락 처리 중…" : "수락하기",
                            isEnabled: !viewModel.isAccepting,
                            action: accept
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(AppColor.bgWhite)
    }

    private func statusLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.heading7)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
    }

    private func accept() {
        guard let loginId = auth.loginId else { return }
        Task { await viewModel.accept(requestId: item.hospitalRequestId, loginId: loginId) }
    }
}

// MARK: - 재생 파형(진행률 표시)

private struct PlaybackWaveform: View {
    let progress: Double

    private static let bars = 26
    private static let heights: [CGFloat] = (0..<bars).map { index in
        let envelope = 0.35 + 0.65 * sin(.pi * CGFloat(index) / CGFloat(bars - 1))
        let ripple = 0.6 + 0.4 * abs(sin(CGFloat(index) * 1.1))
        return envelope * ripple
    }

    var body: some View {
        GeometryReader { geo in
            let playedCount = Int((Double(Self.bars) * progress).rounded())
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<Self.bars, id: \.self) { index in
                    Capsule()
                        .fill(index < playedCount ? AppColor.brandGreen : AppColor.brandGreen.opacity(0.3))
                        .frame(width: 3, height: max(4, geo.size.height * Self.heights[index]))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}
