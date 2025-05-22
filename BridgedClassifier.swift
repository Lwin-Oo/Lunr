//
//  BridgedClassifier.swift
//  Lunr
//
//  Created by Lwin Oo on 5/20/25.
//

import Foundation

@objc public class BridgedClassifier: NSObject {
    @objc public static func classifyText(_ text: String) -> NSString {
        var result: NSString = "Unknown"

        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.global(qos: .userInitiated).async {
            if let ptr = classify_with_llama(text) {
                result = NSString(utf8String: ptr) ?? "Unknown"
            }
            semaphore.signal()
        }

        // Wait max 3 seconds to avoid freeze
        _ = semaphore.wait(timeout: .now() + 3)

        return result
    }
}





