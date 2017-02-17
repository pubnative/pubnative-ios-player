//
//  PNVASTPlayerViewController.m
//  player
//
//  Created by David Martin on 08/02/2017.
//  Copyright © 2017 pubnative. All rights reserved.
//

#import "PNVASTPlayerViewController.h"
#import "PNVASTParser.h"
#import "PNVASTModel.h"
#import "PNVASTMediaFilePicker.h"
#import "PNVASTEventProcessor.h"

NSTimeInterval const kPNVASTPlayerDefaultLoadTimeout        = 20.0f;
NSTimeInterval const kPNVASTPlayerDefaultPlaybackInterval   = 0.25f;

typedef enum : NSUInteger {
    PNVastPlayerState_IDLE = 1 << 0,
    PNVastPlayerState_LOAD = 1 << 1,
    PNVastPlayerState_READY = 1 << 2,
    PNVastPlayerState_PLAY = 1 << 3,
    PNVastPlayerState_PAUSE = 1 << 4
}PNVastPlayerState;

typedef enum : NSUInteger {
    PNVastPlaybackState_FirstQuartile = 1 << 0,
    PNVastPlaybackState_SecondQuartile = 1 << 1,
    PNVastPlaybackState_ThirdQuartile = 1 << 2,
    PNVastPlaybackState_FourthQuartile = 1 << 3
}PNVastPlaybackState;

@interface PNVASTPlayerViewController ()<PNVASTEventProcessorDelegate>

@property (nonatomic, assign) BOOL                      shown;
@property (nonatomic, assign) PNVastPlayerState         currentState;
@property (nonatomic, assign) PNVastPlaybackState       playback;
@property (nonatomic, strong) NSURL                     *vastUrl;
@property (nonatomic, strong) PNVASTModel               *vastModel;
@property (nonatomic, strong) PNVASTParser              *parser;
@property (nonatomic, strong) PNVASTEventProcessor      *eventProcessor;
@property (nonatomic, strong) MPMoviePlayerController   *player;
@property (nonatomic, strong) NSTimer                   *loadTimer;
@property (nonatomic, strong) NSTimer                   *playbackTimer;

@end

@implementation PNVASTPlayerViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.state = PNVastPlayerState_IDLE;
        self.playback = PNVastPlaybackState_FirstQuartile;
    }
    return self;
}

- (void)loadView
{
    self.view = [[UIView alloc] init];
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)dealloc
{
    [self close];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.shown = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.shown = NO;
}

#pragma mark - PUBLIC -

- (void)loadWithVastUrl:(NSURL*)url
{
    @synchronized (self) {
        self.vastUrl = url;
        [self setState:PNVastPlayerState_LOAD];
    }
}

- (void)play
{
    @synchronized (self) {
        [self setState:PNVastPlayerState_PLAY];
    }
}

- (void)pause
{
    @synchronized (self) {
        [self setState:PNVastPlayerState_PAUSE];
    }
}

- (void)stop
{
    @synchronized (self) {
        [self setState:PNVastPlayerState_IDLE];
    }
}

#pragma mark - PRIVATE -

- (void)close
{
    @synchronized (self) {
        [self removeObservers];
        [self stopLoadTimeoutTimer];
        [self stopPlaybackTimer];
        if(self.shown) {
            [self.eventProcessor trackEvent:PNVASTEvent_Close];
        }
        @try {
            [self.player stop];
            self.player = nil;
        }
        
        @catch (NSException *exception) {
            NSLog(@"PNVASTPlayer - exception ocurred when closing the player - %@", exception);
        }
        self.vastUrl = nil;
        self.vastModel = nil;
        self.parser = nil;
        self.eventProcessor = nil;
    }
}

- (void)createVideoPlayerWithVideoUrl:(NSURL*)url
{
    @try {
        
        if(self.player == nil) {
            self.player = [[MPMoviePlayerController alloc] initWithContentURL:url];
            self.player.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
            [self.view addSubview:self.player.view];
            self.view.autoresizesSubviews = YES;
            self.player.controlStyle = MPMovieControlStyleNone;
            self.player.shouldAutoplay = NO;
            self.player.fullscreen = NO;
        }
        
        [self.player prepareToPlay];
        
    } @catch (NSException *exception) {
        NSLog(@"PNVASTPlayer - Exception ocurred when creating the video player: %@", exception);
        [self close];
        [self setState:PNVastPlayerState_IDLE];
    }
}

#pragma mark - Delegate helpers

- (void)invokeDidFinishLoading
{
    [self stopLoadTimeoutTimer];
    if([self.delegate respondsToSelector:@selector(vastPlayerDidFinishLoading:)]) {
        [self.delegate vastPlayerDidFinishLoading:self];
    }
}

- (void)invokeDidFailLoadingWithError:(NSError*)error
{
    [self close];
    if([self.delegate respondsToSelector:@selector(vastPlayer:didFailLoadingWithError:)]) {
        [self.delegate vastPlayer:self didFailLoadingWithError:error];
    }
    [self trackError];
}

