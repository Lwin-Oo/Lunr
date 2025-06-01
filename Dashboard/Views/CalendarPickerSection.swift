//
//  CalendarPickerSection.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//
import SwiftUI

struct CalendarPickerSection: View {
    @Binding var selectedDate: Date
    let loadData: (Date) -> Void

    var body: some View {
        HStack {
            DatePicker("Pick a Date", selection: $selectedDate, displayedComponents: .date)
                .onChange(of: selectedDate) { loadData($0) }

            Spacer()

            Button("Reset") {
                selectedDate = Date()
                loadData(Date())
            }
        }
    }
}
