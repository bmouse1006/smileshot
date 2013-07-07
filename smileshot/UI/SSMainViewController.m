//
//  SSMainViewController.m
//  smileshot
//
//  Created by Jin Jin on 13-7-6.
//  Copyright (c) 2013年 Jin Jin. All rights reserved.
//

#import "SSMainViewController.h"

static const NSString *AVCaptureStillImageIsCapturingStillImageContext = @"AVCaptureStillImageIsCapturingStillImageContext";

@interface SSMainViewController ()

@property (nonatomic, assign) BOOL isUsingFrontCamera;

@property (nonatomic, strong) AVCaptureStillImageOutput* stillImageOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput* videoDataOutput;

@property (nonatomic, strong) UIView* flashView;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer* previewLayer;
@property (nonatomic, strong) AVCaptureSession* session;

@property (nonatomic, strong) SSVideoCaptureProcessor* videoProcessor;

@property (nonatomic, assign) BOOL detectFace;
@property (nonatomic, assign) BOOL detectSmile;

@end

@implementation SSMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.videoProcessor = [[SSVideoCaptureProcessor alloc] init];
        self.videoProcessor.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupAVCapture];
    // Do any additional setup after loading the view from its nib.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self startAVCapture];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [self stopAVCapture];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)captureImageFromVideo{
    AVCaptureConnection* connection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection
                                                       completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error){
                                                           //截屏并记录
                                                       }];
}

-(void)startAVCapture{
	[self.session startRunning];
	[[self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
}

-(void)stopAVCapture{
    [self.session stopRunning];
}

-(void)setupAVCapture{
    NSError *error = nil;
	
    self.session = [[AVCaptureSession alloc] init];
    
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	    [self.session setSessionPreset:AVCaptureSessionPreset640x480];
	else
	    [self.session setSessionPreset:AVCaptureSessionPresetPhoto];
	
    // Select a video device, make an input
    AVCaptureDeviceInput* deviceInput = nil;
    
    for (AVCaptureDevice* device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]){
        if ([device position] == AVCaptureDevicePositionFront){
            deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        }
    }
	
    self.isUsingFrontCamera = NO;
	if ( [self.session canAddInput:deviceInput] ){
		[self.session addInput:deviceInput];
    }
    
    // Make a still image output
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    [self.stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:(__bridge void *)(AVCaptureStillImageIsCapturingStillImageContext)];
    if ([self.session canAddOutput:self.stillImageOutput]){
        [self.session addOutput:self.stillImageOutput];
    }
    
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
	NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
									   [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [self.videoDataOutput setVideoSettings:rgbOutputSettings];
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked (as we process the still image)
    
    dispatch_queue_t videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
	[self.videoDataOutput setSampleBufferDelegate:self.videoProcessor queue:videoDataOutputQueue];
	
    if ( [self.session canAddOutput:self.videoDataOutput] )
		[self.session addOutput:self.videoDataOutput];
	[[self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:NO];
    
	self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
	[self.previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
	[self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
	CALayer *rootLayer = [self.previewView layer];
	[rootLayer setMasksToBounds:YES];
	[self.previewLayer setFrame:[rootLayer bounds]];
	[rootLayer addSublayer:self.previewLayer];
}

#pragma mark - key value observer
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ( context == (__bridge void *)(AVCaptureStillImageIsCapturingStillImageContext) ) {
		BOOL isCapturingStillImage = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		
		if ( isCapturingStillImage ) {
			// do flash bulb like animation
			self.flashView = [[UIView alloc] initWithFrame:[self.previewView frame]];
			[self.flashView setBackgroundColor:[UIColor whiteColor]];
			[self.flashView setAlpha:0.f];
			[[[self view] window] addSubview:self.flashView];
			
			[UIView animateWithDuration:.4f
							 animations:^{
								 [self.flashView setAlpha:1.f];
							 }
			 ];
		}
		else {
			[UIView animateWithDuration:.4f
							 animations:^{
								 [self.flashView setAlpha:0.f];
							 }
							 completion:^(BOOL finished){
								 [self.flashView removeFromSuperview];
							 }
			 ];
		}
	}
}

#pragma mark - delegate
-(void)processor:(SSVideoCaptureProcessor*)processor hasFace:(BOOL)hasFace hasSmile:(BOOL)hasSmile leftEyeBlink:(BOOL)leftEyeBlink rightEyeBlink:(BOOL)rightEyeBlink faceRect:(CGRect)faceRect{
    if (hasFace && hasSmile){
        [self captureImageFromVideo];
    }
}

@end
