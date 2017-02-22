//
//  ViewController.m
//  player.demo
//
//  Created by David Martin on 16/02/2017.
//  Copyright © 2017 pubnative. All rights reserved.
//

#import "ViewController.h"
#import "PNVASTPlayerViewController.h"

NSString * const kDefaultVASTURL = @"https://dl.dropboxusercontent.com/u/2709335/test.vast";

@interface ViewController () <PNVASTPlayerViewControllerDelegate>

@property (nonatomic, strong) PNVASTPlayerViewController *player;
@property (weak, nonatomic) IBOutlet UIButton *btnToggle;
@property (weak, nonatomic) IBOutlet UIView *videoContainer;
@property (weak, nonatomic) IBOutlet UITextField *textViewURL;

@end

@implementation ViewController

- (void)dealloc
{
    self.player = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.player = [[PNVASTPlayerViewController alloc] init];
    self.player.delegate = self;
    self.textViewURL.text = kDefaultVASTURL;
}

static BOOL playing = NO;

- (IBAction)toogle:(id)sender {
    
    if(playing) {
        [self setTogglePlay];
        [self.player pause];
    } else {
        [self setTogglePause];
        [self.player play];
    }
    playing = !playing;
}

- (void)setTogglePlay
{
    [self.btnToggle setTitle:@"play" forState:UIControlStateNormal];
}

- (void)setTogglePause
{
    [self.btnToggle setTitle:@"pause" forState:UIControlStateNormal];
}

- (IBAction)close:(id)sender {
    
    [self.player stop];
}

- (IBAction)loadPushed:(id)sender {
    
    [self.player stop];
    [self.player.view removeFromSuperview];
    
    if(self.textViewURL.text != nil) {
        NSURL *url = [NSURL URLWithString:self.textViewURL.text];
        [self.player loadWithVastUrl:url];
        self.player.view.frame = self.videoContainer.bounds;
        [self.videoContainer addSubview:self.player.view];
    }
}

#pragma mark -CALLBACKS-
#pragma mark PNVASTPlayerViewControllerDelegate

- (void)vastPlayerDidFinishLoading:(PNVASTPlayerViewController*)vastPlayer
{
    NSLog(@"vastPlayerDidFinishLoading:");
}

- (void)vastPlayer:(PNVASTPlayerViewController*)vastPlayer didFailLoadingWithError:(NSError*)error
{
    NSLog(@"vastPlayer:didFailLoadingWithError:");
}

- (void)vastPlayerDidStartPlaying:(PNVASTPlayerViewController*)vastPlayer
{
    NSLog(@"vastPlayerDidStartPlaying:");
}

- (void)vastPlayerDidPause:(PNVASTPlayerViewController*)vastPlayer
{
    NSLog(@"vastPlayerDidPause:");
}

-(void)vastPlayerDidComplete:(PNVASTPlayerViewController *)vastPlayer
{
    NSLog(@"vastPlayerDidComplete:");
    playing = NO;
    [self setTogglePlay];
}


@end
