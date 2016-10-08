//
//  VKGLES2View.m
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>

#import "VKVideoDecoder.h"
#import "VKDecodeManager.h"
#import "VKVideoFrameYUV.h"
#import "VKVideoFrameYUVVT.h"
#import "VKVideoFrameRGB.h"

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

@class VKDecodeManager;
@class VKVideoFrame;

extern const GLfloat texCoords[];
extern NSString *const stringShaderVertex;

/**
 *  VideoKit uses opengl framework to render pictures & make color conversion fastly. VKGLES2View is a subclass of UIView and its opengl settings are ready for opengl rendering.
 */
@interface VKGLES2View : UIView {
    
    EAGLContext *_context; // OpenGL ES context
    GLint _position;   //must be a unique id for attribution
    GLint _texCoordIn; //must be a unique id for attribution
    GLfloat _vertices[8];  // Vertices x1,y1 ... x4,y4
    GLuint _renderbuffer;
    GLuint _vertexShader;
    GLuint _fragmentShader;
    GLuint _program;
    GLuint _projectionUniformMatrix;
    GLuint _a;
    VKVideoStreamColorFormat _colorFormat;
}

#pragma mark - public methods

/**
*  Initialize openGL view with DecodeManager
*
*  @param decoder VKDecodeManager object to be feed from
*  @param bounds bounds of the render view
*
*  @return 0 for succes and non-zero for failure
*/
- (int)initGLWithDecodeManager:(VKDecodeManager *)decoder bounds:(CGRect)bounds;

/**
 *  Enable-disable retina frames if device has retina support, default is YES
 *
 *  @param value Specify YES for enabling or NO for disabling Retina
 */
- (void)enableRetina:(BOOL)value;


- (CGRect)exactFrameRectForSize:(CGSize)boundsSize fillScreen:(BOOL)fillScreen;


- (void)updateOpenGLFrameSizes;

/** 
 * Get snapshot of glview in UIImage format
 *
 * @return UIImage object
 */
- (UIImage *)snapshot;

/**
 *  destroy openGL view
 */
- (void)shutdown;

///Specify YES to fit video frames fill to the glview, default is NO
@property (nonatomic, assign) BOOL fillScreen;

///Specify YES to to avoid calling layoutsubviews method of glView when layout changes
@property (nonatomic, assign) BOOL stopUpdateGLSize;

@end
