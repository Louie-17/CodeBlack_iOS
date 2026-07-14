//
//  RouteMapView.swift
//  CodeBlack
//
//  환자↔병원 경로 지도. 인라인 프리뷰(정적) / 전체화면(확대·축소·이동) 공용.
//

import SwiftUI
import MapKit
import CoreLocation

struct RouteMapView: View {
    let patient: CLLocationCoordinate2D?
    let hospital: CLLocationCoordinate2D?
    /// true면 확대/축소/이동 가능, false면 정적 프리뷰.
    var interactive: Bool = true

    /// MKDirections로 계산한 실제 도로 경로(로딩 전/실패 시 nil).
    @State private var route: MKRoute?
    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $position) {
            if let patient {
                Marker("환자", systemImage: "cross.case.fill", coordinate: patient)
                    .tint(AppColor.emergencyRed)
            }
            if let hospital {
                Marker("병원", systemImage: "building.2.fill", coordinate: hospital)
                    .tint(AppColor.brandGreen)
            }
            if let route {
                // 실제 도로 경로.
                MapPolyline(route.polyline)
                    .stroke(AppColor.brandGreen, lineWidth: 5)
            } else if let patient, let hospital {
                // 경로 로딩 전/실패 시 임시 직선.
                MapPolyline(coordinates: [patient, hospital])
                    .stroke(AppColor.brandGreen.opacity(0.4), style: StrokeStyle(lineWidth: 3, dash: [6, 6]))
            }
        }
        .allowsHitTesting(interactive)
        .task(id: routeKey) { await loadRoute() }
    }

    /// 좌표 조합 키. 병원/환자 좌표가 채워지면 값이 바뀌어 경로를 재계산한다.
    private var routeKey: String {
        guard let patient, let hospital else { return "none" }
        return "\(patient.latitude),\(patient.longitude)|\(hospital.latitude),\(hospital.longitude)"
    }

    /// 환자→병원 자동차 경로를 계산한다. 실패 시 직선 폴백 유지.
    private func loadRoute() async {
        guard let patient, let hospital else { route = nil; return }
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: patient))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: hospital))
        request.transportType = .automobile
        route = try? await MKDirections(request: request).calculate().routes.first
    }
}

/// 전체화면 인터랙티브 경로 지도(확대/축소/이동 + 닫기).
struct FullRouteMapView: View {
    let patient: CLLocationCoordinate2D?
    let hospital: CLLocationCoordinate2D?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            RouteMapView(patient: patient, hospital: hospital, interactive: true)
                .ignoresSafeArea()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(AppColor.bgWhite))
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
            }
            .buttonStyle(.plain)
            .padding(20)
        }
    }
}
