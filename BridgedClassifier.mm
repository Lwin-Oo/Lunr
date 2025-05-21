//
//  BridgedClassifier.mm
//  Lunr
//
//  Created by Lwin Oo on 5/20/25.
//

#import <Foundation/Foundation.h>
#import "BridgedClassifier.h"
#import "Lunr-Swift.h"

const char* classifyContentText(const char* text) {
    @autoreleasepool {
        NSString* input = [NSString stringWithUTF8String:text];
        NSString* result = [BridgedClassifier classifyText:input];
        return strdup([result UTF8String]); // Copy to C-style string
    }
}
