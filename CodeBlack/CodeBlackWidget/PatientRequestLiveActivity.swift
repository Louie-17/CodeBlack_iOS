//
//  PatientRequestLiveActivity.swift
//  CodeBlackWidget
//
//  간호사 수신 요청 Live Activity — 잠금화면/다이나믹 아일랜드.
//  ⚠️ 공유 타입 PatientRequestAttributes(앱의 PatientRequestActivityAttributes.swift)를
//     이 위젯 타겟 멤버십에도 추가해야 한다.
//

import SwiftUI
import WidgetKit
import ActivityKit

// 앱 AppColor는 위젯 타겟에 없으므로 브랜드 색을 로컬 정의.
private let brandGreen = Color(red: 0.525, green: 0.773, blue: 0.353)   // #86C55A
private let emergencyRed = Color(red: 1.0, green: 0.192, blue: 0.192)   // #FF3131

struct PatientRequestLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PatientRequestAttributes.self) { context in
            LockScreenView(context: context)
                .padding(16)
                .activityBackgroundTint(Color.black.opacity(0.75))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("\(context.state.pendingCount)건", systemImage: "cross.case.fill")
                        .font(.caption)
                        .foregroundStyle(brandGreen)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.hospitalName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("새 환자 수용 요청")
                                .font(.headline)
                            if !context.state.severity.isEmpty {
                                severityBadge(context.state.severity)
                            }
                        }
                        Text(context.state.symptomText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Image(systemName: "cross.case.fill")
                    .foregroundStyle(brandGreen)
            } compactTrailing: {
                Text("\(context.state.pendingCount)")
                    .foregroundStyle(brandGreen)
            } minimal: {
                Image(systemName: "cross.case.fill")
                    .foregroundStyle(brandGreen)
            }
        }
    }
}

private struct LockScreenView: View {
    let context: ActivityViewContext<PatientRequestAttributes>

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "cross.case.fill")
                .font(.system(size: 26))
                .foregroundStyle(brandGreen)
                .frame(width: 44, height: 44)
                .background(Circle().fill(brandGreen.opacity(0.18)))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("새 환자 수용 요청")
                        .font(.headline)
                        .foregroundStyle(.white)
                    if !context.state.severity.isEmpty {
                        severityBadge(context.state.severity)
                    }
                    Spacer(minLength: 0)
                    Text("대기 \(context.state.pendingCount)건")
                        .font(.caption)
                        .foregroundStyle(brandGreen)
                }
                Text(context.state.symptomText)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
                Text(context.attributes.hospitalName)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
}

@ViewBuilder
private func severityBadge(_ text: String) -> some View {
    Text(text)
        .font(.caption2.bold())
        .foregroundStyle(emergencyRed)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Capsule().fill(emergencyRed.opacity(0.15)))
}
