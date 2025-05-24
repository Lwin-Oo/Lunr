//
//  LunrApp.swift
//  Lunr
//
//  Created by Lwin Oo on 5/18/25.
//

import SwiftUI

@main
struct LunrApp: App {
    @StateObject private var userManager = UserManager.shared

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
            .environmentObject(userManager)
        }
    }
}


