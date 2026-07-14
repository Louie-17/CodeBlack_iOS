//
//  VoiceInputViewModel.swift
//  CodeBlack
//
//  환자 상태 음성 입력 → 확인 → 수용 요청 생성 뷰모델.
//  녹음/전사는 SpeechRecognizer 가 담당하고, 여기서는 확정 텍스트로 요청을 만든다.
//

import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class VoiceInputViewModel {

    enum SubmitState: Equatable {
        case idle
        case submitting
        case failed(String)
    }

    private(set) var submitState: SubmitState = .idle

    private let service = EmergencyRequestService()

    var isSubmitting: Bool { submitState == .submitting }

    /// 확정된 증상 텍스트(+선택 음성 파일)로 수용 요청을 생성한다. 성공 시 requestId 반환.
    func submit(
        symptomText: String,
        paramedicLoginId: String,
        targets: [SelectedHospital],
        coordinate: CLLocationCoordinate2D,
        voiceURL: URL? = nil
    ) async -> Int64? {
        let text = symptomText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            submitState = .failed("환자 상태 텍스트가 비어 있습니다.")
            return nil
        }
        guard !targets.isEmpty else {
            submitState = .failed("요청할 병원을 1개 이상 선택하세요.")
            return nil
        }
        submitState = .submitting
        do {
            let request = CreateEmergencyRequest(
                paramedicLoginId: paramedicLoginId,
                symptomText: text,
                targetHospitals: targets.map { $0.target },
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            let voiceData = voiceURL.flatMap { try? Data(contentsOf: $0) }
            let response = try await service.create(request, voice: voiceData)
            submitState = .idle
            // 요청 전송 완료 로컬 알림(대기 중 안내).
            await LocalNotifier.shared.requestAuthorization()
            LocalNotifier.shared.notify(
                title: "요청 전송 완료",
                body: targets.count == 1
                    ? "\(targets[0].name)에 수용 요청을 보냈습니다. 병원 확인 대기 중입니다."
                    : "\(targets.count)개 병원에 수용 요청을 보냈습니다. 병원 확인 대기 중입니다."
            )
            return response.requestId
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            submitState = .failed(message)
            return nil
        }
    }
}
