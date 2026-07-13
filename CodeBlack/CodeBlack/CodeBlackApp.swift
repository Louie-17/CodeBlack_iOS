//
//  CodeBlackApp.swift
//  CodeBlack
//
//  Created by 장태균 on 7/13/26.
//

import SwiftUI

@main
struct CodeBlackApp: App {
    @State private var auth = AuthViewModel()

    init() {
        AppFont.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(auth)
                .task {
                    await auth.bootstrap()
                }
        }
    }
}
