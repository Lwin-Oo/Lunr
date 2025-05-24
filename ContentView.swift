//
//  ContentView.swift
//  Lunr
//
//  Created by Lwin Oo on 5/18/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userManager: UserManager  // Pull from environment

    var body: some View {
        Group {
            if !userManager.isUserLoaded {
                SplashScreenView()
            } else if userManager.currentUser != nil {
                LunrDashboard()
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: userManager.isUserLoaded)
        .transition(.opacity)
    }
}

