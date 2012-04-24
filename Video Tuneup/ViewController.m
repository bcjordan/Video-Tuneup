//
//  ViewController.m
//  Video Tuneup
//
//  Created by Brian Jordan on 3/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "PlayerView.h"
#import "SimpleEditor.h"
#import "AssetsViewController.h"

// Define this constant for the key-value observation context.
static const NSString *ItemStatusContext;

@implementation ViewController

@synthesize player, playerItem, playerView, playButton, pauseButton, rewindButton, editor, videoNavBar, exportStatus,
mScrubber, mediaLibraryButton, mediaLibraryPopover;

#pragma mark - Video playback

- (void)syncUI {
    NSLog(@"syncUI");

    if ((player.currentItem != nil) &&
            ([player.currentItem status] == AVPlayerItemStatusReadyToPlay &&
                    CMTimeCompare([player.currentItem duration], kCMTimeZero) != 0)) {
        playButton.enabled = YES;

        NSLog(@"Enabling play button");
    }
    else {
        playButton.enabled = NO;
        NSLog(@"Play button disabled");
    }
}

- (void)refreshEditor {
    NSLog(@"Refreshing editor");
    
    // Update editor assets
    if (asset)
        self.editor.video = asset;
    if (songAsset)
        self.editor.song = songAsset;

    // Remove old player
    [self.player pause];
    
    // Build composition for playback
    [self.editor buildNewCompositionForPlayback:YES];

    // Initialize editor's player
    self.playerItem = self.editor.playerItem;
    [playerItem addObserver:self forKeyPath:@"status"
                    options:0 context:&ItemStatusContext];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    [playerView setPlayer:self.player];
    
    [self play:nil];
}

- (IBAction)loadAssetFromFile:sender {
    NSLog(@"Loading asset.");

    NSURL *fileURL = [[NSBundle mainBundle]
            URLForResource:@"sample_iPod" withExtension:@"m4v"];
    asset = [AVURLAsset URLAssetWithURL:fileURL options:nil];

    NSLog(@"Asset duration is %f", CMTimeGetSeconds([asset duration]));

    NSString *tracksKey = @"tracks";

    [asset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:tracksKey] completionHandler:
            ^{
                NSLog(@"Handler block reached");
                // Completion handler block.
                dispatch_async(dispatch_get_main_queue(),
                        ^{
                            NSError *error = nil;
                            AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];

                            if (status == AVKeyValueStatusLoaded) {
                                [self refreshEditor];

                                // File has loaded into player
                                NSLog(@"File loaded!");
                                NSLog(@"Asset duration is %f", CMTimeGetSeconds([asset duration]));

                            }
                            else {
                                // You should deal with the error appropriately.
                                NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
                            }
                        });
            }];
}

