//
//  EmergencyRequestService.swift
//  CodeBlack
//
//  Emergency Requests 태그 API. 구급대원 환자 수용 요청 생성/현황.
//

import Foundation

struct EmergencyRequestService {

    var client = APIClient(baseURL: AppConfig.baseURL)

    /// POST /api/emergency-requests — 선택한 병원들에게 환자 수용 요청 생성.
    /// multipart/form-data: `request` 파트에 환자 정보 JSON, `voice` 파트에 음성 녹음(선택).
    func create(_ request: CreateEmergencyRequest, voice: Data? = nil) async throws -> EmergencyRequestResponse {
        var files: [APIClient.FilePart] = []
        if let voice {
            files.append(
                APIClient.FilePart(
                    name: "voice",
                    filename: "voice.caf",
                    mimeType: "audio/x-caf",
                    data: voice
                )
            )
        }
        return try await client.sendMultipart(
            .post, "/api/emergency-requests",
            jsonPartName: "request",
            jsonPart: request,
            files: files
        )
    }

    /// GET /api/emergency-requests/{requestId} — 요청 + 대상 병원별 상태 조회.
    func detail(requestId: Int64) async throws -> EmergencyRequestResponse {
        try await client.send(.get, "/api/emergency-requests/\(requestId)")
    }

    /// GET /api/emergency-requests/{requestId}/status — 폴링용 현황 조회.
    func status(requestId: Int64) async throws -> EmergencyRequestStatusResponse {
        try await client.send(.get, "/api/emergency-requests/\(requestId)/status")
    }
}
