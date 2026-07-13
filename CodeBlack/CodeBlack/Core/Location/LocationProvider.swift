//
//  LocationProvider.swift
//  CodeBlack
//
//  현재 위치 제공. 추천 병원 조회(위도/경도 필수)에 사용한다.
//  권한 거부/획득 실패 시 조용히 기본 좌표(fallback)로 동작한다.
//

import CoreLocation
import Observation

@MainActor
@Observable
final class LocationProvider {

    private(set) var coordinate: CLLocationCoordinate2D?
    private(set) var isResolving = false

    /// 위치를 얻지 못했을 때 사용할 기본 좌표(서울시청).
    static let fallback = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)

    /// 추천 조회에 사용할 현재 좌표(없으면 fallback).
    var current: CLLocationCoordinate2D { coordinate ?? Self.fallback }

    /// 현재 위치를 한 번 획득한다. 실패해도 예외를 던지지 않고 fallback을 유지한다.
    func resolveOnce() async {
        guard coordinate == nil, !isResolving else { return }
        isResolving = true
        defer { isResolving = false }
        do {
            for try await update in CLLocationUpdate.liveUpdates() {
                if let location = update.location {
                    coordinate = location.coordinate
                    return
                }
                if update.locationUnavailable { return }
            }
        } catch {
            // 권한 거부 또는 위치 오류 → fallback 유지
        }
    }
}
