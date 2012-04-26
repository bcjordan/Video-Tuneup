//
//  AssetsViewController.h
//  Video Tuneup
//
//  Created by tw on 4/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ViewController.h"

@interface AssetsViewController : UITableViewController {
    NSMutableArray *assets;
    ViewController *_viewController;
}

@property (nonatomic, retain) UIActivityIndicatorView *activity;
@property (nonatomic, retain) ALAssetsLibrary *library;

- (void)setParentViewController:(ViewController *)viewController;

@end
