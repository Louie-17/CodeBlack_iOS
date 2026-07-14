//
//  AcceptRequestIntent.swift
//  CodeBlack
//
//  Live Activity '수락하기' 버튼 App Intent(앱 타겟 복제본).
//  탭 시 앱을 백그라운드로 깨워 요청 수락 API를 호출한다.
//  ⚠️ 위젯 타겟의 CodeBlackWidget/AcceptRequestIntent.swift 와 동일하게 유지한다.
//

import AppIntents
import Foundation

struct AcceptRequestIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "환자 수용 요청 수락"

    @Parameter(title: "요청 ID") var requestId: Int
    @Parameter(title: "로그인 ID") var loginId: String

    init() {}
    init(requestId: Int, loginId: String) {
        self.requestId = requestId
        self.loginId = loginId
    }

    func perform() async throws -> some IntentResult {
        guard requestId > 0, !loginId.isEmpty,
              let encoded = loginId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://codeblack-api.oijwef098234.com/api/hospital/requests/\(requestId)/accept?loginId=\(encoded)")
        else { return .result() }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        _ = try? await URLSession.shared.data(for: request)
        return .result()
    }
}
