#import <CoreMedia/CoreMedia.h>
#import <sys/utsname.h>

#import "HardwareController.h"

NSString* machineName();

@interface HardwareController ()

@property (nonatomic, strong) GLView *glView;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic) BOOL restartingCamera;
@property (nonatomic) double pixelRatio;

- (void)startCamera;
- (void)restartCamera;
- (void)initCamera;

@end

@implementation HardwareController

@synthesize glView;
@synthesize captureSession;
@synthesize restartingCamera;

- (void) loadView {
  self.restartingCamera = NO;

  CGRect rect = [[UIScreen mainScreen] bounds];

  self.glView = [[GLView alloc] initWithFrame:rect];

  // Double the resolution on iPhone 4 and 4s etc.
  if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
    self.pixelRatio = [UIScreen mainScreen].scale;
  } else {
    self.pixelRatio = 1.0f;
  }
  
  if ([self.glView respondsToSelector:@selector(setContentScaleFactor:)])
  {
    [self.glView setContentScaleFactor: self.pixelRatio];
  }

  glView.delegate = self;
  glView.multipleTouchEnabled = YES;

  self.view = self.glView;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self initCamera];
}

- (void)drawView:(GLView*)view {

}

- (void) startCamera {
    [self.captureSession startRunning];
	restartingCamera = NO;
}

- (void) restartCamera {
	if (self.restartingCamera)
		return;
	
	restartingCamera = YES;
	
	if ([self.captureSession isRunning])
		[self.captureSession stopRunning];
	
	[self startCamera];
}

- (void) eventHandler:(id)data {
    if ([[data name] isEqualToString:@"AVCaptureSessionRuntimeErrorNotification"]) {
        [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(restartCamera) userInfo:nil repeats:NO];
    } else if ([[data name] isEqualToString:@"AVCaptureSessionInterruptionEndedNotification"]) {
        [self.captureSession startRunning];
    }
}

- (void) initCamera {
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
  
	self.captureSession = [[AVCaptureSession alloc] init];
  
	AVCaptureDevice *device = nil;
	NSError *outError = nil;
  
  for (device in [AVCaptureDevice devices]) {
    if (device.position == AVCaptureDevicePositionBack && [device hasMediaType: AVMediaTypeVideo]) break;
  }
  
	if (device == nil) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No camera found"
                                                    message:@"You need a device with a back-facing camera to run this app."
                                                   delegate:self
                                          cancelButtonTitle:@"Quit"
                                          otherButtonTitles:nil];
		[alert show];
		return;
	}
  
	AVCaptureFocusMode wantedFocusMode = AVCaptureFocusModeContinuousAutoFocus;
  
	if ([device isFocusModeSupported: wantedFocusMode]) {
		if ([device lockForConfiguration: &outError]) {
			[device setFocusMode: wantedFocusMode];
			[device unlockForConfiguration];
		} else {
			NSLog(@"lockForConfiguration ERROR: %@", outError);
		}
	}
	
  AVCaptureDeviceInput *devInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&outError];
  
  if (!devInput) {
    NSLog(@"ERROR: %@",outError);
    return;
  }
  
	AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
  output.alwaysDiscardsLateVideoFrames = YES;
  
  NSMutableDictionary *videoSettings = [[NSMutableDictionary alloc] init];
  
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:kCVPixelFormatType_32BGRA];
  
  [videoSettings setValue:number forKey:(NSString*) kCVPixelBufferPixelFormatTypeKey];
  
	[output setVideoSettings:videoSettings];
  
  [output setSampleBufferDelegate:self queue:dispatch_get_current_queue()];
  
  [self.captureSession addInput:devInput];
  
  [self.captureSession addOutput:output];
  
  double max_fps = 30;
  NSString *deviceName = machineName();
  if ([deviceName isEqualToString:@"iPhone2,1"] || [deviceName isEqualToString:@"iPhone3,1"]) {
    max_fps = 15;//Lower frame rate on iPhone 3GS and iPhone 4 for increased image detection performance
  }
  
  NSLog(@"FPS %f", max_fps);
  
  for(int i = 0; i < [[output connections] count]; i++) {
    AVCaptureConnection *conn = [[output connections] objectAtIndex:i];
    if (conn.supportsVideoMinFrameDuration) {
      conn.videoMinFrameDuration = CMTimeMake(1, max_fps);
    }
    if (conn.supportsVideoMaxFrameDuration) {
      conn.videoMaxFrameDuration = CMTimeMake(1, max_fps);
    }
  }
  
  [self.captureSession setSessionPreset: AVCaptureSessionPresetMedium];
  
  NSArray *events = [NSArray arrayWithObjects:
                     AVCaptureSessionRuntimeErrorNotification,
                     AVCaptureSessionErrorKey,
                     AVCaptureSessionDidStartRunningNotification,
                     AVCaptureSessionDidStopRunningNotification,
                     AVCaptureSessionWasInterruptedNotification,
                     AVCaptureSessionInterruptionEndedNotification,
                     nil];
  
  for (id e in events) {
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(eventHandler:)
     name:e
     object:nil];
  }
  
  [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(startCamera) userInfo:nil repeats:NO];
}

@end

NSString* machineName()
{
  struct utsname systemInfo;
  uname(&systemInfo);
  
  return [NSString stringWithCString:systemInfo.machine
                            encoding:NSUTF8StringEncoding];
}