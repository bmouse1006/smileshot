//
//  AVImageUtil.h
//  smileshot
//
//  Created by Jin Jin on 13-7-6.
//  Copyright (c) 2013年 Jin Jin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>
#import <CoreMedia/CoreMedia.h>

@interface AVImageUtil : NSObject

+(CIImage*)ciImageFromCMSmapleBuffer:(CMSampleBufferRef*)bufferRef;

@end

#pragma mark-

@interface UIImage (RotationMethods)

- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees;

@end