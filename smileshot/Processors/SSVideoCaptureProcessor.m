//
//  SSVideoCaptureProcessor.m
//  smileshot
//
//  Created by Jin Jin on 13-7-6.
//  Copyright (c) 2013年 Jin Jin. All rights reserved.
//

#import "SSVideoCaptureProcessor.h"
#import "AVImageUtil.h"
#import <CoreGraphics/CoreGraphics.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>

@interface SSVideoCaptureProcessor()

@property (nonatomic, strong) CIDetector* faceDetector;
@property (nonatomic, strong) CIContext* context;
@property (nonatomic, assign) dispatch_queue_t detectQueue;

@end

@implementation SSVideoCaptureProcessor

-(id)init{
    self = [super init];
    if (self){
        NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, [NSNumber numberWithBool:YES], CIDetectorTracking, nil];

        self.faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:self.context options:detectorOptions];
    }
    
    return self;
}

#pragma mark - delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
//    NSLog(@"start capture video output");
    BOOL hasFace = false;
    BOOL hasSmile = false;
    BOOL leftEyeBlink = false;
    BOOL rightEyeBlink =false;
    CGRect faceRect = CGRectZero;
    
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        
        // get the array of CIFeature instances in the given image with a orientation passed in
        // the detection will be done based on the orientation but the coordinates in the returned features will
        // still be based on those of the image.
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
        CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer
                                                          options:(__bridge NSDictionary *)attachments];
        if (attachments)
            CFRelease(attachments);
        
        NSMutableDictionary *imageOptions = [NSMutableDictionary dictionary];
        NSNumber *orientation = (__bridge NSNumber *)(CMGetAttachment(sampleBuffer, kCGImagePropertyOrientation, NULL));
        
        if (orientation) {
            [imageOptions setObject:orientation forKey:CIDetectorImageOrientation];
        }
        
        [imageOptions setObject:[NSNumber numberWithBool:YES] forKey:CIDetectorEyeBlink];
        [imageOptions setObject:[NSNumber numberWithBool:YES] forKey:CIDetectorSmile];
        
        NSArray *features = [self.faceDetector featuresInImage:ciImage options:imageOptions];
        for (CIFeature* feature in features){
            if ([feature.type isEqualToString:CIFeatureTypeFace]){
                CIFaceFeature* face = (CIFaceFeature*)feature;
                
                [self.delegate processor:self hasFace:YES hasSmile:face.hasSmile leftEyeBlink:face.leftEyeClosed rightEyeBlink:face.rightEyeClosed faceRect:face.bounds];
            }else{
                [self.delegate processor:self hasFace:NO hasSmile:NO leftEyeBlink:NO rightEyeBlink:NO faceRect:CGRectZero];
            }
        }
//        CGImageRef srcImage = NULL;
//        OSStatus err = CreateCGImageFromCVPixelBuffer(CMSampleBufferGetImageBuffer(imageDataSampleBuffer), &srcImage);
//        check(!err);
//        
//        CGImageRef cgImageResult = [self newSquareOverlayedImageForFeatures:features
//                                                                  inCGImage:srcImage
//                                                            withOrientation:curDeviceOrientation
//                                                                frontFacing:isUsingFrontFacingCamera];
//        if (srcImage)
//            CFRelease(srcImage);
//        
//        CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
//                                                                    imageDataSampleBuffer,
//                                                                    kCMAttachmentMode_ShouldPropagate);
//        [self writeCGImageToCameraRoll:cgImageResult withMetadata:(id)attachments];
//        if (attachments)
//            CFRelease(attachments);
//        if (cgImageResult)
//            CFRelease(cgImageResult);
        
    });
    
    [self.delegate processor:self hasFace:hasFace hasSmile:hasSmile leftEyeBlink:leftEyeBlink rightEyeBlink:rightEyeBlink faceRect:faceRect];
}

@end
