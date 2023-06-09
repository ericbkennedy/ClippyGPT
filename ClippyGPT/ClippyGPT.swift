//
//  ClippyGPTApp.swift
//  ClippyGPT
//
//  Created by Eric Kennedy on 6/3/23.
//

import SwiftUI

@main
struct ClippyGPTApp: App {

    @AppStorage("isDarkMode") var isDarkMode: Bool = false

    var body: some Scene {
        WindowGroup {
            ChatView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
