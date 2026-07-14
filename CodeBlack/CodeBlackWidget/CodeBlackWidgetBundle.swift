//
//  CodeBlackWidgetBundle.swift
//  CodeBlackWidget
//
//  위젯 익스텐션 진입점. Live Activity 위젯을 등록한다.
//  ⚠️ 이 파일들은 앱 타겟이 아니라 별도 "Widget Extension" 타겟에 추가되어야 한다.
//

import WidgetKit
import SwiftUI

@main
struct CodeBlackWidgetBundle: WidgetBundle {
    var body: some Widget {
        PatientRequestLiveActivity()
    }
}
