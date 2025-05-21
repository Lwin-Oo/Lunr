//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import "SystemObserverBridge.h"
#import "BridgedClassifier.h"           // ✅ Declare classifier bridge here only if needed

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>   // ✅ Needed for ScreenRecorder (Swift)
#import <Vision/Vision.h>               // ✅ Needed for OCR in Swift


