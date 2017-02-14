//
//  PNVASTMediaFilePicker.m
//  VAST
//
//  Created by Muthu on 11/20/13.
//  Copyright (c) 2013 Nexage. All rights reserved.
//

#import "PNVASTMediaFilePicker.h"
#import "PNVASTReachability.h"
#import <UIKit/UIKit.h>

@interface PNVASTMediaFilePicker()

+ (BOOL)isMIMETypeCompatible:(PNVASTMediaFile *)vastMediaFile;

@end

@implementation PNVASTMediaFilePicker

+ (PNVASTMediaFile *)pick:(NSArray *)mediaFiles
{
    // Check whether we even have a network connection.
    // If not, return a nil.
    if (![PNVASTMediaFilePicker isInternetReachable]) {
        return nil;
    }
    
    // Go through the provided media files and only those that have a compatible MIME type.
    NSMutableArray *compatibleMediaFiles = [[NSMutableArray alloc] init];
    for (PNVASTMediaFile *vastMediaFile in mediaFiles) {
        // Make sure that you have type specified for mediafile and ignore accordingly
        if (vastMediaFile.type != nil && [self isMIMETypeCompatible:vastMediaFile]) {
            [compatibleMediaFiles addObject:vastMediaFile];
        }
    }
    if ([compatibleMediaFiles count] == 0) {
        return nil;
    }
    
    // Sort the media files based on their video size (in square pixels).
    NSArray *sortedMediaFiles = [compatibleMediaFiles sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        PNVASTMediaFile *mf1 = (PNVASTMediaFile *)a;
        PNVASTMediaFile *mf2 = (PNVASTMediaFile *)b;
        int area1 = mf1.width * mf1.height;
        int area2 = mf2.width * mf2.height;
        if (area1 < area2) {
            return NSOrderedAscending;
        } else if (area1 > area2) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    
    // Pick the media file with the video size closes to the device's screen size.
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    int screenArea = screenSize.width * screenSize.height;
    int bestMatch = 0;
    int bestMatchDiff = INT_MAX;
    int len = (int)[sortedMediaFiles count];
    
    for (int i = 0; i < len; i++) {
        int videoArea = ((PNVASTMediaFile *)sortedMediaFiles[i]).width * ((PNVASTMediaFile *)sortedMediaFiles[i]).height;
        int diff = abs(screenArea - videoArea);
       if (diff >= bestMatchDiff) {
            break;
        }
        bestMatch = i;
        bestMatchDiff = diff;
    }
    
    PNVASTMediaFile *toReturn = (PNVASTMediaFile *)sortedMediaFiles[bestMatch];
    NSLog(@"VAST - Mediafile Picker: Selected Media File: %@", toReturn.url);
    return toReturn;
}

+ (BOOL)isInternetReachable
{
    BOOL result = false;
    PNVASTReachability *reachability = [PNVASTReachability reachabilityForInternetConnection];
    [reachability startNotifier];
    PNVASTReachability_NetworkStatus currentNetwork = [reachability currentReachabilityStatus];
    NSLog(@"VAST - Mediafile Picker: NetworkType: %ld", (long)currentNetwork);
    result = currentNetwork != PNVASTReachability_NotReachable;
    [reachability stopNotifier];
    return result;}

+ (BOOL)isMIMETypeCompatible:(PNVASTMediaFile *)vastMediaFile
{
    NSString *pattern = @"(mp4|m4v|quicktime|3gpp)";
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSArray *matches = [regex matchesInString:vastMediaFile.type
                                      options:0
                                        range:NSMakeRange(0, [vastMediaFile.type length])];
    
    return ([matches count] > 0);
}

@end
