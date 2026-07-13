//
//  APIError.swift
//  CodeBlack
//

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized(code: String?, message: String?)
    case server(status: Int, code: String?, message: String?)
    case decoding(Error)
    case transport(Error)
    case emptyData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 요청 URL"
        case .invalidResponse:
            return "서버 응답 형식 오류"
        case let .unauthorized(_, message):
            return message ?? "인증에 실패했습니다."
        case let .server(status, _, message):
            return message ?? "서버 오류 (\(status))"
        case let .decoding(error):
            return "응답 파싱 오류: \(error.localizedDescription)"
        case let .transport(error):
            return "네트워크 오류: \(error.localizedDescription)"
        case .emptyData:
            return "서버 응답이 비어 있습니다."
        }
    }
}
