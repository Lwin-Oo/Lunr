//
//  LlamaBridge.mm
//  Lunr
//
//  Created by Lwin Oo on 5/20/25.
//

#import "LlamaBridge.h"

const char* classify_with_llama(const char* text) {
    @autoreleasepool {
        NSString *input = [NSString stringWithUTF8String:text];
        NSURL *url = [NSURL URLWithString:@"http://localhost:11434/api/generate"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

        NSDictionary *json = @{ @"model": @"mistral", @"prompt": [NSString stringWithFormat:@"Classify this text into either 'Work', 'Entertainment', or 'Unknown': \"%@\"\nLabel:", input] };
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
                    classification = [[result objectForKey:@"response"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                }
            }
            dispatch_semaphore_signal(sema);
        }];

        [task resume];
        dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)));

        return strdup([classification UTF8String]);
    }
}
