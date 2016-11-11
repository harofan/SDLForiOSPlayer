//
//  OpenglVC.m
//  SDLPlayerDemo
//
//  Created by fy on 2016/10/13.
//  Copyright © 2016年 LY. All rights reserved.
//
//这里县渲染的是一张yuv图片,如果想渲染一段yuv视频,需要对yuv视频进行分割并循环,若屏幕出现绿色或打印说参数错误,一般是视频/图片的宽高不对引起的,请仔细查看资源宽高属性,视频目前需要一些特别的参数,我目前是写死的,这样很不好,后面有空了我会将他们进行合理的优化
#import "OpenglVC.h"

//#import <OpenGLES/ES3/gl.h>

#import <GLKit/GLKit.h>

#import "OpenglView.h"
//文件名
#define filePathName @"jpgimage1_image_640_480.yuv"

#define screenSize [UIScreen mainScreen].bounds.size


#warning 这里参数一定要正确!
//yuv数据宽度
#define videoW 640
//yuv数据高度
#define videoH 480

@interface OpenglVC ()



@end

@implementation OpenglVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self play];
}

-(void)dealloc{
    
    NSLog(@"销毁");
}

/**
 开始渲染
 */
-(void)play{
    
    OpenglView * openglview = [[OpenglView alloc]initWithFrame:CGRectMake(0, 100, screenSize.width, 300)];
    
    [self.view addSubview:openglview];
    
    [openglview setVideoSize:videoW height:videoH];
    
    NSString * path = [[NSBundle mainBundle]pathForResource:filePathName
                                                     ofType:nil];
    
    NSData * data = [NSData dataWithContentsOfFile:path];
    
    UInt32 * pFrameRGB = (UInt32*)[data bytes];
    
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        //这里必须加这个,或者延时,否则显示不出来
        
        sleep(1);
        
        [openglview displayYUV420pData:pFrameRGB width:640 height:480];
        
    });
    
    //这里的page循环数以及9.75设置的比较玄学,这里只是为了先出一个效果
    //实际上是没必要把yuv先分开的,直接在解码里做就可以
//    float result =data.length/9.75f;
//    
//    for (int page = 0 ; page<10; page ++) {
//        
//        NSRange rang=NSMakeRange(page*result+1, page*result+result+1);
//        
//        if (rang.location>=data.length||rang.location+rang.length>=data.length) {
//            return;
//        }
//        NSData * dataNew=[data subdataWithRange:rang];
//        UInt32 * pFrameRGB = (UInt32*)[dataNew bytes];
//        
//        dispatch_async(dispatch_get_global_queue(0, 0), ^{
//            
//            //这里必须加这个,或者延时,否则显示不出来
//            sleep(1);
//            
//            [openglview displayYUV420pData:pFrameRGB width:640 height:480];
//            
//        });
//        
//        if (page == 4) {
//            break;
//        }
//    }
//    
//    
//    NSLog(@"结束");

}
@end
