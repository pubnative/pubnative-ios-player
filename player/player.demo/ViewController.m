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
