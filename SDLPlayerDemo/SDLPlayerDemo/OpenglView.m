//
//  OpenglView.m
//  SDLPlayerDemo
//
//  Created by fy on 2016/10/9.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "OpenglView.h"

enum AttribEnum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXTURE,
    ATTRIB_COLOR,
};

//YUV数据枚举
enum TextureType
{
    TEXY = 0,
    TEXU,
    TEXV,
    TEXC
};

@implementation OpenglView

#pragma mark -  初始化等操作
- (BOOL)doInit{
    //用来显示opengl的图形
    CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
    //eaglLayer.opaque = YES;
    
    //设为不透明
    eaglLayer.opaque = YES;
    
    //设置描绘属性
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                                    kEAGLColorFormatRGB565, kEAGLDrawablePropertyColorFormat,
                                    //[NSNumber numberWithBool:YES], kEAGLDrawablePropertyRetainedBacking,
                                    nil];
    
    //设置分辨率
    self.contentScaleFactor = [UIScreen mainScreen].scale;
    _viewScale = [UIScreen mainScreen].scale;
    
    //创建上下文
    _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    //[self debugGlError];
    
    //上下文创建失败则直接返回no
    if(!_glContext || ![EAGLContext setCurrentContext:_glContext])
    {
        return NO;
    }
    
    //创建纹理
    [self setupYUVTexture];
    
    //加载着色器
    [self loadShader];
    
    //使用着色器
    glUseProgram(_program);
    
    //获取一致变量的存储位置
    GLuint textureUniformY = glGetUniformLocation(_program, "SamplerY");
    GLuint textureUniformU = glGetUniformLocation(_program, "SamplerU");
    GLuint textureUniformV = glGetUniformLocation(_program, "SamplerV");
    
    //对几个纹理采样器变量进行设置
    glUniform1i(textureUniformY, 0);
    glUniform1i(textureUniformU, 1);
    glUniform1i(textureUniformV, 2);
    
    return YES;
}


-(instancetype)initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    
    if (self) {
        
        //没有初始化成功
        if (![self doInit]) {
            
            self = nil;
        }
    }
    
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        
        //没有初始化成功
        if (![self doInit]) {
            
            self = nil;
        }
    }
    
    return self;
}

-(void)layoutSubviews{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        //互斥锁
        @synchronized (self) {
            
            [EAGLContext setCurrentContext:_glContext];
            
            //清除缓冲区
            [self destoryFrameAndRenderBuffer];
            
            //创建缓冲区
            [self createFrameAndRenderBuffer];
            
        }
        
        //把数据显示在这个视窗上
        glViewport(1, 1, self.bounds.size.width*_viewScale - 2, self.bounds.size.height*_viewScale - 2);
    });
}

#pragma mark -  设置opengl



/**
 创建缓冲区

 @return <#return value description#>
 */
- (BOOL)createFrameAndRenderBuffer
{
    //创建帧缓冲绑定
    glGenFramebuffers(1, &_framebuffer);
    glGenRenderbuffers(1, &_renderBuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    
    if (![_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer])
    {
        NSLog(@"attach渲染缓冲区失败");
    }
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"创建缓冲区错误 0x%x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }
    return YES;
}

/**
 清除缓冲区
 */
- (void)destoryFrameAndRenderBuffer
{
    if (_framebuffer)
    {
        glDeleteFramebuffers(1, &_framebuffer);
    }
    
    if (_renderBuffer)
    {
        glDeleteRenderbuffers(1, &_renderBuffer);
    }
    
    _framebuffer = 0;
    _renderBuffer = 0;
}
/**
 创建纹理
 */
- (void)setupYUVTexture{
    
}

/**
 加载着色器
 */
- (void)loadShader{
    
}

#pragma mark -  接口

        

/**
 设置大小

 @param width  界面宽
 @param height 界面高
 */
-(void)setVideoSize:(GLuint)width height:(GLuint)height{
   
    //给宽高赋值
    _videoH = height;
    _videoW = width;

    //开辟内存空间
    //为什么乘1.5而不是1: width * hight =Y（总和） U = Y / 4   V = Y / 4
    void *blackData = malloc(width * height * 1.5);
    
    if (blackData) {
        
        /**
         对内存空间清零,作用是在一段内存块中填充某个给定的值，它是对较大的结构体或数组进行清零操作的一种最快方法

         @param __b#>   源数据 description#>
         @param __c#>   填充数据 description#>
         @param __len#> 长度 description#>

         @return <#return value description#>
         */
        memset(blackData, 0x0, width * height * 1.5);
    }
    /*
     Apple平台不允许直接对Surface进行操作.这也就意味着在Apple中,不能通过调用eglSwapBuffers函数来直接实现渲染结果在目标surface上的更新.
     在Apple平台中,首先要创建一个EAGLContext对象来替代EGLContext (不能通过eglCreateContext来生成), EAGLContext的作用与EGLContext是类似的.
     然后,再创建相应的Framebuffer和Renderbuffer.
     Framebuffer象一个Renderbuffer集(它可以包含多个Renderbuffer对象).
     
     Renderbuffer有三种:  color Renderbuffer, depth Renderbuffer, stencil Renderbuffer.
     
     渲染结果是先输出到Framebuffer中,然后通过调用context的presentRenderbuffer,将Framebuffer上的内容提交给之前的CustumView.
     */
    
    //设置当前上下文
    [EAGLContext setCurrentContext:_glContext];
    
    
    /*
     target —— 纹理被绑定的目标，它只能取值GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D或者GL_TEXTURE_CUBE_MAP；
     texture —— 纹理的名称，并且，该纹理的名称在当前的应用中不能被再次使用。
     glBindTexture可以让你创建或使用一个已命名的纹理，调用glBindTexture方法，将target设置为GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D或者GL_TEXTURE_CUBE_MAP，并将texture设置为你想要绑定的新纹理的名称，即可将纹理名绑定至当前活动纹理单元目标。当一个纹理与目标绑定时，该目标之前的绑定关系将自动被打破。纹理的名称是一个无符号的整数。在每个纹理目标中，0被保留用以代表默认纹理。纹理名称与相应的纹理内容位于当前GL rendering上下文的共享对象空间中。
     */
    
    //绑定Y纹理
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXY]);
    
    
    /**
     根据像素数据,加载纹理

     @param target#>         指定目标纹理，这个值必须是GL_TEXTURE_2D。 description#>
     @param level#>          执行细节级别。0是最基本的图像级别，n表示第N级贴图细化级别 description#>
     @param internalformat#> 指定纹理中的颜色格式。可选的值有GL_ALPHA,GL_RGB,GL_RGBA,GL_LUMINANCE, GL_LUMINANCE_ALPHA 等几种。 description#>
     @param width#>          纹理的宽度 description#>
     @param height#>         高度 description#>
     @param border#>         纹理的边框宽度,必须为0 description#>
     @param format#>         像素数据的颜色格式, 不需要和internalformatt取值必须相同。可选的值参考internalformat。 description#>
     @param type#>           指定像素数据的数据类型。可以使用的值有GL_UNSIGNED_BYTE,GL_UNSIGNED_SHORT_5_6_5,GL_UNSIGNED_SHORT_4_4_4_4,GL_UNSIGNED_SHORT_5_5_5_1等。 description#>
     @param pixels#>         指定内存中指向图像数据的指针 description#>

     @return <#return value description#>
     */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width, height, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, blackData);
    
    //绑定U纹理
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXU]);
    //加载纹理
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width/2, height/2, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, blackData + width * height);
    
    //绑定V数据
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXV]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width/2, height/2, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, blackData + width * height * 5 / 4);
    
    //释放malloc分配的内存空间
    free(blackData);
}


