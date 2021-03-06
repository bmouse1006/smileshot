//
//  SSMainViewController.h
//  smileshot
//
//  Created by Jin Jin on 13-7-6.
//  Copyright (c) 2013年 Jin Jin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "SSVideoCaptureProcessor.h"

@interface SSMainViewController : UIViewController<SSVideoCaptureProcessorDelegate>

@property (nonatomic, strong) IBOutlet UIView* previewView;

@end