- (IBAction)loadAudioFromFile:(id)sender {
    NSURL *songFileURL = [[NSBundle mainBundle]
            URLForResource:@"song" withExtension:@"mp3"];
    songAsset = [AVURLAsset URLAssetWithURL:songFileURL options:nil];
    NSLog(@"Song asset duration is %f", CMTimeGetSeconds([songAsset duration]));

    NSLog(@"Refreshing editor");
    [self refreshEditor];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {

    if (context == &ItemStatusContext) {
        // Have to dispatch to main thread queue for UI operations
        dispatch_async(dispatch_get_main_queue(),
                ^{
                    [self syncUI];
                });
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object
                           change:change context:context];
    return;
}

- (IBAction)play:(id)sender {

    if(player.rate == 0 && (player.currentItem != nil) &&
                ([player.currentItem status] == AVPlayerItemStatusReadyToPlay &&
                        CMTimeCompare([player.currentItem duration], kCMTimeZero) != 0)) { // Paused
        NSLog(@"Playing item");
        [player play];
        [self initScrubberTimer];
        [self.videoNavBar setItems:[NSArray
                              arrayWithObjects:[self.videoNavBar.items objectAtIndex:0],
                                                   [self.videoNavBar.items objectAtIndex:1],
                                                   [self.videoNavBar.items objectAtIndex:2],
                              [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(play:)],[self.videoNavBar.items objectAtIndex:4],[self.videoNavBar.items objectAtIndex:5],nil] animated:NO];

    } else {
        [player pause];
        [self.videoNavBar setItems:[NSArray arrayWithObjects:[self.videoNavBar.items objectAtIndex:0],
                                                            [self.videoNavBar.items objectAtIndex:1],
                                                            [self.videoNavBar.items objectAtIndex:2],
                                           [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(play:)],[self.videoNavBar.items objectAtIndex:4],
                                    [self.videoNavBar.items objectAtIndex:5], nil] animated:NO];
    }
}

- (IBAction)pause:(id)sender {
    NSLog(@"Pausing...");

    [player pause];
}

- (IBAction)rewind:(id)sender {
    [player seekToTime:kCMTimeZero];
}


// Handle scrubbing
// Based on sample code from http://developer.apple.com/library/ios/#samplecode/AVPlayerDemo/Listings/Classes_AVPlayerDemoPlaybackViewController_m.html#//apple_ref/doc/uid/DTS40010101-Classes_AVPlayerDemoPlaybackViewController_m-DontLinkElementID_8

#pragma mark -
#pragma mark Movie scrubber control

/* ---------------------------------------------------------
 **  Methods to handle manipulation of the movie scrubber control
 ** ------------------------------------------------------- */

- (CMTime)playerItemDuration
{
    return [playerItem duration];
}

/* Requests invocation of a given block during media playback to update the movie scrubber control. */
-(void)initScrubberTimer
{
    double interval = .1f;  
    
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) 
    {
        return;
    } 
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration))
    {
        CGFloat width = CGRectGetWidth([mScrubber bounds]);
        interval = 0.5f * duration / width;
    }
    
    /* Update the scrubber during normal playback. */
    mTimeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC) 
                                                           queue:NULL /* If you pass NULL, the main queue is used. */
                                                      usingBlock:^(CMTime time) 
                      {
                          [self syncScrubber];
                      }];
    
}

/* Set the scrubber based on the player current time. */
- (void)syncScrubber
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) 
    {
        mScrubber.minimumValue = 0.0;
        return;
    } 
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration))
    {
        float minValue = [mScrubber minimumValue];
        float maxValue = [mScrubber maximumValue];
        double time = CMTimeGetSeconds([player currentTime]);
        
        [mScrubber setValue:(maxValue - minValue) * time / duration + minValue];
    }
}

/* The user is dragging the movie controller thumb to scrub through the movie. */
- (IBAction)beginScrubbing:(id)sender
{
    mRestoreAfterScrubbingRate = [player rate];
    [player setRate:0.f];
    
    /* Remove previous timer. */
//    [self removePlayerTimeObserver];
}

/* Set the player current time to match the scrubber position. */
- (IBAction)scrub:(id)sender
{
    if ([sender isKindOfClass:[UISlider class]])
    {
        UISlider* slider = sender;
        
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration)) {
            return;
        } 
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration))
        {
            float minValue = [slider minimumValue];
            float maxValue = [slider maximumValue];
            float value = [slider value];
            
            double time = duration * (value - minValue) / (maxValue - minValue);
            
            [player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
        }
    }
}

/* The user has released the movie thumb control to stop scrubbing through the movie. */
- (IBAction)endScrubbing:(id)sender
{
    if (!mTimeObserver)
    {
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration)) 
        {
            return;
        } 
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration))
        {
            CGFloat width = CGRectGetWidth([mScrubber bounds]);
            double tolerance = 0.5f * duration / width;
            
            mTimeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC) queue:NULL usingBlock:
                              ^(CMTime time)
                              {
                                  [self syncScrubber];
                              }];
        }
    }
    
    if (mRestoreAfterScrubbingRate)
    {
        [player setRate:mRestoreAfterScrubbingRate];
        mRestoreAfterScrubbingRate = 0.f;
    }
}

- (BOOL)isScrubbing
{
    return mRestoreAfterScrubbingRate != 0.f;
}

-(void)enableScrubber
{
    self.mScrubber.enabled = YES;
}

-(void)disableScrubber
{
    self.mScrubber.enabled = NO;    
}


