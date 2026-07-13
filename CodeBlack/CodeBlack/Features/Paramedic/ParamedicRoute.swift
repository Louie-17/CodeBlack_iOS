//
//  ParamedicRoute.swift
//  CodeBlack
//
//  구급대원 플로우 네비게이션 라우트 및 화면 간 전달 값.
//

import Foundation

/// 선택한 대상 병원 요약값. 상세/음성입력/요청 화면으로 전달한다.
struct SelectedHospital: Hashable {
    let hospitalId: String
    let name: String
    let latitude: Double?
    let longitude: Double?
    /// 목록에서 계산된 현재 위치 기준 거리(km). 상세 화면 표시용.
    var distanceKilometers: Double? = nil
    /// 목록(추천)에서 표시된 가용병상 수. 상세 화면과 값이 일치하도록 전달한다.
    var availableBeds: Int? = nil

    /// 요청 생성 시 사용할 대상 병원 DTO로 변환.
    var target: TargetHospitalRequest {
        TargetHospitalRequest(hospitalId: hospitalId, hospitalName: name)
    }
}

/// 구급대원 플로우 라우트. (검색 → 상세 → 음성입력 → 요청상태)
enum ParamedicRoute: Hashable {
    case detail(SelectedHospital)
    case voiceInput(SelectedHospital)
    case requestStatus(requestId: Int64)
}
