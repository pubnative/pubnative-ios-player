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

NSTimeInterval const kPNVASTPlayerViewControllerDefaultLoadTimeout = 10.0;

typedef enum : NSUInteger {
    
    PNVastPlayerState_IDLE,
    PNVastPlayerState_LOAD,
    PNVastPlayerState_READY,
    PNVastPlayerState_PLAY,
    PNVastPlayerState_PAUSE
}PNVastPlayerState;

@interface PNVASTPlayerViewController ()<PNVASTEventProcessorDelegate>

@property (nonatomic, assign) PNVastPlayerState         currentState;
@property (nonatomic, assign) NSTimeInterval            loadTimeout;
@property (nonatomic, assign) BOOL                      isFullScreen;
@property (nonatomic, strong) NSURL                     *vastUrl;
@property (nonatomic, strong) PNVASTModel               *vastModel;
@property (nonatomic, strong) PNVASTParser              *parser;
@property (nonatomic, strong) PNVASTEventProcessor      *eventProcessor;
@property (nonatomic, strong) MPMoviePlayerController   *player;
@property (nonatomic, strong) NSTimer                   *loadTimer;

@end

@implementation PNVASTPlayerViewController

- (void)loadView
{
    self.view = [[UIView alloc] init];
}

- (void)dealloc
{
    self.vastUrl = nil;
    self.vastModel = nil;
    self.parser = nil;
    self.eventProcessor = nil;
    [self removeObservers];
    [self stopVideoLoadTimeoutTimer];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Public methods -

- (void)close
{
    @synchronized (self) {
        [self removeObservers];
        [self stopVideoLoadTimeoutTimer];
        [self.player stop];
        self.player = nil;
    }
}

- (void)createVideoPlayerWithVideoUrl:(NSURL*)url
{
    if(self.player == nil) {
        self.player = [[MPMoviePlayerController alloc] initWithContentURL:url];
    }
    self.player.controlStyle = MPMovieControlStyleNone;
    self.player.shouldAutoplay = NO;
    self.player.fullscreen = self.isFullScreen;
    [self.player prepareToPlay];
}

- (void)setLoadTimeout:(NSTimeInterval)loadTimeout
{
    self.loadTimeout = loadTimeout;
}

- (void)loadWithVastUrl:(NSURL*)url
{
    self.vastUrl = url;
    if (url == nil) {
        NSLog(@"PNVastPlayer - cannot load, invalid state");
    } else if (![self setState:PNVastPlayerState_LOAD]) {
        NSLog(@"PNVastPlayer - cannot load, invalid state");
    } 
}

#pragma mark - Delegate helpers -

- (void)invokeDidFinishLoading
{
    [self stopVideoLoadTimeoutTimer];
    if([self.delegate respondsToSelector:@selector(vastPlayerDidFinishLoading:)]) {
        [self.delegate vastPlayerDidFinishLoading:self];
    }
    [self setState:PNVastPlayerState_READY];
}

- (void)invokeDidFailLoadingWithError:(NSError*)error
{
    [self stopVideoLoadTimeoutTimer];
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

#pragma mark - MPMoviePlayer notifications -

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
                                             selector:@selector(plaerMoviePlayBackDidFinish:)
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
    
}

- (void)plaerMoviePlayBackDidFinish:(NSNotification*)notification
{
    
}

- (void)playerPlaybackStateDidChangeNotification:(NSNotification*)notification
{
    
}

- (void)playerLoadStateDidChanged:(NSNotification*)notification
{
    if (self.player.loadState == MPMovieLoadStatePlaythroughOK)
    {
        [self invokeDidFinishLoading];
    }
}

- (void)playerSourceTypeAvailable:(NSNotification*)notification
{
    
}

#pragma mark - State Machine -

- (BOOL)canGoToState:(PNVastPlayerState)state
{
    BOOL result = NO;
    
    switch (self.currentState) {
        case PNVastPlayerState_IDLE:    result = YES; break;
        case PNVastPlayerState_LOAD:    result = (state == PNVastPlayerState_IDLE
                                                  && self.vastUrl != nil); break;
        case PNVastPlayerState_READY: {
            result = (state == PNVastPlayerState_LOAD       // LOADED
                      || state == PNVastPlayerState_PLAY    // STOP
                      || state == PNVastPlayerState_PAUSE); // STOP
        }
        break;
        case PNVastPlayerState_PLAY:    result = state == PNVastPlayerState_READY; break;
        case PNVastPlayerState_PAUSE:   result = state == PNVastPlayerState_PLAY; break;
        default: break;
    }
    
    return result;
}

- (BOOL)setState:(PNVastPlayerState)state
{
    BOOL result = NO;
    if ([self canGoToState:state]) {
        result = YES;
        switch (state) {
            case PNVastPlayerState_IDLE:    [self setIdleState];    break;
            case PNVastPlayerState_LOAD:    [self setLoadState];    break;
            case PNVastPlayerState_READY:   [self setReadyState];   break;
            case PNVastPlayerState_PLAY:    [self setPlayState];    break;
            case PNVastPlayerState_PAUSE:   [self setPauseState];   break;
        }
        self.currentState = state;
    }
    return result;
}

- (void)setIdleState
{
    NSLog(@"PNVastPlayer - setIdleState");
    // CLEAN EVERYTHING
    [self removeObservers];
    [self addObservers];
}

- (void)setLoadState
{
    NSLog(@"PNVastPlayer - setLoadState");
    
    if (self.parser == nil) {
        self.parser = [[PNVASTParser alloc] init];
    }
    
    [self startVideoLoadTimeoutTimer];
    
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
}

- (void)setPlayState
{
    NSLog(@"PNVastPlayer - setPlayState");
    // ALL CODE HERE
    [self invokeDidStartPlaying];
}

- (void)setPauseState
{
    NSLog(@"PNVastPlayer - setPauseState");
    // ALL CODE HERE
    [self invokeDidPause];
}

#pragma mark - Timers -

- (void)startVideoLoadTimeoutTimer
{
    if(self.loadTimeout == 0) {
        self.loadTimeout = kPNVASTPlayerViewControllerDefaultLoadTimeout;
    }
    
    self.loadTimer = [NSTimer scheduledTimerWithTimeInterval:self.loadTimeout
                                                      target:self
                                                    selector:@selector(loadTimeoutFired)
                                                    userInfo:nil
                                                     repeats:NO];
}

- (void)stopVideoLoadTimeoutTimer
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

#pragma mark -CALLBACKS-
#pragma mark PNVASTEventProcessorDelegate

- (void)eventProcessorDidTrackEvent:(PNVASTEvent)event
{
    NSLog(@"PNVastPlayer - event tracked: %ld", event);
}

@end