- (IBAction)exportToCameraRoll:(id)sender {

    NSLog(@"Editing...");

    NSLog(@"Put clips in. Build.");
    AVAssetExportSession *session = [self.editor assetExportSessionWithPreset:AVAssetExportPresetHighestQuality];
    NSLog(@"Session");

    NSLog(@"begin export");
    NSString *filePath = nil;
    NSUInteger count = 0;
    do {
        NSLog(@"Filepath");
        filePath = NSTemporaryDirectory();

        NSString *numberString = count > 0 ? [NSString stringWithFormat:@"-%i", count] : @"";
        filePath = [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"Output-%@.mov", numberString]];
        count++;
    } while ([[NSFileManager defaultManager] fileExistsAtPath:filePath]);

    NSLog(@"Setting stuff.");

    session.outputURL = [NSURL fileURLWithPath:filePath];
    session.outputFileType = AVFileTypeQuickTimeMovie;

    [session exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Finished exporting.");
            [self exportDidFinish:session];
        });
    }];
}

- (void)exportDidFinish:(AVAssetExportSession *)session {
    NSLog(@"Finished export, attempting photo album");

    NSURL *outputURL = session.outputURL;

//	_exporting = NO;
//	NSIndexPath *exportCellIndexPath = [NSIndexPath indexPathForRow:2 inSection:kProjectSection];
//	ExportCell *cell = (ExportCell*)[self.tableView cellForRowAtIndexPath:exportCellIndexPath];
//	cell.progressView.progress = 1.0;
//	[cell setProgressViewHidden:YES animated:YES];
//	[self updateCell:cell forRowAtIndexPath:exportCellIndexPath];

    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
        [library writeVideoAtPathToSavedPhotosAlbum:outputURL
                                    completionBlock:^(NSURL *assetURL, NSError *error) {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            if (error) {
                                                NSLog(@"writeVideoToAssestsLibrary failed: %@", error);
                                                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                                                                    message:[error localizedRecoverySuggestion]
                                                                                                   delegate:nil cancelButtonTitle:@"OK"
                                                                                          otherButtonTitles:nil];
                                                [alertView show];
//												[alertView release];
                                                [exportStatus setText:@"Camera Roll Export Error"];
                                            }
                                            else {
                                                NSLog(@"Completed photo album add");

                                                [exportStatus setTextColor:[UIColor colorWithRed:255.0 green:255.0 blue:255.0 alpha:255.0]];
                                                [exportStatus setText:@"Exported to Camera Roll"];
                                                [exportStatus setBackgroundColor:[[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"argyle.png"]]];
//                                                [exportStatus setBackgroundColor:[UIColor colorWithRed:0.0 green:200.0 blue:0.0 alpha:255.0]];

												[self performSelector:@selector(hideCameraRollText) withObject:nil afterDelay:5.0];
                                            }
                                        });

                                    }];
    } else {
        NSLog(@"Video format is not compatible with saved photos album.");
        [exportStatus setTextColor:[UIColor colorWithRed:255.0 green:255.0 blue:255.0 alpha:255.0]];
        [exportStatus setText:@"Select a video first."];
        [exportStatus setBackgroundColor:[[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"argyle.png"]]];
        [self performSelector:@selector(hideCameraRollText) withObject:nil afterDelay:5.0];
    }
}

- (void)hideCameraRollText { [exportStatus setText: @""]; [exportStatus setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0]];}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [player seekToTime:kCMTimeZero];
    [player play]; // loop player. If not doing this, set button to pause
}

#pragma mark - Media Library

- (IBAction)showMediaLibrary:(id)sender {
    // http://stackoverflow.com/questions/2469523/mpmediapickercontroller-for-selecting-video-files#answer-3212470
    
    UIButton *theButton = (UIButton *)sender;
    AssetsViewController *avc = [[AssetsViewController alloc] initWithStyle:UITableViewStylePlain];
    
    mediaLibraryPopover = [[UIPopoverController alloc] initWithContentViewController:avc];
//    [mediaLibraryPopover setPopoverContentSize:<#(CGSize)#>// Change size of popover so that it doesn't take up the whole height
    [self.mediaLibraryPopover presentPopoverFromRect:[theButton bounds] inView:theButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

#pragma mark - View controller boilerplate

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"hixs_pattern_evolution.png"]];


    NSLog(@"viewDidLoad");

    // Initialize editor
    self.editor = [[SimpleEditor alloc] init];

    [self refreshEditor]; // Generate composition

    // Sync video player controls
    NSLog(@"syncUI");
    [self syncUI];

    // Register with the notification center after creating the player item.
    [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(playerItemDidReachEnd:)
                   name:AVPlayerItemDidPlayToEndTimeNotification
                 object:[player currentItem]];

    NSLog(@"registered");
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
