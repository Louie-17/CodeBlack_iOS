//
//  NurseRoute.swift
//  CodeBlack
//
//  간호사(병원) 플로우 라우트 및 화면 전달 값.
//

import Foundation

/// 수신된 요청 항목(목록 → 상세 전달용).
struct NurseRequestItem: Hashable {
    let hospitalRequestId: Int64
    let emergencyRequestId: Int64
    let symptomText: String
    let severity: String?
    let patientAge: Int?
    let patientSex: String?
    let latitude: Double?
    let longitude: Double?
    let availableBeds: Int?
    let createdAt: String?
    let status: HospitalRequestStatus?
    let hasVoice: Bool

    init(from response: HospitalRequestResponse) {
        hospitalRequestId = response.hospitalRequestId ?? -1
        emergencyRequestId = response.emergencyRequestId ?? -1
        symptomText = response.symptomText ?? ""
        severity = response.severity
        patientAge = response.patientAge
        patientSex = response.patientSex
        latitude = response.latitude
        longitude = response.longitude
        availableBeds = response.availableBeds
        createdAt = response.createdAt
        status = response.status
        hasVoice = response.hasVoice ?? false
    }
}

/// 간호사 플로우 라우트.
enum NurseRoute: Hashable {
    case detail(NurseRequestItem)
}
