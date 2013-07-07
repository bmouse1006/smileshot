//
//  SSVideoCaptureProcessor.h
//  smileshot
//
//  Created by Jin Jin on 13-7-6.
//  Copyright (c) 2013年 Jin Jin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class SSVideoCaptureProcessor;

@protocol SSVideoCaptureProcessorDelegate <NSObject>

-(void)processor:(SSVideoCaptureProcessor*)processor hasFace:(BOOL)hasFace hasSmile:(BOOL)hasSmile leftEyeBlink:(BOOL)leftEyeBlink rightEyeBlink:(BOOL)rightEyeBlink faceRect:(CGRect)faceRect;

@end

@interface SSVideoCaptureProcessor : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, weak) id<SSVideoCaptureProcessorDelegate> delegate;

@end
