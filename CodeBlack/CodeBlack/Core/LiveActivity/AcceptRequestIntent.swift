//
//  AcceptRequestIntent.swift
//  CodeBlack
//
//  Live Activity '수락하기' 버튼 App Intent(앱 타겟 복제본).
//  탭 즉시 Live Activity를 '수락됨'으로 갱신 → 수락 API 호출 → 잠시 후 종료.
//  ⚠️ 위젯 타겟의 CodeBlackWidget/AcceptRequestIntent.swift 와 동일하게 유지한다.
//

import AppIntents
import ActivityKit
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
        // 1) 버튼 탭 즉시 '수락되었습니다!' 피드백으로 상태 전환.
        await markAccepted()
        // 2) 앱 폴링이 이 요청을 다시 대기중으로 되살리지 않도록 표시.
        UserDefaults.standard.set(requestId, forKey: "codeblack.laAcceptedRequestId")
        // 3) 실제 수락 API 호출.
        await callAccept()
        // 4) 성공 메시지를 잠시 보여준 뒤 Live Activity 종료.
        try? await Task.sleep(nanoseconds: 2_500_000_000)
        await endActivity()
        return .result()
    }

    private func markAccepted() async {
        for activity in Activity<PatientRequestAttributes>.activities
        where activity.content.state.hospitalRequestId == requestId {
            var state = activity.content.state
            state.accepted = true
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    private func endActivity() async {
        for activity in Activity<PatientRequestAttributes>.activities
        where activity.content.state.hospitalRequestId == requestId {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func callAccept() async {
        guard requestId > 0, !loginId.isEmpty,
              let encoded = loginId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://codeblack-api.oijwef098234.com/api/hospital/requests/\(requestId)/accept?loginId=\(encoded)")
        else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        _ = try? await URLSession.shared.data(for: request)
    }
}
