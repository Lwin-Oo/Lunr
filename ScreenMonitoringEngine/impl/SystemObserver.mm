//
//  SystemObserver.mm
//  Lunr
//
//  Created by Lwin Oo on 5/23/25.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "SystemObserverBridge.h"

static BOOL observerRunning = NO;

void startSystemObserver(void) {
    if (observerRunning) return;
    observerRunning = YES;
    NSLog(@"🟢 System Observer started");

    // ⏱ Example placeholder: Print current frontmost app every 10 seconds
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
        while (observerRunning) {
            NSRunningApplication *frontApp = [[NSWorkspace sharedWorkspace] frontmostApplication];
            NSString *appName = [frontApp localizedName];
            NSLog(@"🧪 Frontmost App: %@", appName);
            sleep(10);
        }
    });
}

void stopSystemObserver(void) {
    if (!observerRunning) return;
    observerRunning = NO;
    NSLog(@"🔴 System Observer stopped");
}

bool isSystemObserverRunning(void) {
    return observerRunning;
}
