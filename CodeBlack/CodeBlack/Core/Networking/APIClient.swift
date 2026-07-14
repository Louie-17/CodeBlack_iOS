//
//  APIClient.swift
//  CodeBlack
//
//  async/await + URLSession 기반 API 클라이언트.
//  서버 공통 봉투(APIResponse)를 해석해 성공 시 data 페이로드만 반환한다.
//  인증은 토큰이 아니라 loginId 기반(X-Login-Id 헤더 / loginId 쿼리)이다.
//  JSON(send)과 multipart/form-data(sendMultipart) 요청을 지원한다.
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

    /// multipart 파일 파트.
    struct FilePart {
        let name: String
        let filename: String
        let mimeType: String
        let data: Data
    }

    /// JSON 본문 요청. 성공 시 `APIResponse<T>` 의 data 를 반환한다.
    func send<T: Decodable>(
        _ method: HTTPMethod,
        _ path: String,
        query: [String: String?] = [:],
        headers: [String: String] = [:],
        body: (any Encodable)? = nil
    ) async throws -> T {
        var request = try makeRequest(method, path, query: query, headers: headers)
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                throw APIError.decoding(error)
            }
        }
        return try await perform(request)
    }

    /// multipart/form-data 요청. `jsonPart` 는 application/json 파트, `files` 는 바이너리 파트.
    func sendMultipart<T: Decodable>(
        _ method: HTTPMethod,
        _ path: String,
        jsonPartName: String,
        jsonPart: any Encodable,
        files: [FilePart] = [],
        query: [String: String?] = [:],
        headers: [String: String] = [:]
    ) async throws -> T {
        var request = try makeRequest(method, path, query: query, headers: headers)
        let boundary = "CodeBlackBoundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let jsonData: Data
        do {
            jsonData = try encoder.encode(jsonPart)
        } catch {
            throw APIError.decoding(error)
        }
        request.httpBody = makeMultipartBody(
            boundary: boundary, jsonName: jsonPartName, jsonData: jsonData, files: files
        )
        return try await perform(request)
    }

    // MARK: - 내부

    private func makeRequest(
        _ method: HTTPMethod,
        _ path: String,
        query: [String: String?],
        headers: [String: String]
    ) throws -> URLRequest {
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
        return request
    }

    private func makeMultipartBody(boundary: String, jsonName: String, jsonData: Data, files: [FilePart]) -> Data {
        var body = Data()
        func appendString(_ string: String) {
            body.append(Data(string.utf8))
        }

        appendString("--\(boundary)\r\n")
        appendString("Content-Disposition: form-data; name=\"\(jsonName)\"\r\n")
        appendString("Content-Type: application/json\r\n\r\n")
        body.append(jsonData)
        appendString("\r\n")

        for file in files {
            appendString("--\(boundary)\r\n")
            appendString("Content-Disposition: form-data; name=\"\(file.name)\"; filename=\"\(file.filename)\"\r\n")
            appendString("Content-Type: \(file.mimeType)\r\n\r\n")
            body.append(file.data)
            appendString("\r\n")
        }

        appendString("--\(boundary)--\r\n")
        return body
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        APILog.request(request)
        let startedAt = Date()

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            APILog.failure(error, for: request, duration: Date().timeIntervalSince(startedAt))
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        APILog.response(http, data: data, for: request, duration: Date().timeIntervalSince(startedAt))

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
