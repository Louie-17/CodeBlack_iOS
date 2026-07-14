//
//  PatientRequestLiveActivity.swift
//  CodeBlackWidget
//
//  간호사 수신 요청 Live Activity — 잠금화면/다이나믹 아일랜드.
//  ⚠️ 공유 타입 PatientRequestAttributes는 위젯 타겟의 복제본(PatientRequestAttributes.swift)을 사용한다.
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
                .activityBackgroundTint(Color.black.opacity(0.82))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        appLogo(28)
                        Text("\(context.state.pendingCount)건")
                            .font(.caption).bold()
                            .foregroundStyle(brandGreen)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.hospitalName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text("새 환자 수용 요청").font(.headline)
                            if !context.state.severity.isEmpty {
                                severityBadge(context.state.severity)
                            }
                            Spacer(minLength: 0)
                        }
                        infoRow(context)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                appLogo(20)
            } compactTrailing: {
                Text("\(context.state.pendingCount)")
                    .font(.caption).bold()
                    .foregroundStyle(brandGreen)
            } minimal: {
                appLogo(20)
            }
        }
    }
}

private struct LockScreenView: View {
    let context: ActivityViewContext<PatientRequestAttributes>

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            appLogo(64)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("새 환자 수용 요청")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    if !context.state.severity.isEmpty {
                        severityBadge(context.state.severity)
                    }
                    Spacer(minLength: 0)
                    Text("대기 \(context.state.pendingCount)건")
                        .font(.subheadline).bold()
                        .foregroundStyle(brandGreen)
                }

                infoRow(context)

                Spacer(minLength: 4)

                HStack(spacing: 6) {
                    Image(systemName: "building.2.fill").font(.system(size: 12))
                    Text(context.attributes.hospitalName).lineLimit(1)
                    Spacer(minLength: 0)
                    Text(context.state.elapsedText)
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .top)
    }
}

// MARK: - 공용 서브뷰

private func appLogo(_ size: CGFloat) -> some View {
    Image("AppLogo")
        .resizable()
        .scaledToFill()
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
}

@ViewBuilder
private func infoRow(_ context: ActivityViewContext<PatientRequestAttributes>) -> some View {
    HStack(spacing: 12) {
        if !context.state.patientInfo.isEmpty {
            Label(context.state.patientInfo, systemImage: "person.fill")
        }
        if !context.state.distanceText.isEmpty {
            Label(context.state.distanceText, systemImage: "location.fill")
        }
        Spacer(minLength: 0)
    }
    .font(.caption)
    .foregroundStyle(brandGreen)
    .lineLimit(1)
}

@ViewBuilder
private func severityBadge(_ text: String) -> some View {
    Text(text)
        .font(.caption2.bold())
        .foregroundStyle(emergencyRed)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Capsule().fill(emergencyRed.opacity(0.18)))
}
