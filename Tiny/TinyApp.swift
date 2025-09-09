//
//  TinyApp.swift
//  Tiny
//
//  Created by Harlen Postill on 9/9/2025.
//

import SwiftUI

@main
struct TinyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(.ultraThinMaterial)
                .tabViewCustomization(.none)
                .navigationTitle("Tiny")
        }
        .windowStyle(.hiddenTitleBar)
    }
}
