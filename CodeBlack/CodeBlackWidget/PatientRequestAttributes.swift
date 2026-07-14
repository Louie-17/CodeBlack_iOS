//
//  PatientRequestAttributes.swift
//  CodeBlackWidget
//
//  Live Activity 공유 속성(위젯 타겟 복제본). 앱의
//  CodeBlack/Core/LiveActivity/PatientRequestActivityAttributes.swift 와 반드시 동일하게 유지한다.
//  (ActivityKit은 타입 이름으로 매칭하므로 앱/위젯 각 모듈의 동일 정의가 서로 매칭된다.)
//  ⚠️ 앱의 속성 파일을 이 위젯 타겟에 '중복' 추가하지 말 것(같은 이름 중복 정의 오류).
//

import Foundation
import ActivityKit

struct PatientRequestAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var symptomText: String
        var severity: String
        var patientInfo: String
        var distanceText: String
        var elapsedText: String
        var pendingCount: Int
        /// 최신 PENDING 요청의 병원요청 ID(수락 버튼용).
        var hospitalRequestId: Int
    }

    var hospitalName: String
    /// 담당 간호사 로그인 ID(수락 API 호출용).
    var loginId: String
}
