//
//  LocationProvider.swift
//  CodeBlack
//
//  현재 위치 제공. 추천 병원 조회(위도/경도 필수)에 사용한다.
//  권한 거부/획득 실패 시 조용히 기본 좌표(fallback)로 동작한다.
//  좌표는 역지오코딩해 사람이 읽을 수 있는 지명(placeName)으로도 제공한다.
//

import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class LocationProvider {

    private(set) var coordinate: CLLocationCoordinate2D?
    private(set) var isResolving = false
    /// 역지오코딩된 현재 위치 지명(예: "서울특별시 종로구"). 미확정이면 nil.
    private(set) var placeName: String?
    /// 역지오코딩된 시도(예: "대전광역시"). 추천 조회 지역 파라미터.
    private(set) var city: String?
    /// 역지오코딩된 시군구(예: "유성구"). 추천 조회 지역 파라미터.
    private(set) var district: String?

    /// 위치를 얻지 못했을 때 사용할 기본 좌표(서울시청).
    static let fallback = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)

    private let geocoder = CLGeocoder()

    /// 추천 조회에 사용할 현재 좌표(없으면 fallback).
    var current: CLLocationCoordinate2D { coordinate ?? Self.fallback }

    /// 현재 위치를 한 번 획득하고 지명/지역까지 역지오코딩한다(지역이 추천 조회에 필요).
    func resolveOnce() async {
        guard coordinate == nil, !isResolving else { return }
        isResolving = true
        defer { isResolving = false }
        do {
            for try await update in CLLocationUpdate.liveUpdates() {
                if let location = update.location {
                    coordinate = location.coordinate
                    break
                }
                if update.locationUnavailable { break }
            }
        } catch {
            // 권한 거부 또는 위치 오류 → fallback 유지
        }
        await updatePlaceName()
    }

    /// 현재 좌표를 한국어 지명으로 역지오코딩한다.
    private func updatePlaceName() async {
        let coord = current
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        guard
            let placemarks = try? await geocoder.reverseGeocodeLocation(
                location, preferredLocale: Locale(identifier: "ko_KR")
            ),
            let placemark = placemarks.first
        else {
            return
        }

        // 시도(city) / 시군구(district) 추출.
        let city = placemark.administrativeArea
        var district = placemark.locality
        if district == nil || district == city {
            district = placemark.subLocality
        }
        self.city = city
        self.district = district

        // 지명 = 시도 · 시군구 · 읍면동 순으로 중복 없이 조합.
        var parts: [String] = []
        for candidate in [placemark.administrativeArea, placemark.locality, placemark.subLocality] {
            if let value = candidate, !value.isEmpty, !parts.contains(value) {
                parts.append(value)
            }
        }
        let joined = parts.joined(separator: " ")
        placeName = joined.isEmpty ? placemark.name : joined
    }
}
