//
//  PNVASTEventProcessor.h
//  VAST
//
//  Created by Thomas Poland on 10/3/13.
//  Copyright (c) 2013 Nexage. All rights reserved.
//
//  VASTEventTracker wraps NSURLRequest to handle sending tracking and impressions events defined in the VAST 2.0 document and stored in VASTModel.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PNVASTModel.h"

typedef enum : NSInteger {
    PNVASTEvent_Start,
    PNVASTEvent_FirstQuartile,
    PNVASTEvent_Midpoint,
    PNVASTEvent_ThirdQuartile,
    PNVASTEvent_Complete,
    PNVASTEvent_Close,
    PNVASTEvent_Pause,
    PNVASTEvent_Resume,
    PNVASTEvent_Unknown
} PNVASTEvent;

@class PNVASTEventProcessor;

@protocol PNVASTEventProcessorDelegate <NSObject>

- (void)eventProcessorDidTrackEvent:(PNVASTEvent)event;

@end

@interface PNVASTEventProcessor : NSObject

// designated initializer, uses tracking events stored in VASTModel
- (id)initWithEvents:(NSDictionary *)events delegate:(id<PNVASTEventProcessorDelegate>)delegate;
// sends the given VASTEvent
- (void)trackEvent:(PNVASTEvent)event;
// sends the set of http requests to supplied URLs, used for Impressions, ClickTracking, and Errors.
- (void)sendVASTUrls:(NSArray *)url;

@end
