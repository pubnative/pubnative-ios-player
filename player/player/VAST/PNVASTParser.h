//
//  SKVAST2Parser.h
//  VAST
//
//  Created by Jay Tucker on 10/2/13.
//  Copyright (c) 2013 Nexage. All rights reserved.
//
//  VAST2Parser parses a supplied VAST 2.0 URL or document and returns the result in VASTModel.

#import <Foundation/Foundation.h>

typedef enum : NSInteger {
    PNVASTParserError_None,
    PNVASTParserError_XMLParse,
    PNVASTParserError_SchemaValidation,
    PNVASTParserError_TooManyWrappers,
    PNVASTParserError_NoCompatibleMediaFile,
    PNVASTParserError_NoInternetConnection,
    PNVASTParserError_MovieTooShort
} PNVASTParserError;

@class PNVASTModel;

@interface PNVASTParser : NSObject

- (void)parseWithUrl:(NSURL *)url completion:(void (^)(PNVASTModel *, PNVASTParserError))block;

@end
