#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#import "GLView.h"

@interface GLView ()

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic) GLuint framebuffer;
@property (nonatomic) GLuint renderbuffer;
@property (nonatomic) GLuint depthbuffer;

- (BOOL) createFramebuffer;
- (void) destroyFramebuffer;
- (void) drawView;

@end


@implementation GLView

@synthesize delegate;
@synthesize context;
@synthesize framebuffer;
@synthesize renderbuffer;
@synthesize depthbuffer;

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CAEAGLLayer *layer = (CAEAGLLayer *)self.layer;
        
        layer.opaque = YES;
        layer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO],
                                    kEAGLDrawablePropertyRetainedBacking,
                                    kEAGLColorFormatRGBA8,
                                    kEAGLDrawablePropertyColorFormat,
                                    nil];
        
		self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
		
		if (!context || ![EAGLContext setCurrentContext:context]) {
			return nil;
		}
    }
    return self;
}

- (void)layoutSubviews
{
    [EAGLContext setCurrentContext:context];
	[self destroyFramebuffer];
    [self createFramebuffer];
    [self drawView];
}

- (void)drawView
{
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, framebuffer);
    
	[delegate drawView:self];
	
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, renderbuffer);
    
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (BOOL)createFramebuffer
{
    glGenFramebuffersOES(1, &framebuffer);
    glGenRenderbuffersOES(1, &renderbuffer);
	glGenRenderbuffersOES(1, &depthbuffer);
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, framebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, renderbuffer);
	
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
	
	// Attach renderbuffer to framebuffer
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, renderbuffer);
	
	GLint width;
    GLint height;
    
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &width);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &height);
	
	// Create 16 bit depth buffer
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthbuffer);
	glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, width, height);
	
	// attach the depth buffer to the frame buffer
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthbuffer);
    
    if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
        NSLog(@"OpenGL framebuffer incomplete: %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
    return YES;
}

- (void)destroyFramebuffer
{
    glDeleteFramebuffersOES(1, &framebuffer);
    framebuffer = 0;
	
    glDeleteRenderbuffersOES(1, &renderbuffer);
    renderbuffer = 0;
	
	glDeleteRenderbuffersOES(1, &depthbuffer);
	depthbuffer = 0;
}


@end