//
//  BridgedClassifier.swift
//  Lunr
//
//  Created by Lwin Oo on 5/20/25.
//

import Foundation

@objc public class BridgedClassifier: NSObject {
    @objc public static func classifyText(_ text: String) -> NSString {
        let result = classify_with_llama(text)
        return NSString(utf8String: result) ?? "Unknown"
    }
}



