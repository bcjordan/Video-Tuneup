//
//  WebserviceCommunicator.h
//  Video Tuneup
//
//  Created by tw on 4/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ViewController.h"

@interface WebserviceCommunicator : NSObject <NSURLConnectionDelegate>{
    ViewController* _viewController;
}

@property (nonatomic, retain) NSFileHandle *fileHandle;
@property (nonatomic, retain) NSString *songPath;

-(void)mixMusic:(NSURL *)file;
-(void)setParentController:(ViewController *)viewController;

@end
