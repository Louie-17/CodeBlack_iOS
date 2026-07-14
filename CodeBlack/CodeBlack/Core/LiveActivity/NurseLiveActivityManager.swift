//
//  NurseLiveActivityManager.swift
//  CodeBlack
//
//  간호사 화면에서 수신된 요청을 Live Activity로 표시/갱신/종료한다.
//  위젯 익스텐션 타겟이 있어야 실제로 잠금화면/다이나믹 아일랜드에 렌더링된다.
//

import Foundation
import CoreLocation
import ActivityKit

@MainActor
final class NurseLiveActivityManager {

    static let shared = NurseLiveActivityManager()
    private init() {}

    private var activity: Activity<PatientRequestAttributes>?

    /// 요청 목록에 맞춰 Live Activity를 시작/갱신/종료한다.
    /// PENDING 요청이 있으면 최신 요청으로 표시, 없으면 종료.
    func sync(
        hospitalName: String,
        hospitalCoordinate: CLLocationCoordinate2D?,
        requests: [HospitalRequestResponse],
        loginId: String
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // LA '수락하기'로 방금 수락한 요청은 목록에 반영되기 전까지 제외(재표시/깜빡임 방지).
        let acceptedKey = "codeblack.laAcceptedRequestId"
        let acceptedId = UserDefaults.standard.integer(forKey: acceptedKey)
        var pending = requests.filter { $0.status == .pending }
        if acceptedId != 0 {
            pending.removeAll { Int($0.hospitalRequestId ?? 0) == acceptedId }
            // 더 이상 대기중이 아니면 플래그 정리.
            if !requests.contains(where: { Int($0.hospitalRequestId ?? 0) == acceptedId && $0.status == .pending }) {
                UserDefaults.standard.removeObject(forKey: acceptedKey)
            }
        }
        guard let latest = pending.max(by: { ($0.createdAt ?? "") < ($1.createdAt ?? "") }) else {
            end()
            return
        }

        let state = PatientRequestAttributes.ContentState(
            symptomText: latest.symptomText ?? "새 환자 수용 요청",
            severity: latest.severity ?? "",
            patientInfo: Self.patientInfo(age: latest.patientAge, sex: latest.patientSex),
            distanceText: Self.distanceText(from: hospitalCoordinate, latitude: latest.latitude, longitude: latest.longitude),
            elapsedText: HospitalFormat.relativeTime(iso: latest.createdAt),
            pendingCount: pending.count,
            hospitalRequestId: Int(latest.hospitalRequestId ?? 0)
        )

        if let activity, activity.activityState == .active {
            Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
        } else {
            // 없거나 (인텐트로) 외부 종료됨 → 새로 시작.
            self.activity = nil
            do {
                activity = try Activity.request(
                    attributes: PatientRequestAttributes(hospitalName: hospitalName, loginId: loginId),
                    content: ActivityContent(state: state, staleDate: nil),
                    pushType: nil
                )
            } catch {
                // 위젯 익스텐션 미설정 또는 권한 거부 시 조용히 무시.
            }
        }
    }

    // MARK: - 표시 문자열

    private static func patientInfo(age: Int?, sex: String?) -> String {
        var parts: [String] = []
        if let age { parts.append("\(age)세") }
        switch sex?.uppercased() {
        case "M": parts.append("남성")
        case "F": parts.append("여성")
        default: break
        }
        return parts.joined(separator: " ")
    }

    private static func distanceText(from hospital: CLLocationCoordinate2D?, latitude: Double?, longitude: Double?) -> String {
        guard let km = HospitalRequestListViewModel.distanceKilometers(
            from: hospital, toLatitude: latitude, longitude: longitude
        ) else { return "" }
        return "\(HospitalFormat.distance(km)) · \(HospitalFormat.eta(km))"
    }

    /// Live Activity 종료.
    func end() {
        guard let activity else { return }
        let ended = activity
        self.activity = nil
        Task { await ended.end(nil, dismissalPolicy: .immediate) }
    }
}
