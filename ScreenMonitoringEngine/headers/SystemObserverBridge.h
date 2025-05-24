//
//  SystemObserverBridge.h
//  Lunr
//
//  Created by Lwin Oo on 5/23/25.
//

#ifndef SystemObserverBridge_h
#define SystemObserverBridge_h

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Starts the system observer engine.
void startSystemObserver(void);

/// Stops the system observer engine.
void stopSystemObserver(void);

/// Returns true if the observer is running.
bool isSystemObserverRunning(void);

#ifdef __cplusplus
}
#endif

#endif /* SystemObserverBridge_h */
