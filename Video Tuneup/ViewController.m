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

// Define this constant for the key-value observation context.
static const NSString *ItemStatusContext;

@implementation ViewController

@synthesize player, playerItem, playerView, playButton, pauseButton, rewindButton, editor;

#pragma mark - Video playback

- (void)syncUI {
    NSLog(@"syncUI");
    
    if ((player.currentItem != nil) &&
        ([player.currentItem status] == AVPlayerItemStatusReadyToPlay)) {
        playButton.enabled = YES;
        NSLog(@"Enabling play button");

    }
    else {
        playButton.enabled = NO;
        NSLog(@"Play button disabled");
    }
    
}

- (IBAction)loadAssetFromFile:sender {
    NSLog(@"Loading asset.");    

    NSURL *fileURL = [[NSBundle mainBundle]
                      URLForResource:@"airplane" withExtension:@"m4v"];
    
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
                                self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                                [playerItem addObserver:self forKeyPath:@"status"
                                                options:0 context:&ItemStatusContext];
                                [[NSNotificationCenter defaultCenter] addObserver:self
                                                                         selector:@selector(playerItemDidReachEnd:)
                                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                                           object:playerItem];
                                self.player = [AVPlayer playerWithPlayerItem:playerItem];
                                [playerView setPlayer:player];

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
    NSLog(@"Loading audio from file [NOT YET IMPLEMENTED]");
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

- (IBAction)play:sender {
    [player play];
}

- (IBAction)pause:sender {
    NSLog(@"Pausing...");
    
    [player pause];
}

- (IBAction)rewind:sender {
    [player seekToTime:kCMTimeZero];
}

- (IBAction)edit:sender {

    NSLog(@"Editing...");
    
    // Initialize video editor
    self.editor = [[SimpleEditor alloc] init];    
    
    NSMutableArray *clips = [NSMutableArray arrayWithCapacity:3];
    
    if(asset) {
        [clips addObject:asset];
        [clips addObject:asset];
        [clips addObject:asset];
    } else {NSLog(@"Error! No Asset!"); return;}
    
    // Copy clips into editor
//    self.editor.clips = [clips copy];
    self.editor.clips = clips;

    NSLog(@"Put clips in. Count is %i", [clips count]);
    
    // Begin export
    [self.editor buildCompositionObjectsForPlayback:NO];
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
	} while([[NSFileManager defaultManager] fileExistsAtPath:filePath]);      

    NSLog(@"Setting stuff.");
	
	session.outputURL = [NSURL fileURLWithPath:filePath];
	session.outputFileType = AVFileTypeQuickTimeMovie;

    NSLog(@"Exporting asynchronously %i.", [clips count]);
    
	[session exportAsynchronouslyWithCompletionHandler:^
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             NSLog(@"Finished exporting.");
             [self exportDidFinish:session];
         });
     }];
}

- (void)exportDidFinish:(AVAssetExportSession*)session
{
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
									completionBlock:^(NSURL *assetURL, NSError *error){
										dispatch_async(dispatch_get_main_queue(), ^{
											if (error) {
												NSLog(@"writeVideoToAssestsLibrary failed: %@", error);
												UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
																									message:[error localizedRecoverySuggestion]
																								   delegate:nil
																						  cancelButtonTitle:@"OK"
																						  otherButtonTitles:nil];
												[alertView show];
//												[alertView release];
											}
											else {
                                                NSLog(@"Completed photo album add");
//												_showSavedVideoToAssestsLibrary = YES;
//												ExportCell *cell = (ExportCell*)[self.tableView cellForRowAtIndexPath:exportCellIndexPath];
//												[cell setDetailTextLabelHidden:NO animated:YES];
//												[self updateCell:cell forRowAtIndexPath:exportCellIndexPath];
//												NSArray *modes = [[[NSArray alloc] initWithObjects:NSDefaultRunLoopMode, UITrackingRunLoopMode, nil] autorelease];
//												[self performSelector:@selector(hideCameraRollText) withObject:nil afterDelay:5.0 inModes:modes];
											}
										});
										
									}];
	} else {
        NSLog(@"Video format is not compatible with saved photos album.");
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [player seekToTime:kCMTimeZero];
}


#pragma mark - View controller boilerplate

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"viewDidLoad");
    
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

	// Do any additional setup after loading the view, typically from a nib.
    // http://mobileorchard.com/easy-audio-playback-with-avaudioplayer/
    
//    NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/airplane.m4v", [[NSBundle mainBundle] resourcePath]]];
    // http://developer.apple.com/library/ios/#DOCUMENTATION/AudioVideo/Conceptual/AVFoundationPG/Articles/02_Playback.html#//apple_ref/doc/uid/TP40010188-CH3-SW2
    
    //    Create an asset using AVURLAsset and load its tracks using loadValuesAsynchronouslyForKeys:completionHandler:.  
    //    When the asset has loaded its tracks, create an instance of AVPlayerItem using the asset.
    //    Associate the item with an instance of AVPlayer.
    //    Wait until the item’s status indicates that it’s ready to play (typically you use key-value observing to receive a notification when the status changes).
    
    // Put video in supporting files
    
    // Get URL of video
    
    // Load video into player?
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
