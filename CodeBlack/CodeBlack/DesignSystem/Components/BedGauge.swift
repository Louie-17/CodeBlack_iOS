//
//  BedGauge.swift
//  CodeBlack
//
//  응급실 가용병상 진행 게이지. 혼잡도 색을 따른다.
//

import SwiftUI

struct BedGauge: View {
    /// 가용병상 수
    let availableBeds: Int?
    /// 게이지 정규화를 위한 기준 최대 병상 수(시안 기준 근사치).
    var capacity: Int = 10

    private var congestion: Congestion { Congestion(availableBeds: availableBeds) }

    private var ratio: CGFloat {
        guard capacity > 0, let beds = availableBeds else { return 0 }
        return min(1, max(0, CGFloat(beds) / CGFloat(capacity)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("가용병상")
                    .font(.caption6)
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                Text("\(availableBeds ?? 0)병상")
                    .font(.heading9)
                    .foregroundStyle(congestion.color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColor.bgGray2)
                    Capsule()
                        .fill(congestion.color)
                        .frame(width: geo.size.width * ratio)
                }
            }
            .frame(height: 6)
        }
    }
}
