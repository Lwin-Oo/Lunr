//
//  ScreenLogger.mm
//  Lunr
//
//  Created by Lwin Oo on 5/23/25.
//

#import "ScreenLogger.h"
#import <Foundation/Foundation.h>

static BOOL isLogging = NO;
static NSTimer *logTimer;

void writeFakeLog() {
    NSLog(@"🟢 Logger tick - recording app usage...");
    // TODO: Replace with actual AX/UI logic
    NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Lunr/logs"];
    [[NSFileManager defaultManager] createDirectoryAtPath:logPath withIntermediateDirectories:YES attributes:nil error:nil];

    NSString *filename = [NSString stringWithFormat:@"%@.json", [[NSDate date] descriptionWithLocale:[NSLocale currentLocale]]];
    NSString *fullPath = [logPath stringByAppendingPathComponent:filename];

    NSDictionary *fakeSession = @{
        @"date": [[NSDate date] description],
        @"sessions": @[
            @{
                @"app": @"Safari",
                @"windowTitle": @"WWDC Keynote",
                @"startTime": @"10:00",
                @"endTime": @"10:30",
                @"durationSeconds": @1800,
                @"classification": @"Productive"
            }
        ]
    };

    NSData *data = [NSJSONSerialization dataWithJSONObject:fakeSession options:NSJSONWritingPrettyPrinted error:nil];
    [data writeToFile:fullPath atomically:YES];
}

void runLogger() {
    if (isLogging) return;
    isLogging = YES;
    NSLog(@"✅ Logger started");
    logTimer = [NSTimer scheduledTimerWithTimeInterval:15 target:[NSBlockOperation blockOperationWithBlock:^{
        writeFakeLog();
    }] selector:@selector(main) userInfo:nil repeats:YES];
}

void stopLogger() {
    if (!isLogging) return;
    isLogging = NO;
    NSLog(@"🛑 Logger stopped");
    [logTimer invalidate];
    logTimer = nil;
}
