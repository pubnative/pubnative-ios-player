//
//  Copyright (c) 2017 PubNative
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "PNVASTModel.h"
#import "PNVASTMediaFile.h"
#import "PNVASTXMLUtil.h"

@interface PNVASTModel ()

@property (nonatomic, strong)NSMutableArray *vastDocumentArray;

// returns an array of VASTUrlWithId objects
- (NSArray *)resultsForQuery:(NSString *)query;

// returns the text content of both simple text and CDATA sections
- (NSString *)content:(NSDictionary *)node;

@end

@implementation PNVASTModel

#pragma mark - "private" method

- (void)dealloc
{
    self.vastDocumentArray = nil;
}

// We deliberately do not declare this method in the header file in order to hide it.
// It should be used only be the VAST2Parser to build the model.
// It should not be used by anybody else receiving the model object.
- (void)addVASTDocument:(NSData *)vastDocument
{
    if (self.vastDocumentArray == nil) {
        self.vastDocumentArray = [NSMutableArray array];
    }
    [self.vastDocumentArray addObject:vastDocument];
}

#pragma mark - public methods

- (NSString *)vastVersion
{
    // sanity check
    if ([self.vastDocumentArray count] == 0) {
        return nil;
    }
    
    NSString *version;
    NSString *query = @"/VAST/@version";
    NSArray *results = performXMLXPathQuery(self.vastDocumentArray[0], query);
    // there should be only a single result
    if ([results count] > 0) {
        NSDictionary *attribute = results[0];
        version = attribute[@"nodeContent"];
    }
    return version;
}

- (NSArray<NSString*> *)errors
{
    NSString *query = @"//Error";
    return [self resultsForQuery:query];
}

- (NSArray<NSString*> *)impressions
{
    NSString *query = @"//Impression";
    return [self resultsForQuery:query];
}

- (NSString *)clickThrough
{
    NSString *query = @"//ClickThrough";
    NSArray *array = [self resultsForQuery:query];
    // There should be at most only one array element.
    return ([array count] > 0) ? array[0] : nil;
}

- (NSArray<NSString*> *)clickTracking
{
    NSString *query = @"//ClickTracking";
    return [self resultsForQuery:query];
}

- (NSDictionary *)trackingEvents
{
    NSMutableDictionary *eventDict;
    NSString *query = @"//Linear//Tracking";

    for (NSData *document in self.vastDocumentArray) {
        NSArray *results = performXMLXPathQuery(document, query);
        for (NSDictionary *result in results) {
            // use lazy initialization
            if (!eventDict) {
                eventDict = [NSMutableDictionary dictionary];
            }
            NSString *urlString = [self content:result];
            NSArray *attributes = result[@"nodeAttributeArray"];
            for (NSDictionary *attribute in attributes) {
                NSString *name = attribute[@"attributeName"];
                if ([name isEqualToString:@"event"]) {
                    NSString *event = attribute[@"nodeContent"];
                    NSMutableArray *newEventArray = [NSMutableArray array];
                    NSArray *oldEventArray = [eventDict valueForKey:event];
                    if (oldEventArray) {
                        [newEventArray addObjectsFromArray:oldEventArray];
                    }
                    NSURL *eventURL = [self urlWithCleanString:urlString];
                    if (eventURL) {
                        [newEventArray addObject:[self urlWithCleanString:urlString]];
                        [eventDict setValue:newEventArray forKey:event];
                    }
                }
            }
        }
    }
    
    NSLog(@"VAST - Model: returning event dictionary with %lu event(s)", (unsigned long)[eventDict count]);
    for (NSString *event in [eventDict allKeys]) {
        NSArray *array = (NSArray *)[eventDict valueForKey:event];
        NSLog(@"VAST - Model: %@ has %lu URL(s)", event, (unsigned long)[array count]);
    }
    
    return eventDict;
}

