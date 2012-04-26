//
//  WebserviceCommunicator.m
//  Video Tuneup
//
//  Created by tw on 4/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WebserviceCommunicator.h"

#define BASEPATH (@"http://localhost:4567")

@implementation WebserviceCommunicator

@synthesize fileHandle, songPath;

- (id)init {
    self = [super init];
    if (self) {
        songPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"mixed_song.mp3"];
        [[NSFileManager defaultManager] createFileAtPath:songPath contents:nil attributes:nil];
        fileHandle = [NSFileHandle fileHandleForWritingAtPath:songPath];
    }
    return self;
}

-(void)mixMusic:(NSURL *)file {
    NSString *uploadFileName = [file lastPathComponent];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/blend/%@", BASEPATH, uploadFileName]] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:130.0]; // BASEPATH/blend/:filename
    [request setHTTPMethod:@"POST"];
    [request setHTTPShouldHandleCookies:NO];
    NSString *boundary = @"--x-x-x-x-";
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
    
    NSData *songData = [NSData dataWithContentsOfURL:file];
    NSMutableData *requestData = [[NSMutableData alloc] init];
    
//  To send extra params:
//
//  for (NSString *paramName in params) ...
//	[body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
//	[body appendData:[@"Content-Disposition: form-data; name=\"photo-description\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
//	[body appendData:[@"testing 123" dataUsingEncoding:NSUTF8StringEncoding]];
//    [body appendData:[[NSString stringWithFormat:@"%@\r\n", [_params objectForKey:param]] dataUsingEncoding:NSUTF8StringEncoding]];
	
    [requestData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[requestData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", @"data", uploadFileName] dataUsingEncoding:NSUTF8StringEncoding]];
	[requestData appendData:[@"Content-Type: audio/mpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[requestData appendData:songData];
    [requestData appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [requestData appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
	[request setHTTPBody:requestData];
    
    (void)[[NSURLConnection alloc] initWithRequest:request delegate:self];
}


- (void)setParentController:(ViewController *)viewController {
    _viewController = viewController;
}


#pragma mark NSURLConnection delegate methods

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	NSLog(@"Got response data");
    
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSLog(@"Song send failed");
    if(_viewController != nil) {
        [_viewController.internetRequestButton setTitle:@"Internet Tune-up (failed)" forState:UIControlStateNormal];
    }
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSLog(@"Song send finished loading.");

    [fileHandle closeFile];
    if(_viewController != nil) {
        [_viewController.internetRequestButton setTitle:@"Internet Tune-up (failed)" forState:UIControlStateNormal];
    }
    
    // This is happening before file is completely sent back. Need to change timeout.

    NSLog(@"Received song path is %@", songPath);
//    [_viewController loadAudioFromFile:[NSURL URLWithString:songPath]];
}

@end
