//
//  LunrApp.swift
//  Lunr
//
//  Created by Lwin Oo on 5/18/25.
//

import SwiftUI

@main
struct LunrApp: App {
    let persistenceController = PersistenceController.shared // <- inject Core Data context

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    DispatchQueue.global(qos: .background).async {
                        runLogger()
                    }
                }
        }
    }
}


