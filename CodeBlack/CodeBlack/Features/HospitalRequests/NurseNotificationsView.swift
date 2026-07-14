//
//  NurseNotificationsView.swift
//  CodeBlack
//
//  병원 담당자 알림 목록(시트). 읽음 처리 + 해당 요청 상세로 이동.
//

import SwiftUI

struct NurseNotificationsView: View {
    let viewModel: NotificationsViewModel
    let loginId: String
    /// 알림 → 해당 병원요청(hospitalRequestId) 상세 열기.
    let onOpenRequest: (Int64) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .background(AppColor.bgGray)
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack {
            Text("알림")
                .font(.heading4)
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
            if viewModel.unreadCount > 0 {
                Button("모두 읽음") {
                    Task { await viewModel.markAllRead(loginId: loginId) }
                }
                .font(.heading8)
                .foregroundStyle(AppColor.brandGreenDark)
            }
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 16)
        .background(AppColor.bgWhite)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.notifications.isEmpty {
            VStack(spacing: 8) {
                Spacer()
                Image(systemName: "bell.slash")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColor.textSecondary)
                Text("알림이 없습니다")
                    .font(.heading7)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.notifications) { notification in
                        Button {
                            tap(notification)
                        } label: {
                            NotificationCard(notification: notification)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }

    private func tap(_ notification: NotificationResponse) {
        if let id = notification.notificationId {
            Task { await viewModel.markRead(notificationId: id, loginId: loginId) }
        }
        if let requestId = notification.hospitalRequestId {
            onOpenRequest(requestId)
        } else {
            dismiss()
        }
    }
}

// MARK: - 알림 카드

private struct NotificationCard: View {
    let notification: NotificationResponse

    private var isUnread: Bool { notification.read != true }

    private var icon: String {
        switch notification.type {
        case .requestReceived: return "cross.case.fill"
        case .requestCanceled: return "xmark.circle.fill"
        default: return "bell.fill"
        }
    }

    private var iconColor: Color {
        notification.type == .requestCanceled ? AppColor.textSecondary : AppColor.brandGreen
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background(Circle().fill(iconColor.opacity(0.15)))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(notification.title ?? "알림")
                        .font(.heading7)
                        .foregroundStyle(AppColor.textPrimary)
                    if isUnread {
                        Circle().fill(AppColor.emergencyRed).frame(width: 7, height: 7)
                    }
                    Spacer(minLength: 4)
                    Text(HospitalFormat.relativeTime(iso: notification.createdAt))
                        .font(.caption6)
                        .foregroundStyle(AppColor.textSecondary)
                }
                Text(notification.message ?? "")
                    .font(.caption4)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isUnread ? AppColor.greenBg : AppColor.bgWhite)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppColor.border, lineWidth: 1)
        )
    }
}
