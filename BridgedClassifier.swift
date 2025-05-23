//
//  BridgedClassifier.swift
//  Lunr
//
//  Created by Lwin Oo on 5/20/25.
//

import Foundation

@_silgen_name("classify_with_llama")
func classify_with_llama(_ input: UnsafePointer<CChar>) -> UnsafePointer<CChar>?

@objc public class BridgedClassifier: NSObject {
    
    // ✅ Method used by BridgedClassifier.mm
    @objc public static func classifyWithAppName(_ appName: NSString, title: NSString) -> NSString {
        let combined = "App: \(appName)\nTitle: \(title)"
        let cString = combined.cString(using: .utf8)!
        
        if let ptr = classify_with_llama(cString) {
            return NSString(utf8String: ptr) ?? "Unknown"
        } else {
            return "Unknown"
        }
    }

    // ✅ Method used in Swift directly when raw full text is available
    @objc public static func classifyWithRawText(_ input: NSString) -> NSString {
        let lines = input.components(separatedBy: "\n")
        var app = "Unknown", title = "", content = ""

        for line in lines {
            if line.hasPrefix("App: ") {
                app = String(line.dropFirst(5))
            } else if line.hasPrefix("Title: ") || line.hasPrefix("Tab: ") {
                title = String(line.dropFirst(6))
            } else if line.hasPrefix("Screen: ") {
                content = String(line.dropFirst(8))
            }
        }

        let prompt = "App: \(app)\nTitle: \(title)\nScreen: \(content)"
        let cString = prompt.cString(using: .utf8)!

        if let ptr = classify_with_llama(cString) {
            return NSString(utf8String: ptr) ?? "Unknown"
        } else {
            return "Unknown"
        }
    }
}