- (NSArray *)mediaFiles;
{
    NSMutableArray *mediaFileArray;
    NSString *query = @"//MediaFile";
    
    for (NSData *document in self.vastDocumentArray) {
        NSArray *results = performXMLXPathQuery(document, query);
        for (NSDictionary *result in results) {
 
            // use lazy initialization
            if (!mediaFileArray) {
                mediaFileArray = [NSMutableArray array];
            }
            
            NSString *id_;
            NSString *delivery;
            NSString *type;
            NSString *bitrate;
            NSString *width;
            NSString *height;
            NSString *scalable;
            NSString *maintainAspectRatio;
            NSString *apiFramework;
            
            NSArray *attributes = result[@"nodeAttributeArray"];
            for (NSDictionary *attribute in attributes) {
                NSString *name = attribute[@"attributeName"];
                NSString *content = attribute[@"nodeContent"];
                if ([name isEqualToString:@"id"]) {
                    id_ = content;
                } else  if ([name isEqualToString:@"delivery"]) {
                    delivery = content;
                } else  if ([name isEqualToString:@"type"]) {
                    type = content;
                } else  if ([name isEqualToString:@"bitrate"]) {
                    bitrate = content;
                } else  if ([name isEqualToString:@"width"]) {
                    width = content;
                } else  if ([name isEqualToString:@"height"]) {
                    height = content;
                } else  if ([name isEqualToString:@"scalable"]) {
                    scalable = content;
                } else  if ([name isEqualToString:@"maintainAspectRatio"]) {
                    maintainAspectRatio = content;
                } else  if ([name isEqualToString:@"apiFramework"]) {
                    apiFramework = content;
                }
            }
            NSString *urlString = [self content:result];
            if (urlString != nil) {
                urlString = [[self urlWithCleanString:urlString] absoluteString];
            }
            
            PNVASTMediaFile *mediaFile = [[PNVASTMediaFile alloc]
                                        initWithId:id_
                                        delivery:delivery
                                        type:type
                                        bitrate:bitrate
                                        width:width
                                        height:height
                                        scalable:scalable
                                        maintainAspectRatio:maintainAspectRatio
                                        apiFramework:apiFramework
                                        url:urlString];
            
            [mediaFileArray addObject:mediaFile];
        }
    }
    
    return mediaFileArray;
}

#pragma mark - helper methods

- (NSArray *)resultsForQuery:(NSString *)query
{
    NSMutableArray *array;
    NSString *elementName = [query stringByReplacingOccurrencesOfString:@"/" withString:@""];
    
    for (NSData *document in self.vastDocumentArray) {
        NSArray *results = performXMLXPathQuery(document, query);
        for (NSDictionary *result in results) {
            if (array == nil) {
                array = [NSMutableArray array];
            }
            NSString *urlString = [self content:result];
            if(urlString != nil) {
                [array addObject:urlString];
            }
        }
    }
    
    NSLog(@"VAST - Model: returning %@ array with %lu element(s)", elementName, (unsigned long)[array count]);
    return array;
}

- (NSString *)content:(NSDictionary *)node
{
    // this is for string data
    if ([node[@"nodeContent"] length] > 0) {
        return node[@"nodeContent"];
    }
    
    // this is for CDATA
    NSArray *childArray = node[@"nodeChildArray"];
    if ([childArray count] > 0) {
        // return the first array element that is not a comment
        for (NSDictionary *childNode in childArray) {
            if ([childNode[@"nodeName"] isEqualToString:@"comment"]) {
                continue;
            }
            return childNode[@"nodeContent"];
        }
    }
    
    return nil;
}

- (NSURL*)urlWithCleanString:(NSString *)string
{
    NSString *cleanUrlString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];  // remove leading, trailing \n or space
    cleanUrlString = [cleanUrlString stringByReplacingOccurrencesOfString:@"|" withString:@"%7c"];
    return [NSURL URLWithString:cleanUrlString];                                                                            // return the resulting URL
}

@end
