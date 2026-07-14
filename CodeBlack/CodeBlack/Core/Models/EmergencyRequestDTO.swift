//
//  EmergencyRequestDTO.swift
//  CodeBlack
//
//  Emergency Requests / Hospital Requests 태그 DTO.
//  구급대원의 환자 수용 요청 생성/현황, 병원 담당자 관점 요청.
//

import Foundation

// MARK: - 생성 요청 (구급대원)

/// POST /api/emergency-requests 요청. 선택한 병원들에게 환자 수용 요청 전송.
struct CreateEmergencyRequest: Encodable {
    /// 요청 구급대원 로그인 아이디
    let paramedicLoginId: String
    /// 앱에서 STT로 변환된 환자 증상 텍스트 (maxLength 1000)
    let symptomText: String
    /// 중증도 메모
    let severity: String?
    /// 환자 나이 (0...150)
    let patientAge: Int?
    /// 환자 성별
    let patientSex: String?
    /// 발생 위치 위도 (-90...90)
    let latitude: Double?
    /// 발생 위치 경도 (-180...180)
    let longitude: Double?
    /// 실시간 가용병상 조회용 시도(STAGE1)
    let sido: String?
    /// 실시간 가용병상 조회용 시군구(STAGE2)
    let sigungu: String?
    /// 요청을 보낼 대상 병원 목록 (최소 1개)
    let targetHospitals: [TargetHospitalRequest]

    init(
        paramedicLoginId: String,
        symptomText: String,
        targetHospitals: [TargetHospitalRequest],
        severity: String? = nil,
        patientAge: Int? = nil,
        patientSex: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        sido: String? = nil,
        sigungu: String? = nil
    ) {
        self.paramedicLoginId = paramedicLoginId
        self.symptomText = symptomText
        self.targetHospitals = targetHospitals
        self.severity = severity
        self.patientAge = patientAge
        self.patientSex = patientSex
        self.latitude = latitude
        self.longitude = longitude
        self.sido = sido
        self.sigungu = sigungu
    }
}

/// 요청 대상 병원.
struct TargetHospitalRequest: Encodable {
    /// 공공데이터 병원 HPID
    let hospitalId: String
    /// 선택 화면 표시용 병원명
    let hospitalName: String?

    init(hospitalId: String, hospitalName: String? = nil) {
        self.hospitalId = hospitalId
        self.hospitalName = hospitalName
    }
}

// MARK: - 환자 요청 상세/현황 (구급대원 관점)

/// GET /api/emergency-requests/{requestId} 응답. 요청 + 대상 병원별 상태.
struct EmergencyRequestResponse: Decodable {
    let requestId: Int64?
    let paramedicLoginId: String?
    let symptomText: String?
    let severity: String?
    let patientAge: Int?
    let patientSex: String?
    let latitude: Double?
    let longitude: Double?
    /// 전체 요청 상태
    let status: EmergencyRequestStatus?
    /// 수락한 병원 HPID
    let acceptedHospitalId: String?
    /// 수락한 병원명
    let acceptedHospitalName: String?
    /// 요청 생성 시각 (ISO8601)
    let createdAt: String?
    /// 미응답 마감 시각 (ISO8601)
    let respondDeadline: String?
    /// 음성 녹음 첨부 여부
    let hasVoice: Bool?
    /// 대상 병원별 상태 목록
    let hospitals: [HospitalRequestSummary]?
}

/// GET /api/emergency-requests/{requestId}/status 응답. 폴링용 축약 현황.
struct EmergencyRequestStatusResponse: Decodable {
    let requestId: Int64?
    let status: EmergencyRequestStatus?
    let acceptedHospitalId: String?
    let acceptedHospitalName: String?
    let hospitals: [HospitalRequestSummary]?
}

/// 요청 대상 병원별 상태 요약.
struct HospitalRequestSummary: Decodable, Identifiable {
    let hospitalRequestId: Int64?
    let hospitalId: String?
    let hospitalName: String?
    let status: HospitalRequestStatus?
    /// 요청 생성 시점 응급실 가용병상 스냅샷
    let availableBeds: Int?
    /// 상태 확정 시각(수락/취소/미응답, ISO8601)
    let resolvedAt: String?

    var id: Int64 { hospitalRequestId ?? -1 }
}

/// GET /api/emergency-requests/{requestId}/call-candidates 응답 항목.
/// 자동 수용에 실패(미응답)했을 때 구급대원이 직접 연락할 후보 병원.
struct CallCandidateResponse: Decodable, Identifiable {
    let hospitalId: String?
    let hospitalName: String?
    /// 대표 전화번호(있을 때만 전화 버튼 표시).
    let phoneNumber: String?
    let availableBeds: Int?
    let status: HospitalRequestStatus?

    var id: String { hospitalId ?? UUID().uuidString }
}

/// POST /api/emergency-requests/{requestId}/ai-call 응답. AI 순차 발신 시작 현황.
struct AiCallStartResponse: Decodable {
    let sessionId: Int64?
    /// 세션 상태(CALLING / COMPLETED / EXHAUSTED).
    let status: String?
    /// 발신 대상(순위) 병원 수.
    let targetCount: Int?
    /// 현재(1순위) 발신 병원 HPID/병원명.
    let currentHospitalId: String?
    let currentHospitalName: String?
    /// 실제로 발신한 번호(테스트 모드면 테스트 번호).
    let dialedNumber: String?
}

/// GET /api/ai-calls/{sessionId} 응답. AI 발신 세션 실시간 상태(전화 걸림/받음 조회).
struct AiCallStatusResponse: Decodable {
    let sessionId: Int64?
    /// CALLING=발신/통화중, COMPLETED=병원이 받음, EXHAUSTED=모든 순위 미응답.
    let status: String?
    /// 마지막 통화 상태(ringing/answered/completed/no-answer/busy 등).
    let lastCallStatus: String?
    /// 전화 연결(수신) 성공 여부. true면 병원이 받음.
    let connected: Bool?
    let currentHospitalId: String?
    let currentHospitalName: String?
    /// 발신 대상(순위) 병원 수.
    let targetCount: Int?
    /// 현재 순위 인덱스(0부터).
    let currentIndex: Int?
}

// MARK: - 병원 담당자 관점 요청

/// GET /api/hospital/requests, /{requestId}, POST /{requestId}/accept 응답.
struct HospitalRequestResponse: Decodable, Identifiable {
    let hospitalRequestId: Int64?
    let emergencyRequestId: Int64?
    /// 병원별 요청 상태
    let status: HospitalRequestStatus?
    let symptomText: String?
    let severity: String?
    let patientAge: Int?
    let patientSex: String?
    let latitude: Double?
    let longitude: Double?
    /// 요청 생성 시점 응급실 가용병상 스냅샷
    let availableBeds: Int?
    /// 요청 생성 시각 (ISO8601)
    let createdAt: String?
    /// 상태 확정 시각 (ISO8601)
    let resolvedAt: String?
    /// 음성 녹음 첨부 여부
    let hasVoice: Bool?

    var id: Int64 { hospitalRequestId ?? -1 }
}
