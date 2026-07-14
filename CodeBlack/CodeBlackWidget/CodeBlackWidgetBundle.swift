//
//  CodeBlackWidgetBundle.swift
//  CodeBlackWidget
//
//  위젯 익스텐션 진입점. 간호사 수신 요청 Live Activity를 등록한다.
//

import WidgetKit
import SwiftUI

@main
struct CodeBlackWidgetBundle: WidgetBundle {
    var body: some Widget {
        PatientRequestLiveActivity()
    }
}
