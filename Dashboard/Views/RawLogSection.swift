//
//  RawLogSection.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//

import SwiftUI

struct RawLogSection: View {
    let openLogInFinder: () -> Void
    let destroyUserData: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("🧾 Raw Data Access").font(.headline)

            Button("Open JSON File in Finder") {
                openLogInFinder()
            }
            .font(.caption)

            Divider()

            Button(role: .destructive) {
                destroyUserData()
            } label: {
                Label("Destroy User", systemImage: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}
