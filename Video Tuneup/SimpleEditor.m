
/*
     File: SimpleEditor.m
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

#import "SimpleEditor.h"

#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

@implementation SimpleEditor

- (id)init
{
	if (self = [super init]) {
		_songStartTime = CMTimeMake(0, 1); // Default start time for the song is two seconds.
		_videoStartTime = CMTimeMake(0, 1); // Default start time for the video is two seconds.
	}
	return self;
}

// Configuration

@synthesize video = _video, videoStartTime = _videoStartTime;
@synthesize song = _song, songStartTime = _songStartTime;

// Composition objects.

@synthesize composition = _composition;
@synthesize audioMix = _audioMix;
@synthesize playerItem = _playerItem;

- (void)addSongTrackToComposition:(AVMutableComposition *)composition withAudioMix:(AVMutableAudioMix *)audioMix
{
	NSInteger i;
	NSArray *tracksToDuck = [composition tracksWithMediaType:AVMediaTypeAudio]; // before we add the song
	
	// Clip song duration to composition duration.
	CMTimeRange songTimeRange = CMTimeRangeMake(self.songStartTime, self.song.duration);
	if (CMTIME_COMPARE_INLINE(CMTimeRangeGetEnd(songTimeRange), >, [composition duration]))
		songTimeRange.duration = CMTimeSubtract([composition duration], songTimeRange.start);
	
	// Add the song track.
	AVMutableCompositionTrack *compositionSongTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
	[compositionSongTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, songTimeRange.duration) ofTrack:[[self.song tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:songTimeRange.start error:nil];
	
	// Ramp tracks down and up at beginning and end.
	NSMutableArray *trackMixArray = [NSMutableArray array];
	CMTime rampDuration = CMTimeMake(1, 2); // half-second ramps
	for (i = 0; i < [tracksToDuck count]; i++) {
		AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:[tracksToDuck objectAtIndex:i]];
		[trackMix setVolumeRampFromStartVolume:1.0 toEndVolume:0.2 timeRange:CMTimeRangeMake(CMTimeSubtract(songTimeRange.start, rampDuration), rampDuration)];
		[trackMix setVolumeRampFromStartVolume:0.2 toEndVolume:1.0 timeRange:CMTimeRangeMake(CMTimeRangeGetEnd(songTimeRange), rampDuration)];
		[trackMixArray addObject:trackMix];
	}
	audioMix.inputParameters = trackMixArray;
}

- (void)addVideoTrackToComposition:(AVMutableComposition *)composition
{
    AVAssetTrack *videoTrack = nil;
    if ([[self.video tracksWithMediaType:AVMediaTypeVideo] count] > 0)
       videoTrack = [[self.video tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];

    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTimeRange videoTimeRange = CMTimeRangeMake(self.videoStartTime, self.video.duration);

    [compositionVideoTrack insertTimeRange:videoTimeRange ofTrack:videoTrack atTime:videoTimeRange.start error:nil];
}
- (void)addAudioTrackToComposition:(AVMutableComposition *)composition
{
    AVAssetTrack *audioTrack = nil;
    if ([[self.video tracksWithMediaType:AVMediaTypeAudio] count] > 0)
       audioTrack = [[self.video tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];

    AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTimeRange audioTimeRange = CMTimeRangeMake(self.videoStartTime, self.video.duration);

    [compositionAudioTrack insertTimeRange:audioTimeRange ofTrack:audioTrack atTime:audioTimeRange.start error:nil];
}

- (void)buildCompositionObjectsForPlayback:(BOOL)forPlayback
{
	AVMutableComposition *composition = [[AVMutableComposition alloc]init];
	AVMutableAudioMix *audioMix = nil;

	CGSize videoSize = [self.video naturalSize];
	composition.naturalSize = videoSize;

    if (self.video) {
        [self addVideoTrackToComposition:composition];
        [self addAudioTrackToComposition:composition];
    }

	if (self.song) {
		// Add the song track and duck all other audio during it.
		audioMix = [AVMutableAudioMix audioMix];
		[self addSongTrackToComposition:composition withAudioMix:audioMix];
	}

	self.composition = composition;
	self.audioMix = audioMix;

	if (forPlayback) {
#if TARGET_OS_EMBEDDED
		// Render high-def movies at half scale for real-time playback (device-only).
		if (videoSize.width > 640)
			composition.renderScale = 0.5;
#endif // TARGET_OS_EMBEDDED
		
		AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
//		playerItem.audioMix = audioMix;
		self.playerItem = playerItem;
	}
}

- (AVAssetImageGenerator*)assetImageGenerator
{
	AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.composition];
	return generator;
}

- (AVAssetExportSession*)assetExportSessionWithPreset:(NSString*)presetName
{
	AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:self.composition presetName:presetName];

//    session.videoComposition = self.videoComposition;
//	session.audioMix = self.audioMix;
    return session;
}

@end
