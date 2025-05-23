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

        // Expecting "App: NAME\nTitle: TITLE"
        NSArray<NSString*> *lines = [input componentsSeparatedByString:@"\n"];
        NSString *appName = @"UnknownApp";
        NSString *title = @"";

        for (NSString *line in lines) {
            if ([line hasPrefix:@"App: "]) {
                appName = [line substringFromIndex:5];
            } else if ([line hasPrefix:@"Title: "]) {
                title = [line substringFromIndex:7];
            }
        }

        NSString* result = [BridgedClassifier classifyWithAppName:appName title:title];
        return strdup([result UTF8String]);
    }
}

