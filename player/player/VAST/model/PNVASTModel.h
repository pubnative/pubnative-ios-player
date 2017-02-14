//
//  PNVASTModel.h
//  VAST
//
//  Created by Jay Tucker on 10/4/13.
//  Copyright (c) 2013 Nexage. All rights reserved.
//
//  VASTModel provides access to VAST document elements; the VAST2Parser result is stored here.

#import <Foundation/Foundation.h>
#import "PNVASTMediaFile.h"

@interface PNVASTModel : NSObject

// returns the version of the VAST document 
- (NSString *)vastVersion;

// returns an array of VASTUrlWithId objects (although the id will always be nil)
- (NSArray<NSString*> *)errors;

// returns an array of VASTUrlWithId objects
- (NSArray<NSString*> *)impressions;

// returns the ClickThrough URL
- (NSString*)clickThrough;

// returns an array of VASTUrlWithId objects
- (NSArray<NSString*> *)clickTracking;

// returns a dictionary whose keys are the names of the event ("start", "midpoint", etc.)
// and whose values are arrays of NSURL objects
- (NSDictionary *)trackingEvents;

// returns an array of VASTMediaFile objects
- (NSArray *)mediaFiles;

@end
