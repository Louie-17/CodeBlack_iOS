//
//  APILogger.swift
//  CodeBlack
//
//  API 요청/응답 콘솔 로깅. DEBUG 빌드에서만 출력된다.
//  Xcode 콘솔에서 "[API]" 로 필터링하면 요청/응답 흐름을 볼 수 있다.
//

import Foundation

enum APILog {

    /// DEBUG 빌드에서만 로깅 활성화.
    static var isEnabled: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    /// 요청 로그.
    static func request(_ request: URLRequest) {
        guard isEnabled else { return }
        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "(nil url)"

        var lines: [String] = []
        lines.append("┏━━━ [API →] \(method) \(url)")
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            lines.append("┃ headers: \(redacted(headers))")
        }
        if let body = request.httpBody, !body.isEmpty {
            lines.append("┃ body: \(prettyJSON(body, indent: "┃ "))")
        }
        lines.append("┗━━━")
        print(lines.joined(separator: "\n"))
    }

    /// 응답 로그(성공/실패 상태 모두).
    static func response(_ response: HTTPURLResponse, data: Data, for request: URLRequest, duration: TimeInterval) {
        guard isEnabled else { return }
        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "(nil url)"
        let ms = Int((duration * 1000).rounded())
        let mark = (200..<300).contains(response.statusCode) ? "✓" : "✗"

        var lines: [String] = []
        lines.append("┏━━━ [API ←] \(mark) \(response.statusCode) (\(ms)ms) \(method) \(url)")
        if data.isEmpty {
            lines.append("┃ body: (empty)")
        } else {
            lines.append("┃ body: \(prettyJSON(data, indent: "┃ "))")
        }
        lines.append("┗━━━")
        print(lines.joined(separator: "\n"))
    }

    /// 전송 실패(네트워크 오류) 로그.
    static func failure(_ error: Error, for request: URLRequest, duration: TimeInterval) {
        guard isEnabled else { return }
        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "(nil url)"
        let ms = Int((duration * 1000).rounded())
        print("┏━━━ [API ✗] TRANSPORT FAIL (\(ms)ms) \(method) \(url)\n┃ error: \(error.localizedDescription)\n┗━━━")
    }

    // MARK: - 유틸

    /// 민감 헤더 값 마스킹.
    private static func redacted(_ headers: [String: String]) -> [String: String] {
        var copy = headers
        for key in copy.keys where key.lowercased() == "authorization" {
            copy[key] = "***"
        }
        return copy
    }

    /// JSON 데이터를 보기 좋게 정렬/들여쓰기. 실패 시 원문 문자열.
    private static func prettyJSON(_ data: Data, indent: String) -> String {
        guard
            let object = try? JSONSerialization.jsonObject(with: data),
            let pretty = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
            ),
            let string = String(data: pretty, encoding: .utf8)
        else {
            return String(data: data, encoding: .utf8) ?? "(\(data.count) bytes)"
        }
        // 각 줄 앞에 로그 프레임 들여쓰기를 붙인다(첫 줄 제외).
        return string.replacingOccurrences(of: "\n", with: "\n\(indent)")
    }
}