- (void)invokeDidStartPlaying
{
    if([self.delegate respondsToSelector:@selector(vastPlayerDidStartPlaying:)]) {
        [self.delegate vastPlayerDidStartPlaying:self];
    }
}

- (void)invokeDidPause
{
    if([self.delegate respondsToSelector:@selector(vastPlayerDidPause:)]) {
        [self.delegate vastPlayerDidPause:self];
    }
}

- (void)invokeDidComplete
{
    if([self.delegate respondsToSelector:@selector(vastPlayerDidComplete:)]) {
        [self.delegate vastPlayerDidComplete:self];
    }
}

#pragma mark - MPMoviePlayer notifications

- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(applicationDidBecomeActive:)
                                                 name: UIApplicationDidBecomeActiveNotification
                                               object: nil];
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerMovieDurationAvailable:)
                                                 name:MPMovieDurationAvailableNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerMoviePlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerPlaybackStateDidChangeNotification:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerLoadStateDidChanged:)
                                                 name:MPMoviePlayerLoadStateDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerSourceTypeAvailable:)
                                                 name:MPMovieSourceTypeAvailableNotification
                                               object:nil];
    #pragma clang diagnostic pop
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMovieDurationAvailableNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMovieSourceTypeAvailableNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
    #pragma clang diagnostic pop
}

- (void)applicationDidBecomeActive:(NSNotification*)notification
{
    
}

- (void)playerMovieDurationAvailable:(NSNotification*)notification
{
    NSLog(@"VAST - Movie duration available %f", self.player.duration);
}

- (void)playerMoviePlayBackDidFinish:(NSNotification*)notification
{
    NSLog(@"VAST - Movie finish playing");
    [self.eventProcessor trackEvent:PNVASTEvent_Complete];
    [self setState:PNVastPlayerState_IDLE];
    [self invokeDidComplete];
}

- (void)playerPlaybackStateDidChangeNotification:(NSNotification*)notification
{
    NSLog(@"VAST - Movie playback state changed");
}

- (void)playerLoadStateDidChanged:(NSNotification*)notification
{
    NSLog(@"VAST - Movie load state changed");
    if (self.player.loadState == (MPMovieLoadStatePlayable|MPMovieLoadStatePlaythroughOK))
    {
        [self setState:PNVastPlayerState_READY];
    }
}

- (void)playerSourceTypeAvailable:(NSNotification*)notification
{
    NSLog(@"VAST - Movie source type available");
}

#pragma mark - State Machine

- (BOOL)canGoToState:(PNVastPlayerState)state
{
    BOOL result = NO;
    
    switch (state) {
        case PNVastPlayerState_IDLE:    result = YES; break;
        case PNVastPlayerState_LOAD:    result = self.currentState & PNVastPlayerState_IDLE; break;
        case PNVastPlayerState_READY:   result = self.currentState & PNVastPlayerState_LOAD; break;
        case PNVastPlayerState_PLAY:    result = self.currentState & (PNVastPlayerState_READY|PNVastPlayerState_PAUSE); break;
        case PNVastPlayerState_PAUSE:   result = self.currentState & PNVastPlayerState_PLAY; break;
        default: break;
    }
    
    return result;
}

- (void)setState:(PNVastPlayerState)state
{
    if ([self canGoToState:state]) {
        self.currentState = state;
        switch (self.currentState) {
            case PNVastPlayerState_IDLE:    [self setIdleState];    break;
            case PNVastPlayerState_LOAD:    [self setLoadState];    break;
            case PNVastPlayerState_READY:   [self setReadyState];   break;
            case PNVastPlayerState_PLAY:    [self setPlayState];    break;
            case PNVastPlayerState_PAUSE:   [self setPauseState];   break;
        }
    } else {
        NSLog(@"PNVastPlayer - Cannot go to state %lu, invalid previous state", (unsigned long)state);
    }
}

- (void)setIdleState
{
    NSLog(@"PNVastPlayer - setIdleState");
    [self close];
}

- (void)setLoadState
{
    NSLog(@"PNVastPlayer - setLoadState");
    if (self.vastUrl == nil) {
        NSLog(@"PNVastPlayer - setLoadState error: VAST url is nil and required");
        [self setState:PNVastPlayerState_IDLE];
    } else {
        [self addObservers];
        
        if (self.parser == nil) {
            self.parser = [[PNVASTParser alloc] init];
        }
        
        [self startLoadTimeoutTimer];
        __weak PNVASTPlayerViewController *weakSelf = self;
        [self.parser parseWithUrl:self.vastUrl
                       completion:^(PNVASTModel *model, PNVASTParserError error) {
                           
           if (model == nil) {
               NSError *parseError = [NSError errorWithDomain:[NSString stringWithFormat:@"%ld", (long)error]
                                                         code:0
                                                     userInfo:nil];
               [weakSelf invokeDidFailLoadingWithError:parseError];
           } else {
               weakSelf.eventProcessor = [[PNVASTEventProcessor alloc] initWithEvents:[model trackingEvents] delegate:self];
               NSURL *mediaUrl = [PNVASTMediaFilePicker pick:[model mediaFiles]].url;
               if(mediaUrl == nil) {
                   NSLog(@"PNVASTPlayer - Error: did not find a compatible mediaFile");
                   NSError *mediaNotFoundError = [NSError errorWithDomain:@"PNVASTPlayer - Error: Not found compatible media with this device" code:0 userInfo:nil];
                   [weakSelf invokeDidFailLoadingWithError:mediaNotFoundError];
               } else {
                   weakSelf.vastModel = model;
                   [weakSelf createVideoPlayerWithVideoUrl:mediaUrl];
               }
            }
        }];
    }
}

