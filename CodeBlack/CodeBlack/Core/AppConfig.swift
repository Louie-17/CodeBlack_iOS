//
//  AppConfig.swift
//  CodeBlack
//
//  앱 전역 설정. API base URL 및 개발용 자동 로그인 아이디.
//

import Foundation

enum AppConfig {

    /// API 서버 base URL.
    /// OpenAPI servers 항목은 http 로 표기돼 있으나 실제 서비스는 https 로 응답한다(ATS 대응).
    static let baseURL = URL(string: "https://codeblack-api.oijwef098234.com")!

    /// 개발용 자동 로그인.
    /// 앱 실행 시 로그인 화면 없이 이 아이디로 `POST /api/auth/login` 을 자동 호출한다.
    /// 서버는 비밀번호 없이 로그인 아이디만으로 사용자를 식별한다.
    ///
    /// ⚠️ 실제 테스트 계정 아이디를 채워야 자동 로그인이 성공한다. (비어 있으면 로그인 스킵)
    enum AutoLogin {
        static let loginId = ""   // 예: "paramedic1", "nurse1"

        static var isConfigured: Bool { !loginId.isEmpty }
    }

    /// 로그인 세션 정책. 한 번 로그인하면 이 기간 동안 재입력 없이 자동 로그인한다.
    enum Session {
        /// 세션 유효기간(초). 기본 30일.
        static let validity: TimeInterval = 60 * 60 * 24 * 30
    }

    /// 진행 중인 응급 요청 ID 저장 키(AppStorage/UserDefaults). 0 = 없음.
    static let activeRequestKey = "codeblack.activeEmergencyRequestId"

    /// 수락(ACCEPTED) 로컬 알림을 이미 발송한 요청 ID 저장 키. 재진입 시 중복 발송 방지. 0 = 없음.
    static let notifiedAcceptedRequestKey = "codeblack.notifiedAcceptedRequestId"
}
