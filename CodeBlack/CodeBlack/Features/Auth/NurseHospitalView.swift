//
//  NurseHospitalView.swift
//  CodeBlack
//
//  간호사 회원가입 마지막 단계 — 근무 병원 선택 후 가입 완료.
//  병원 검색 → 선택 → 완료하기 시 POST /api/signup (hospitalId/병원명 포함).
//

import SwiftUI

struct NurseHospitalView: View {
    let loginId: String
    let phoneNumber: String
    let onBack: () -> Void

    @Environment(AuthViewModel.self) private var auth
    @State private var viewModel = NurseHospitalViewModel()
    @State private var keyword = ""
    @State private var selected: HospitalSearchResponse?
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BackChevronBar(onBack: onBack)

            Text("근무 병원 선택")
                .font(.heading3)
                .foregroundStyle(AppColor.textPrimary)
                .padding(.horizontal, 20)
                .padding(.top, 8)

            Text("소속(근무) 병원을 검색해 선택하세요.")
                .font(.body5)
                .foregroundStyle(AppColor.textSecondary)
                .padding(.horizontal, 20)
                .padding(.top, 8)

            searchField
            results

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption5)
                    .foregroundStyle(AppColor.emergencyRed)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }

            CTAButton(
                title: isSubmitting ? "가입 중…" : "완료하기",
                isEnabled: selected != nil && !isSubmitting,
                action: submit
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(AppColor.bgWhite)
    }

    // MARK: 검색 입력

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundStyle(AppColor.textSecondary)
            TextField("병원 이름 검색", text: $keyword)
                .font(.body5)
                .foregroundStyle(AppColor.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($focused)
                .onSubmit(runSearch)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(RoundedRectangle(cornerRadius: 12).fill(AppColor.bgGray2))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(focused ? AppColor.brandGreen : AppColor.border, lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    // MARK: 결과 목록

    @ViewBuilder
    private var results: some View {
        switch viewModel.loadState {
        case .idle:
            hint("병원 이름으로 검색하세요.")
        case .loading:
            Spacer()
            ProgressView()
                .tint(AppColor.brandGreen)
                .frame(maxWidth: .infinity)
            Spacer()
        case .failed(let message):
            hint(message)
        case .loaded:
            if viewModel.results.isEmpty {
                hint("검색 결과가 없습니다.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.results) { hospital in
                            hospitalRow(hospital)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
    }

    private func hospitalRow(_ hospital: HospitalSearchResponse) -> some View {
        let isSelected = selected?.hospitalId == hospital.hospitalId
        return Button {
            selected = hospital
            focused = false
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(hospital.name ?? "이름 미상")
                        .font(.heading7)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                    if let address = hospital.address {
                        Text(address)
                            .font(.caption6)
                            .foregroundStyle(AppColor.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColor.brandGreen)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? AppColor.greenBg : AppColor.bgWhite)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? AppColor.brandGreen : AppColor.border,
                                  lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func hint(_ text: String) -> some View {
        VStack {
            Spacer()
            Text(text)
                .font(.caption5)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: 액션

    private func runSearch() {
        Task { await viewModel.search(keyword: keyword) }
    }

    private func submit() {
        guard let hospital = selected, let hospitalId = hospital.hospitalId else { return }
        isSubmitting = true
        errorMessage = nil
        Task {
            do {
                try await auth.register(
                    loginId: loginId,
                    role: .nurse,
                    hospitalId: hospitalId,
                    hospitalName: hospital.name,
                    phoneNumber: phoneNumber
                )
                // 성공 시 auth.state = .authenticated → 루트가 앱 플로우로 전환.
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                isSubmitting = false
            }
        }
    }
}

#Preview {
    NurseHospitalView(loginId: "nurse1", phoneNumber: "010-1234-5678", onBack: {})
        .environment(AuthViewModel())
}
