//
//  FFmpegVC.m
//  SDLPlayerDemo
//
//  Created by fy on 2016/10/13.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "FFmpegVC.h"

#import "avformat.h"

#import "avcodec.h"

#import "swscale.h"

@interface FFmpegVC ()

@end

@implementation FFmpegVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [ UIColor whiteColor];
    
    [self decode];
    
}

-(void)dealloc{
    
    NSLog(@"销毁");
}

/**
 解码
 */
-(void)decode{
    
    //初始化所有组件
    av_register_all();
    
    //声明上下文
    AVFormatContext	*pFormatCtx;
    
    //初始化上下文
    pFormatCtx = avformat_alloc_context();
    
    //获取文件路径
    NSString * filePath = [[NSBundle mainBundle]pathForResource:@"cuc_ieschool.mp4" ofType:nil];
    
    const char * path = [filePath UTF8String];
    
    //打开视频流
    if(avformat_open_input(&pFormatCtx,path,NULL,NULL)!=0){
        
        NSLog(@"不能打开流");
        
        return ;
    }
    
    //查看视频流信息
    if(avformat_find_stream_info(pFormatCtx,NULL)<0){
        
        NSLog(@"不能成功查看视频流信息");
        
        return ;
    }
    
    int i,videoIndex;
    
    videoIndex = -1;
    
    //对上下文中的视频流进行遍历
    for (i = 0; i<pFormatCtx->nb_streams; i++) {
        
        //找到视频流信息后跳出循环
        if(pFormatCtx->streams[i]->codecpar->codec_type==AVMEDIA_TYPE_VIDEO){
            
            videoIndex=i;
            
            break;
            
        }
    }
    
    //若videoIndex还为初值那么说明没有找到视频流
    if(videoIndex==-1){
        
        NSLog(@"没有找到视频流");
        
        return ;
    }
    
    //声明编码器上下文结构体
    //这里新版本不再使用AVCodecContext这个结构体了,具体原因我也不太清楚,好像是AVCodecContext过于臃肿
    AVCodecContext	* pCodecCtx;
    
    pCodecCtx = pFormatCtx->streams[videoIndex]->codec;
    
    //声明解码器类型
    AVCodec	*pCodec;
    
    //查找解码器
    pCodec = avcodec_find_decoder(pCodecCtx->codec_id);
    
    if (pCodec == NULL) {
        
        NSLog(@"解码器没找到");
        
        return;
    }
    
    
    //打开解码器
    if(avcodec_open2(pCodecCtx, pCodec,NULL)<0){
        NSLog(@"解码器打开失败");
        return;
    }
    
    //解码后的数据
    AVFrame *pFream,*pFreamYUV;
    
    pFream = av_frame_alloc();
    
    pFreamYUV = av_frame_alloc();
    
    uint8_t *out_buffer;
    
    //分配内存
    //根据像素格式,宽高分配
    out_buffer = (uint8_t *)av_malloc(avpicture_get_size(AV_PIX_FMT_YUV420P, pCodecCtx->width, pCodecCtx->height));
    
    //用ptr中的内容根据文件格式（YUV…） 和分辨率填充picture。这里由于是在初始化阶段，所以填充的可能全是零。
    avpicture_fill((AVPicture*)pFreamYUV, out_buffer, AV_PIX_FMT_YUV420P, pCodecCtx->width, pCodecCtx->height);
    
    //解码前的数据
    AVPacket *packet;
    
    //开辟空间
    packet =(AVPacket *)av_malloc(sizeof(AVPacket));
    
    /*******************************输出信息*********************************************/
    
    NSLog(@"--------------- File Information ----------------");
    
    //打印视频信息,av_dump_format()是一个手工调试的函数，能使我们看到pFormatCtx->streams里面有什么内容
    av_dump_format(pFormatCtx, 0, path, 0);
    
    NSLog(@"-------------------------------------------------");
    
    //主要用来对图像进行变化,这里是为了缩放,把黑边裁去
    struct SwsContext * img_convert_ctx;
    
    
    /**
     该函数包含以下参数：
     srcW：源图像的宽
     srcH：源图像的高
     srcFormat：源图像的像素格式
     dstW：目标图像的宽
     dstH：目标图像的高
     dstFormat：目标图像的像素格式
     flags：设定图像拉伸使用的算法
     成功执行的话返回生成的SwsContext，否则返回NULL。
     */
    img_convert_ctx = sws_getContext(pCodecCtx->width, pCodecCtx->height, pCodecCtx->pix_fmt,
                                     pCodecCtx->width, pCodecCtx->height, AV_PIX_FMT_YUV420P, SWS_BICUBIC, NULL, NULL, NULL);
    
    //解码序号
    int frame_cnt = 0;
    
    int got_picture_ptr = 0;
    
    //循环读取每一帧
    while (av_read_frame(pFormatCtx, packet)>=0) {
        
        //若为视频流信息
        if (packet->stream_index == videoIndex) {
            
            //解码一帧数据,输入一个压缩编码的结构体AVPacket，输出一个解码后的结构体AVFrame。
            int ret = avcodec_decode_video2(pCodecCtx, pFream, &got_picture_ptr, packet);
            
            //当解码失败
            if (ret < 0) {
                
                NSLog(@"解码失败");
                
                return;
            }
            
            if (got_picture_ptr) {
                //处理图像数据,用于转换像素
                //裁剪
                //data解码后的图像像素数据
                //linesize对视频来说是一行像素的大小
                sws_scale(img_convert_ctx, (const uint8_t * const *)pFream->data, pFream->linesize, 0, pCodecCtx->height, pFreamYUV->data, pFreamYUV->linesize);
                
//                dispatch_async(dispatch_get_global_queue(0, 0), ^{
//                    
//                    sleep(1);
//                    
//                    [self.openglView displayYUV420pData:pFreamYUV width:videoW height:videoH];
//                    
//                });
                
                
                NSLog(@"解码序号%d",frame_cnt);
                
                frame_cnt ++;
            }
        }
        
        
        
        //销毁packet
        av_free_packet(packet);
    }
    
    //销毁
    sws_freeContext(img_convert_ctx);
    
    av_frame_free(&pFreamYUV);
    
    av_frame_free(&pFream);
    
    avcodec_close(pCodecCtx);
    
    avformat_close_input(&pFormatCtx);
}

@end
