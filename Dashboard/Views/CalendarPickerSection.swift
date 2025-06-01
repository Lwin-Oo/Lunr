//
//  CalendarPickerSection.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//
//  This component renders a date picker that allows the user to select a specific date.
//  When a new date is picked, it triggers `loadData` to fetch usage data for that date.
//  Includes a "Reset" button to quickly return to today.
//

import SwiftUI

// MARK: - 📅 CalendarPickerSection
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
