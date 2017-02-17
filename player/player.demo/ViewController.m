//
//  ViewController.m
//  player.demo
//
//  Created by David Martin on 16/02/2017.
//  Copyright © 2017 pubnative. All rights reserved.
//

#import "ViewController.h"
#import "PNVASTPlayerViewController.h"

@interface ViewController () <PNVASTPlayerViewControllerDelegate>

@property (nonatomic, strong) PNVASTPlayerViewController *player;

@end

@implementation ViewController

- (void)dealloc
{
    self.player = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSURL *vastURL = [NSURL URLWithString:@"https://dl.dropboxusercontent.com/u/2709335/test.vast"];
    self.player = [[PNVASTPlayerViewController alloc] init];
    self.player.delegate = self;
    [self.player loadWithVastUrl:vastURL];
} 


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)toogle:(id)sender {
    
    static BOOL playing = true;
    
    if(playing) {
        [self.player pause];
    } else {
        [self.player play];
    }
    playing = !playing;
}

- (IBAction)close:(id)sender {
    
    [self.player stop];
}

#pragma mark -CALLBACKS-
#pragma mark PNVASTPlayerViewControllerDelegate

- (void)vastPlayerDidFinishLoading:(PNVASTPlayerViewController*)vastPlayer
{
    NSLog(@"vastPlayerDidFinishLoading:");
    self.player.view.frame = CGRectMake(0, 0, 250, 180);
    [self.view addSubview:self.player.view];
    [self.player play];
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


@end
