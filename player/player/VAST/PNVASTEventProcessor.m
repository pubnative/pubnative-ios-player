//
//  PNVASTEventProcessor.m
//  VAST
//
//  Created by Thomas Poland on 10/3/13.
//  Copyright (c) 2013 Nexage. All rights reserved.
//

#import "PNVASTEventProcessor.h"

@interface PNVASTEventProcessor()

@property(nonatomic, strong) NSDictionary *events;
@property(nonatomic, weak) NSObject<PNVASTEventProcessorDelegate> *delegate;
@property (nonatomic, strong) NSString *userAgent;

@end

@implementation PNVASTEventProcessor

// designated initializer
- (id)initWithEvents:(NSDictionary *)events delegate:(id<PNVASTEventProcessorDelegate>)delegate;
{
    self = [super init];
    if (self) {
        self.events = events;
        self.delegate = delegate;
    }
    return self;
}

- (void)dealloc
{
    self.events = nil;
    self.userAgent = nil;
}

- (void)trackEvent:(PNVASTEvent)event
{
    NSString *eventString = nil;
    switch (event) {
        case PNVASTEvent_Start:           eventString = @"start";           break;
        case PNVASTEvent_FirstQuartile:   eventString = @"firstQuartile";   break;
        case PNVASTEvent_Midpoint:        eventString = @"midpoint";        break;
        case PNVASTEvent_ThirdQuartile:   eventString = @"thirdQuartile";   break;
        case PNVASTEvent_Complete:        eventString = @"complete";        break;
        case PNVASTEvent_Close:           eventString = @"close";           break;
        case PNVASTEvent_Pause:           eventString = @"pause";           break;
        case PNVASTEvent_Resume:          eventString = @"resume";          break;
        default: break;
    }
    [self invokeDidTrackEvent:event];
    if(eventString == nil) {
        [self invokeDidTrackEvent:PNVASTEvent_Unknown];
    } else {
        for (NSURL *eventUrl in self.events[eventString]) {
            [self sendTrackingRequest:eventUrl];
            NSLog(@"VAST - Event Processor: Sent event '%@' to url: %@", eventString, [eventUrl absoluteString]);
        }
    }
}

- (void)invokeDidTrackEvent:(PNVASTEvent)event
{
    if ([self.delegate respondsToSelector:@selector(eventProcessorDidTrackEvent:)]) {
        [self.delegate eventProcessorDidTrackEvent:event];
    }
}

- (void)sendVASTUrlsWithId:(NSArray *)urls
{
    for (NSURL *url in urls) {
        [self sendTrackingRequest:url];
        NSLog(@"VAST - Event Processor: Sent http request to url: %@", url);
    }
}

- (void)sendTrackingRequest:(NSURL *)url
{
    dispatch_queue_t sendTrackRequestQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(sendTrackRequestQueue, ^{
        
        NSLog(@"VAST - Event Processor: Event processor sending request to url: %@", [url absoluteString]);
        
        NSURLSession * session = [NSURLSession sharedSession];
        if(self.userAgent == nil){
            UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectZero];
            self.userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        }
        session.configuration.HTTPAdditionalHeaders = @{@"User-Agent": self.userAgent};
        
        NSURLRequest* request = [NSURLRequest requestWithURL:url
                                                 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                             timeoutInterval:1.0];
        
        [[session dataTaskWithRequest:request
                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                        
            // Send the request only, no response or errors
            if(error == nil) {
                NSLog(@"VAST - tracking url %@ error: %@", response.URL, error);
            } else {
                NSLog(@"VAST - tracking url %@ response: %@", response.URL, [NSString stringWithUTF8String:[data bytes]]);
            }
        }] resume];
    });
}

@end
