//
//  DateUtils.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//

import Foundation

func parseDeadline(_ string: String) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: string)
}
