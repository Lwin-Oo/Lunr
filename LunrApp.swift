//
//  LunrApp.swift
//  Lunr
//
//  Created by Lwin Oo on 5/18/25.
//

import SwiftUI

@main
struct LunrApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                OnboardingView()
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

