//
//  BridgedClassifier.mm
//  Lunr
//
//  Created by Lwin Oo on 5/24/25.
//

#include "BridgedClassifier.h"
#import <Foundation/Foundation.h>

// This is the actual implementation Swift will call via @_silgen_name
extern "C" const char* classifyContentText(const char* input) {
    NSString *text = [NSString stringWithUTF8String:input];
    
    // Very basic logic for now
    if ([text.lowercaseString containsString:@"youtube"]) {
        return "Entertainment";
    } else if ([text.lowercaseString containsString:@"xcode"] || [text.lowercaseString containsString:@"docs"]) {
        return "Productive";
    } else {
        return "Unknown";
    }
}
