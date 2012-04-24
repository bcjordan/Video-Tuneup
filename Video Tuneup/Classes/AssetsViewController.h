//
//  AssetsViewController.h
//  Video Tuneup
//
//  Created by tw on 4/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface AssetsViewController : UITableViewController {
    NSMutableArray *assets;
}

@property (nonatomic, retain) UIActivityIndicatorView *activity;
@property (nonatomic, retain) ALAssetsLibrary *library;

@end