/**
 清除画面
 */
-(void)clearFrame{
    
}


/**
 显示YUV数据

 @param data YUV数据
 @param w    <#w description#>
 @param h    <#h description#>
 */
-(void)displayYUV420pData:(void *)data width:(NSInteger)w height:(NSInteger)h{
    
    if (!self.window) {
        return;
    }
    
    //加互斥锁,防止其他线程访问
    @synchronized (self) {
        
        if (w != _videoW || h != _videoH) {
            [self setVideoSize:(GLuint)w height:(GLuint)h];
        }
        
        //设置当前上下文
        [EAGLContext setCurrentContext:_glContext];
        
        //绑定
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXY]);
        
        /**
         更新纹理
         https://my.oschina.net/sweetdark/blog/175784
         @param target#>  指定目标纹理，这个值必须是GL_TEXTURE_2D。 description#>
         @param level#>   执行细节级别。0是最基本的图像级别，n表示第N级贴图细化级别 description#>
         @param xoffset#> 纹理数据的偏移x值 description#>
         @param yoffset#> 纹理数据的偏移y值 description#>
         @param width#>   更新到现在的纹理中的纹理数据的规格宽 description#>
         @param height#>  高 description#>
         @param format#>  像素数据的颜色格式, 不需要和internalformatt取值必须相同。可选的值参考internalformat。 description#>
         @param type#>    颜色分量的数据类型 description#>
         @param pixels#>  指定内存中指向图像数据的指针 description#>
         
         @return <#return value description#>
         */
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, (GLsizei)w, (GLsizei)h, GL_RED_EXT, GL_UNSIGNED_BYTE, data);
        
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXU]);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, (GLsizei)w/2, (GLsizei)h/2, GL_RED_EXT, GL_UNSIGNED_BYTE, data + w * h);
        
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXV]);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, (GLsizei)w/2, (GLsizei)h/2, GL_RED_EXT, GL_UNSIGNED_BYTE, data + w * h * 5 / 4);
        
        //渲染
        [self render];
    }
    
#ifdef DEBUG
    
    GLenum err = glGetError();
    if (err != GL_NO_ERROR)
    {
        printf("GL_ERROR=======>%d\n", err);
    }
    struct timeval nowtime;
    gettimeofday(&nowtime, NULL);
    if (nowtime.tv_sec != _time.tv_sec)
    {
        printf("视频 %ld 帧率:   %d\n", self.tag, _frameRate);
        memcpy(&_time, &nowtime, sizeof(struct timeval));
        _frameRate = 1;
    }
    else
    {
        _frameRate++;
    }
#endif
}


/**
 渲染
 */
-(void)render{
    
    //设置上下文
    [EAGLContext setCurrentContext:_glContext];
    
    CGSize size = self.bounds.size;
    
    //把数据显示在这个视窗上
    glViewport(1, 1, size.width * _viewScale -2, size.height * _viewScale -2);
    
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    
    static const GLfloat coordVertices[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f,  0.0f,
        1.0f,  0.0f,
    };
    
    //更新属性值
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
    //开启定点属性数组
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    
    
    glVertexAttribPointer(ATTRIB_TEXTURE, 2, GL_FLOAT, 0, 0, coordVertices);
    glEnableVertexAttribArray(ATTRIB_TEXTURE);
    
    //绘制
    
    //当采用顶点数组方式绘制图形时，使用该函数。该函数根据顶点数组中的坐标数据和指定的模式，进行绘制。
    //绘制方式,从数组的哪一个点开始绘制(一般为0),顶点个数
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    //将该渲染缓冲区对象绑定到管线上
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    //把缓冲区（render buffer和color buffer）的颜色呈现到UIView上
    [_glContext presentRenderbuffer:GL_RENDERBUFFER];

}
@end
