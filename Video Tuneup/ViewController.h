//
//  ViewController.h
//  Video Tuneup
//
//  Created by Brian Jordan on 3/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "SimpleEditor.h"

@class PlayerView;

@interface ViewController : UIViewController {
    AVURLAsset *asset;
}

@property (nonatomic, retain) AVPlayer *player;
@property (nonatomic, retain) SimpleEditor *editor;
@property (retain) AVPlayerItem *playerItem;
@property (nonatomic, retain) IBOutlet PlayerView *playerView;
@property (nonatomic, retain) IBOutlet UIButton *playButton;
@property (nonatomic, retain) IBOutlet UIButton *pauseButton;
@property (nonatomic, retain) IBOutlet UIButton *rewindButton;

- (IBAction)loadAssetFromFile:sender;
- (IBAction)loadAudioFromFile:sender;
- (IBAction)play:sender;
- (IBAction)pause:sender;
- (IBAction)rewind:sender;
- (IBAction)edit:sender;
- (void)syncUI;

- (void)exportDidFinish:(AVAssetExportSession*)session;
@end