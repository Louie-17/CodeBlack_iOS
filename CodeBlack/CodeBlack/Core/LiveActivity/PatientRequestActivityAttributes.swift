//
//  PatientRequestActivityAttributes.swift
//  CodeBlack
//
//  간호사(병원) Live Activity 속성. 앱 타겟과 위젯 익스텐션 타겟이 공유한다.
//  ⚠️ 위젯 익스텐션 생성 후, 이 파일을 위젯 타겟 멤버십에도 추가해야 한다.
//

import Foundation
import ActivityKit

/// 병원 담당자에게 들어온 환자 수용 요청 Live Activity.
struct PatientRequestAttributes: ActivityAttributes {

    /// 실시간으로 갱신되는 상태.
    public struct ContentState: Codable, Hashable {
        /// 최신 요청 환자 상태 요약.
        var symptomText: String
        /// 중증도(없으면 빈 문자열).
        var severity: String
        /// 대기 중(PENDING) 요청 수.
        var pendingCount: Int
    }

    /// 고정 값 — 소속 병원명.
    var hospitalName: String
}
