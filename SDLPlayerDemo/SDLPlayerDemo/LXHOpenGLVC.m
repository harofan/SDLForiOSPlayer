//
//  LXHOpenGLVC.m
//  SDLPlayerDemo
//
//  Created by fy on 2016/10/13.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "LXHOpenGLVC.h"

#import <OpenGLES/ES2/gl.h>

@interface LXHOpenGLVC ()

@end

@implementation LXHOpenGLVC

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.view.backgroundColor = [UIColor whiteColor];
    
    
}

/*
 1.       初始化
 1)         初始化
 2)         创建窗口
 3)         设置绘图函数
 4)         设置定时器
 5)         进入消息循环
 
 2.       循环显示画面
 1)       调整显示位置，图像大小
 2)       画图
 3)       显示
 */
-(void)test{
    
    //YUV->RGB
    
    int view_w , view_h;
    
    int pixel_w , pixel_h;
    //yuv420p一个像素12字节
    int bpp = 12;
    
    //YUV文件
    FILE * fp = NULL;//C语言中用来定义带缓冲的文件指针
    
    //缓冲区大小
    unsigned char buffer[pixel_w*pixel_h*bpp/8];//转换前YUV
    unsigned char buffer_convert[pixel_w*pixel_h*3];//转换后RGB
    
    NSString * filePath = [[NSBundle mainBundle]pathForResource:@"cuc_ieschool.mp4" ofType:nil];
    
    const char * path = [filePath UTF8String];
    
    //读取文件
    if ((fp = fopen(path, "rb"))==NULL) {
        printf("不能打开文件");
        return;
    }
    //分配临时缓冲区
    unsigned char * tmpbuf = (unsigned char *)malloc(pixel_h*pixel_w*3);
    
    unsigned char Y,U,V,R,G,B;
    
    unsigned char * y_planar
    
    
}


@end
