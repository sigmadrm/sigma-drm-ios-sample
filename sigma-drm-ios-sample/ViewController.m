//
//  ViewController.m
//  sigma-drm-ios-sample
//
//  Created by NguyenVanSao on 11/25/20.
//  Copyright © 2020 NguyenVanSao. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <sigma-drm-ios/SigmaDRM.h>
#import "ViewController.h"
#import "APLPlayerView.h"

@interface ViewController () <SigmaDRMDelegate>
@property (nonatomic, copy) NSURL* URL;
@property (readwrite, retain, setter=setPlayer:, getter=player) AVPlayer* player;
@property (retain) AVPlayerItem* playerItem;
@property (retain, nonatomic) IBOutlet APLPlayerView *playView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [self initializeView];
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (void) initializeView
{
    NSURL *URL = [self setupSigma];
    if (URL)
    {
        [self setURL:URL];
    }
}
-(NSURL *)setupSigma
{
    [[SigmaDRM getInstance] setAppId:@"RedTV"];
    [[SigmaDRM getInstance] setMerchantId:@"sctv"];
    [[SigmaDRM getInstance] setSessionId:@"iphone5s"];
    [[SigmaDRM getInstance] setSigmaUid:@"demo-iphone-5s-user"];
    [[SigmaDRM getInstance] setDelegate:self];
    
    NSURL *URL = [NSURL URLWithString:@"http://123.30.235.196:5535/live_staging/vtv1_720.stream/playlist.m3u8"];
    return URL;
}
- (void) setURL:(NSURL*)URL
{
    if ([self URL] != URL)
    {
        self->_URL = [URL copy];
        AVURLAsset *asset = [[SigmaDRM getInstance] assetWithUrl: URL.absoluteString];
        [self prepareToPlayAsset:asset withKeys:nil];
    }
}
- (void) prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
    for (NSString *thisKey in requestedKeys)
    {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed)
        {
            [self assetFailedToPrepareForPlayback:error];
            return;
        }
    }
    
    if (!asset.playable)
    {
        NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
        NSString *localizedFailureReason = NSLocalizedString(@"The contents of the resource at the specified URL are not playable.", @"Item cannot be played failure reason");
        NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   localizedDescription, NSLocalizedDescriptionKey,
                                   localizedFailureReason, NSLocalizedFailureReasonErrorKey,
                                   nil];
        NSError *assetCannotBePlayedError = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:0 userInfo:errorDict];
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        
        return;
    }
    if (self.playerItem)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.playerItem];
    }
    
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    [self.playerItem addObserver:self
                       forKeyPath:@"status"
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:nil];
    if (!self.player)
    {
        [self setPlayer:[AVPlayer playerWithPlayerItem:self.playerItem]];
    }
    
    if (self.player.currentItem != self.playerItem)
    {
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    }
    [self.playView setPlayer:self.player];
    [self.playView setVideoFillMode:AVLayerVideoGravityResizeAspect];
}
-(void) assetFailedToPrepareForPlayback:(NSError *)error
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                        message:[error localizedFailureReason]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}
- (void) observeValueForKeyPath:(NSString*) path ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
    switch (status)
    {
        case AVPlayerStatusUnknown:
        break;
        case AVPlayerStatusReadyToPlay:
        [self.player play];
        break;
        case AVPlayerStatusFailed:
        {
            AVPlayerItem *pItem = (AVPlayerItem *)object;
            [self assetFailedToPrepareForPlayback:pItem.error];
        }
        break;
    }
}
-(void)onProgressLoad:(NSString *)progressName status:(NSString *)error;
{
    NSLog(@"SigmaDRM: %@ - %@", progressName, error);
}
@end
