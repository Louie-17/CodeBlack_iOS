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

        let pending = requests.filter { $0.status == .pending }
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

        if let activity {
            Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
        } else {
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
