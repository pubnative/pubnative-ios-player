//
//  PNVASTPlayerViewController.h
//  player
//
//  Created by David Martin on 08/02/2017.
//  Copyright © 2017 pubnative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class PNVASTPlayerViewController;

@protocol PNVASTPlayerViewControllerDelegate <NSObject>

- (void)vastPlayerDidFinishLoading:(PNVASTPlayerViewController*)vastPlayer;
- (void)vastPlayer:(PNVASTPlayerViewController*)vastPlayer didFailLoadingWithError:(NSError*)error;
- (void)vastPlayerDidStartPlaying:(PNVASTPlayerViewController*)vastPlayer;
- (void)vastPlayerDidPause:(PNVASTPlayerViewController*)vastPlayer;
- (void)vastPlayerDidComplete:(PNVASTPlayerViewController*)vastPlayer;

@end

@interface PNVASTPlayerViewController : UIViewController

@property (nonatomic, assign) NSTimeInterval                                loadTimeout;
@property (nonatomic, assign) BOOL                                          canResize;
@property (nonatomic, strong) NSObject<PNVASTPlayerViewControllerDelegate>  *delegate;

- (void)loadWithVastUrl:(NSURL*)url;
- (void)play;
- (void)pause;
- (void)stop;

@end
