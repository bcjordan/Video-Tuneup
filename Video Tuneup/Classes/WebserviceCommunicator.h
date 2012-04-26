//
//  WebserviceCommunicator.h
//  Video Tuneup
//
//  Created by tw on 4/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WebserviceCommunicator : NSObject <NSURLConnectionDelegate>

@property (nonatomic, retain) NSFileHandle *fileHandle;

-(void)mixMusic:(NSURL *)file;

@end
