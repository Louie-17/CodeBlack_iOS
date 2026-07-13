//
//  APIClient.swift
//  CodeBlack
//
//  async/await + URLSession 기반 API 클라이언트.
//  서버 공통 봉투(APIResponse)를 해석해 성공 시 data 페이로드만 반환한다.
//  인증은 토큰이 아니라 loginId 기반(X-Login-Id 헤더 / loginId 쿼리)이다.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case put = "PUT"
    case delete = "DELETE"
}

struct APIClient {

    let baseURL: URL
    var session: URLSession = .shared
    var decoder: JSONDecoder = JSONDecoder()
    var encoder: JSONEncoder = JSONEncoder()

    /// 요청 전송 후 `APIResponse<T>` 봉투를 해석해 `data` 를 반환한다.
    /// - Parameters:
    ///   - method: HTTP 메서드
    ///   - path: baseURL 기준 경로. 경로 파라미터는 호출부에서 인코딩해 끼워 넣는다.
    ///   - query: 쿼리 파라미터. nil 값 항목은 자동 제외된다.
    ///   - headers: 추가 헤더(예: `X-Login-Id`).
    ///   - body: JSON 본문(Encodable).
    func send<T: Decodable>(
        _ method: HTTPMethod,
        _ path: String,
        query: [String: String?] = [:],
        headers: [String: String] = [:],
        body: (any Encodable)? = nil
    ) async throws -> T {
        guard let resolved = URL(string: path, relativeTo: baseURL),
              var components = URLComponents(url: resolved, resolvingAgainstBaseURL: true) else {
            throw APIError.invalidURL
        }

        let items = query
            .compactMap { key, value in value.map { URLQueryItem(name: key, value: $0) } }
            .sorted { $0.name < $1.name }
        if !items.isEmpty {
            components.queryItems = items
        }

        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                throw APIError.decoding(error)
            }
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        let envelope = try? decoder.decode(APIResponse<T>.self, from: data)

        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 401 || http.statusCode == 403 {
                throw APIError.unauthorized(code: envelope?.code, message: envelope?.message)
            }
            throw APIError.server(status: http.statusCode, code: envelope?.code, message: envelope?.message)
        }

        guard let envelope else { throw APIError.emptyData }
        guard envelope.success, let payload = envelope.data else {
            throw APIError.server(status: http.statusCode, code: envelope.code, message: envelope.message)
        }
        return payload
    }
}

extension APIClient {
    /// 경로 세그먼트에 안전하게 끼워 넣기 위한 퍼센트 인코딩.
    static func encodePathSegment(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
    }
}
