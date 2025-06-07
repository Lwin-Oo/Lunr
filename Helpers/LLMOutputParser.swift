//
//  LLMOutputParser.swift
//  Lunr
//
//  Created by Lwin Oo on 6/6/25.
//

import Foundation

extension String {
    func extractField(named name: String) -> String {
        let pattern = "\(name)[^\\n]*:\\s*(.+)"
        if let match = self.range(of: pattern, options: .regularExpression) {
            return String(self[match])
                .components(separatedBy: ":")
                .last?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        return ""
    }

    func extractList(named name: String, separator: String = ",") -> [String] {
        let raw = extractField(named: name)
        return raw.split(separator: Character(separator)).map { $0.trimmingCharacters(in: .whitespaces) }
    }
}


