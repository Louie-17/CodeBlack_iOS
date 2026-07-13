//
//  ContentView.swift
//  CodeBlack
//
//  Created by 장태균 on 7/13/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthViewModel.self) private var auth

    var body: some View {
        VStack(spacing: 12) {
            switch auth.state {
            case .idle, .loading:
                ProgressView()
                Text("자동 로그인 중…")
                    .font(.body3)
                    .foregroundStyle(.secondary)

            case let .authenticated(name, role):
                Image(systemName: "checkmark.seal.fill")
                    .imageScale(.large)
                    .foregroundStyle(.green)
                Text("로그인 완료")
                    .font(.heading3)
                Text([name, role].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.body3)
                    .foregroundStyle(.secondary)

            case .needsCredentials:
                Image(systemName: "key.slash")
                    .imageScale(.large)
                    .foregroundStyle(.orange)
                Text("자동 로그인 자격증명 미설정")
                    .font(.heading5)
                Text("AppConfig.AutoLogin 의 loginId 를 입력하세요.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

            case let .failed(message):
                Image(systemName: "exclamationmark.triangle.fill")
                    .imageScale(.large)
                    .foregroundStyle(.red)
                Text("로그인 실패")
                    .font(.heading5)
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environment(AuthViewModel())
}
