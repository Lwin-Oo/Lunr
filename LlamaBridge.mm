//
//  LlamaBridge.mm
//  Lunr
//
//  Created by Lwin Oo on 5/20/25.
//

#import "LlamaBridge.h"

const char* classify_with_llama(const char* inputText) {
    @autoreleasepool {
        NSString *rawInput = [NSString stringWithUTF8String:inputText];

        NSArray *lines = [rawInput componentsSeparatedByString:@"\n"];
        NSString *appName = @"UnknownApp";
        NSString *windowTitle = @"";

        for (NSString *line in lines) {
            if ([line hasPrefix:@"App: "]) {
                appName = [line substringFromIndex:5];
            } else if ([line hasPrefix:@"Title: "]) {
                windowTitle = [line substringFromIndex:7];
            }
        }

        NSURL *url = [NSURL URLWithString:@"http://localhost:11434/api/generate"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

        NSString *prompt = [NSString stringWithFormat:
            @"Classify the user’s activity as either 'Productive' or 'Entertaining'. Do NOT return anything else.\n"
            "- Productive = learning, building, reading, coding, professional tools, tutorials, university lectures, email\n"
            "- Entertaining = music, movies, gaming, memes, binge-watching, unrelated browsing\n"
            "- Examples:\n"
            "App: Google Chrome\nTitle: Quantum Mechanics Lecture – YouTube\nLabel: Productive\n"
            "App: Google Chrome\nTitle: Netflix – Stranger Things\nLabel: Entertaining\n"
            "App: Xcode\nTitle: Working on Lunr Dashboard\nLabel: Productive\n"
            "App: Google Chrome\nTitle: YouTube – Cat Compilation\nLabel: Entertaining\n"
            "\nApp: %@\nTitle: %@\nLabel:", appName, windowTitle
        ];

        NSDictionary *json = @{
            @"model": @"mistral",
            @"stream": @NO,
            @"prompt": prompt,
            @"temperature": @0
        };

        NSData *body = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
        [request setHTTPBody:body];

        __block NSString *classification = @"Unknown";
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);

        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 3.0;
        config.timeoutIntervalForResource = 5.0;
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (data && !error) {
                NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if ([result objectForKey:@"response"]) {
                    NSString *raw = result[@"response"];
                    NSString *trimmed = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if ([trimmed isEqualToString:@"Productive"] || [trimmed hasPrefix:@"Productive"]) {
                        classification = @"Productive";
                    } else if ([trimmed isEqualToString:@"Entertaining"] || [trimmed hasPrefix:@"Entertaining"]) {
                        classification = @"Entertaining";
                    } else {
                        classification = @"Entertaining"; // fallback if unclear
                    }
                }
            }
            dispatch_semaphore_signal(sema);
        }];

        [task resume];
        dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)));

        return strdup([classification UTF8String]);
    }
}
