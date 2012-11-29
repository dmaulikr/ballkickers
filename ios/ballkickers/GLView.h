#import <UIKit/UIKit.h>

@protocol GLViewDelegate

- (void)drawView:(UIView *)theView;

@end

@interface GLView : UIView

@property (assign) id<GLViewDelegate>  delegate;

@end

