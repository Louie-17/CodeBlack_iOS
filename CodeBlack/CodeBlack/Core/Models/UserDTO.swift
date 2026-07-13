//
//  UserDTO.swift
//  CodeBlack
//
//  Users 태그 DTO. 사용자 생성/로그인/조회.
//  비밀번호 없이 유니크 로그인 아이디로 식별한다.
//

import Foundation

/// POST /api/signup 요청. 간호사는 병원 HPID/병원명을 함께 전달한다(구급대원은 nil).
struct CreateUserRequest: Encodable {
    /// 유니크 로그인 아이디 (maxLength 50)
    let loginId: String
    /// 사용자 역할
    let role: ActorRole
    /// 간호사 소속 병원 HPID. 구급대원은 nil.
    let hospitalId: String?
    /// 선택 화면 표시용 병원명. 서버가 HPID로 공식 병원명을 저장.
    let hospitalName: String?

    init(loginId: String, role: ActorRole, hospitalId: String? = nil, hospitalName: String? = nil) {
        self.loginId = loginId
        self.role = role
        self.hospitalId = hospitalId
        self.hospitalName = hospitalName
    }
}

/// POST /api/auth/login 요청. 로그인 아이디만으로 조회.
struct LoginRequest: Encodable {
    let loginId: String
}

/// 사용자 응답(ActorResponse). login/signup/me/paramedic/nurse/actors 공통 페이로드.
struct ActorResponse: Decodable, Identifiable {
    /// 로그인 아이디
    let loginId: String?
    /// 사용자 역할
    let role: ActorRole?
    /// 간호사 소속 병원 HPID. 구급대원은 nil.
    let hospitalId: String?
    /// 간호사 소속 병원명. 구급대원은 nil.
    let hospitalName: String?

    var id: String { loginId ?? UUID().uuidString }
}
