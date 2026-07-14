//
//  ReverseGeocoder.swift
//  CodeBlack
//
//  좌표 → 한국어 지명 역지오코딩 유틸. (요청 위치 표시용)
//

import Foundation
import CoreLocation

enum ReverseGeocoder {

    /// 좌표를 사람이 읽을 수 있는 지명으로 변환한다. 실패 시 nil.
    static func placeName(latitude: Double, longitude: Double) async -> String? {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        guard
            let placemarks = try? await geocoder.reverseGeocodeLocation(
                location, preferredLocale: Locale(identifier: "ko_KR")
            ),
            let placemark = placemarks.first
        else {
            return nil
        }

        // 관심지점(건물/기관)명이 있으면 우선, 없으면 시군구·읍면동·도로로 조합.
        if let poi = placemark.areasOfInterest?.first, !poi.isEmpty {
            return poi
        }
        var parts: [String] = []
        for candidate in [placemark.locality, placemark.subLocality, placemark.thoroughfare] {
            if let value = candidate, !value.isEmpty, !parts.contains(value) {
                parts.append(value)
            }
        }
        let joined = parts.joined(separator: " ")
        return joined.isEmpty ? placemark.name : joined
    }
}