- (void)trackError
{
    NSLog(@"VASTPlayer - Sending Error requests");
    if(self.vastModel && [self.vastModel errors] != nil) {
        [self.eventProcessor sendVASTUrlsWithId:[self.vastModel errors]];
    }
}

- (void)setReadyState
{
    NSLog(@"PNVastPlayer - setReadyState");
    [self invokeDidFinishLoading];
}

- (void)setPlayState
{
    NSLog(@"PNVastPlayer - setPlayState");
    
    @try {
        [self.player play];
        
        if(self.player.currentPlaybackTime > 0) {
            [self.eventProcessor trackEvent:PNVASTEvent_Resume];
        } else {
            [self.eventProcessor trackEvent:PNVASTEvent_Start];
        }
        
        [self startPlaybackTimer];
        [self invokeDidStartPlaying];
    } @catch (NSException *exception) {
        NSLog(@"PNVASTPlayer - Exception ocurred when starting playback: %@", exception);
        [self setState:PNVastPlayerState_IDLE];
    }
    
}

- (void)setPauseState
{
    NSLog(@"PNVastPlayer - setPauseState");
    
    @try {
        [self.player pause];
        [self.eventProcessor trackEvent:PNVASTEvent_Pause];
        [self invokeDidPause];
    } @catch (NSException *exception) {
        NSLog(@"PNVASTPlayer - Exception ocurred when pausig playback: %@", exception);
        [self setState:PNVastPlayerState_IDLE];
    }
}

#pragma mark - TIMERS -
#pragma mark Load timer

- (void)startLoadTimeoutTimer
{
    @synchronized (self) {
        [self stopLoadTimeoutTimer];
        if(self.loadTimeout == 0) {
            self.loadTimeout = kPNVASTPlayerDefaultLoadTimeout;
        }
        
        self.loadTimer = [NSTimer scheduledTimerWithTimeInterval:self.loadTimeout
                                                          target:self
                                                        selector:@selector(loadTimeoutFired)
                                                        userInfo:nil
                                                         repeats:NO];
    }
}

- (void)stopLoadTimeoutTimer
{
    [self.loadTimer invalidate];
    self.loadTimer = nil;
}

- (void)loadTimeoutFired
{
    [self close];
    NSError *error = [NSError errorWithDomain:@"VASTPlayer - video load timeout" code:0 userInfo:nil];
    [self invokeDidFailLoadingWithError:error];
}

#pragma mark Playback timer

- (void)startPlaybackTimer
{
    @synchronized (self) {
        [self stopPlaybackTimer];
        self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:kPNVASTPlayerDefaultPlaybackInterval
                                                             target:self
                                                            selector:@selector(playbackTick)
                                                           userInfo:nil
                                                            repeats:YES];
    }
}

- (void)stopPlaybackTimer
{
    [self.playbackTimer invalidate];
    self.playbackTimer = nil;
}

- (void)playbackTick
{
    // TODO: Hang test?
    
    CGFloat currentPlayedPercent = self.player.currentPlaybackTime / self.player.duration;
    
    // TODO: Update spin
    
    switch (self.playback) {
        case PNVastPlaybackState_FirstQuartile:
        {
            if (currentPlayedPercent>0.25f) {
                [self.eventProcessor trackEvent:PNVASTEvent_FirstQuartile];
                self.playback = PNVastPlaybackState_SecondQuartile;
            }
        }
        break;
        case PNVastPlaybackState_SecondQuartile:
        {
            if (currentPlayedPercent>0.50f) {
                [self.eventProcessor trackEvent:PNVASTEvent_Midpoint];
                self.playback = PNVastPlaybackState_ThirdQuartile;
            }
        }
        break;
        case PNVastPlaybackState_ThirdQuartile:
        {
            if (currentPlayedPercent>0.75f) {
                [self.eventProcessor trackEvent:PNVASTEvent_ThirdQuartile];
                self.playback = PNVastPlaybackState_FourthQuartile;
            }
        }
        break;
        default: break;
    }
}

#pragma mark - CALLBACKS -
#pragma mark PNVASTEventProcessorDelegate

- (void)eventProcessorDidTrackEvent:(PNVASTEvent)event
{
    NSLog(@"PNVastPlayer - event tracked: %ld", event);
}

@end
