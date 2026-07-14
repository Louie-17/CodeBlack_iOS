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

    var body: some View {
        Map(initialPosition: .region(region)) {
            if let patient {
                Marker("환자", systemImage: "cross.case.fill", coordinate: patient)
                    .tint(AppColor.emergencyRed)
            }
            if let hospital {
                Marker("병원", systemImage: "building.2.fill", coordinate: hospital)
                    .tint(AppColor.brandGreen)
            }
            if let patient, let hospital {
                MapPolyline(coordinates: [patient, hospital])
                    .stroke(AppColor.brandGreen, lineWidth: 4)
            }
        }
        .allowsHitTesting(interactive)
    }

    private var region: MKCoordinateRegion {
        let points = [patient, hospital].compactMap { $0 }
        guard let first = points.first else {
            return MKCoordinateRegion(
                center: LocationProvider.fallback,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        guard points.count == 2 else {
            return MKCoordinateRegion(
                center: first,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        }
        let lats = points.map(\.latitude)
        let lngs = points.map(\.longitude)
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lngs.min()! + lngs.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.01, (lats.max()! - lats.min()!) * 1.6),
            longitudeDelta: max(0.01, (lngs.max()! - lngs.min()!) * 1.6)
        )
        return MKCoordinateRegion(center: center, span: span)
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
