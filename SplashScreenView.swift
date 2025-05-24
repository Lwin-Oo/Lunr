//
//  SplashScreenView.swift
//  Lunr
//
//  Created by Lwin Oo on 5/23/25.
//

import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            Color(NSColor.windowBackgroundColor).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                Text("Loading Lunr...")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
    }
}
