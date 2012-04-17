
/*
     File: SimpleEditor.h
 Abstract: Demonstrates construction of AVComposition, AVAudioMix, and AVVideoComposition. 
 
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CMTime.h>

@interface SimpleEditor : NSObject 
{	
    // Assets

    AVURLAsset *_video;
    
	CMTime _videoStartTime;
    
	AVURLAsset *_song;
	CMTime _songStartTime;

	// Composition objects

	AVComposition *_composition;
	AVVideoComposition *_videoComposition;
	AVAudioMix *_audioMix;
	
	AVPlayerItem *_playerItem; // Reference to player of work-in-progress
}

// Set these properties before building the composition objects.

@property (nonatomic, retain) AVURLAsset *video;
@property (nonatomic) CMTime videoStartTime;

@property (nonatomic, retain) AVURLAsset *song;
@property (nonatomic) CMTime songStartTime;

// Build the composition, videoComposition, and audioMix.
// If the composition is being built for playback then a player item is also constructed.
// All of these objects can be retrieved all of these objects with the accessors below.
// Calling buildCompositionObjectsForPlayback: will get rid of any previously created composition objects.
- (void)buildNewCompositionForPlayback:(BOOL)forPlayback;

@property (nonatomic, retain) AVComposition *composition;
@property (nonatomic, readwrite, retain) AVVideoComposition *videoComposition;
@property (nonatomic, readwrite, retain) AVAudioMix *audioMix;
@property (nonatomic, readwrite, retain) AVPlayerItem *playerItem;

- (AVAssetExportSession*)assetExportSessionWithPreset:(NSString*)presetName;

@end
