//
//  ContentView.swift
//  Lunr
//
//  Created by Lwin Oo on 5/18/25.
//

import SwiftUI

@_silgen_name("runLogger") func runLogger()
@_silgen_name("stopLogger") func stopLogger()

struct ContentView: View {
    @State private var isLogging = false

    var body: some View {
        VStack(spacing: 20) {
            Text("🧠 Lunr System Observer")
                .font(.title)
                .padding()

            if isLogging {
                Text("🔴 Logging is ACTIVE")
                    .foregroundColor(.red)
            } else {
                Text("🟢 Logging is STOPPED")
                    .foregroundColor(.green)
            }

            HStack(spacing: 20) {
                Button(action: {
                    guard !isLogging else { return }
                    isLogging = true
                    DispatchQueue.global(qos: .background).async {
                        runLogger()
                    }
                }) {
                    Text("Start Logging")
                        .frame(width: 140)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isLogging)

                Button(action: {
                    guard isLogging else { return }
                    stopLogger()
                    isLogging = false
                }) {
                    Text("Stop Logging")
                        .frame(width: 140)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!isLogging)
            }

            Spacer()
        }
        .frame(width: 400, height: 300)
        .padding()
    }
}

