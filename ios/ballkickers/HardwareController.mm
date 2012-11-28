#import "HardwareController.h"
#import "GLView.h"

@interface HardwareController ()

@property (nonatomic, strong) GLView *glView;

@end

@implementation HardwareController

@synthesize glView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)loadView {
  CGRect rect = [[UIScreen mainScreen] bounds];

  self.glView = [[GLView alloc] initWithFrame:rect];

  self.view = self.glView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
