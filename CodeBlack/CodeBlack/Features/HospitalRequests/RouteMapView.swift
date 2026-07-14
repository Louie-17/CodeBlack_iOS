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
    /// 경로를 계산 완료한 좌표 키(중복 계산/스로틀 방지).
    @State private var routedKey: String?
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
        .task(id: routeKey) {
            fitCamera()
            await loadRoute()
        }
    }

    /// 좌표 조합 키. 병원/환자 좌표가 채워지면 값이 바뀌어 경로/카메라를 재계산한다.
    private var routeKey: String {
        guard let patient, let hospital else { return "none" }
        return "\(patient.latitude),\(patient.longitude)|\(hospital.latitude),\(hospital.longitude)"
    }

    /// 환자·병원(·경로)이 모두 보이도록 카메라를 명시적으로 맞춘다.
    private func fitCamera() {
        if let route {
            let rect = route.polyline.boundingMapRect
            let padded = rect.insetBy(dx: -rect.size.width * 0.25, dy: -rect.size.height * 0.25)
            position = .rect(padded)
            return
        }
        let coords = [patient, hospital].compactMap { $0 }
        guard let first = coords.first else { return }
        guard coords.count == 2 else {
            position = .region(MKCoordinateRegion(
                center: first,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
            return
        }
        let lats = coords.map(\.latitude), lngs = coords.map(\.longitude)
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lngs.min()! + lngs.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.008, (lats.max()! - lats.min()!) * 1.5),
            longitudeDelta: max(0.008, (lngs.max()! - lngs.min()!) * 1.5)
        )
        position = .region(MKCoordinateRegion(center: center, span: span))
    }

    /// 환자→병원 자동차 경로를 계산한다. 스로틀/일시 오류 시 백오프 재시도. 실패 시 직선 폴백 유지.
    private func loadRoute() async {
        guard let patient, let hospital else { route = nil; return }
        let key = routeKey
        guard routedKey != key else { return }   // 이 좌표로 이미 계산함
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: patient))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: hospital))
        request.transportType = .automobile
        for attempt in 0..<4 {
            if Task.isCancelled { return }
            if let result = try? await MKDirections(request: request).calculate().routes.first {
                route = result
                routedKey = key
                fitCamera()
                return
            }
            // 스로틀(MKErrorLoadingThrottled) 등 → 점증 대기 후 재시도.
            try? await Task.sleep(nanoseconds: UInt64(attempt + 1) * 1_500_000_000)
        }
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
