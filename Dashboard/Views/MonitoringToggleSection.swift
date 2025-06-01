//
//  MonitoringToggleSection.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//

import SwiftUI

struct MonitoringToggleSection: View {
    let isMonitoring: Bool
    let toggleMonitoring: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🖥 Screen Monitoring").font(.headline)

            Text("Status: \(isMonitoring ? "Running" : "Stopped")")
                .font(.caption)
                .foregroundColor(isMonitoring ? .green : .red)

            Button(action: toggleMonitoring) {
                Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isMonitoring ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .frame(maxWidth: 200)
        }
    }
}
