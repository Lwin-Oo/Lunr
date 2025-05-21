//
//  MonitoringOverlay.swift
//  Lunr
//
//  Created by Lwin Oo on 5/20/25.
//

import SwiftUI

struct MonitoringOverlay: View {
    @Binding var detectedText: String

    var body: some View {
        VStack(spacing: 20) {
            ProgressView("Analyzing screen...")
                .progressViewStyle(CircularProgressViewStyle())
                .padding()

            Text("Detected:")
                .font(.caption)
                .foregroundColor(.gray)

            Text(detectedText)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 8)
    }
}
