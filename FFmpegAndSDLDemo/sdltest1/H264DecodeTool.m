//
//  H264DecodeTool.m
//  FFmpegAndSDLDemo
//
//  Created by fy on 2016/10/20.
//
//

#import "H264DecodeTool.h"

#import "avcodec.h"
#import "avformat.h"
#import "swscale.h"


@interface H264DecodeTool ()

{
    int             pictureWidth;
    BOOL            isInit;
    AVCodec*        pCodec;
    AVCodecContext* pCodecCtx;
    AVFrame*        pVideoFrame;
    AVPacket        pAvPackage;
    //解码状态
    int             setRecordResolveState;
}
@end

@implementation H264DecodeTool

- (id) init
{
    
    if(self=[super init])
    {
        isInit = 0;
    }
    
    return self;
}

-(void)initFFmpeg:(NSError *__autoreleasing *)error{
    
    NSString * errorDomain = @"com.SkyHarute.FFmpegDecode.errorDomain";
    NSDictionary * userInfo;
    
    
    pCodec      =NULL;
    pCodecCtx   =NULL;
    pVideoFrame =NULL;
    
    pictureWidth=0;
    
    setRecordResolveState=0;
    
    av_register_all();
    avcodec_register_all();
    
    pCodec=avcodec_find_decoder(AV_CODEC_ID_H264);
    if(!pCodec){
        printf("Codec not find\n");
        userInfo = @{@"errorInfo":@"Codec not find"};
        *error = [NSError errorWithDomain:errorDomain code:-101 userInfo:userInfo];
        return ;
    }
    pCodecCtx=avcodec_alloc_context3(pCodec);
    if(!pCodecCtx){
        printf("allocate codec context error\n");
        userInfo = @{@"errorInfo":@"allocate codec context error"};
        *error = [NSError errorWithDomain:errorDomain code:-102 userInfo:userInfo];
        return ;
    }
    
    avcodec_open2(pCodecCtx, pCodec, NULL);
    
    pVideoFrame=av_frame_alloc();
    
    //已初始化
    isInit = 1;
}

- (void)dealloc
{
    if(!pCodecCtx){
        avcodec_close(pCodecCtx);
        pCodecCtx=NULL;
    }
    if(!pVideoFrame){
        av_frame_free(&pVideoFrame);
        pVideoFrame=NULL;
    }
}

- (int)DecodeH264Frames: (unsigned char*)inputBuffer withLength:(int)aLength
{
    //没有初始化
    if (!isInit) {
        return -1;
    }
    int gotPicPtr=0;
    int result=0;
    
    av_init_packet(&pAvPackage);
    pAvPackage.data=(unsigned char*)inputBuffer;
    pAvPackage.size=aLength;
    //解码
    result=avcodec_decode_video2(pCodecCtx, pVideoFrame, &gotPicPtr, &pAvPackage);
    
    //如果视频尺寸更改，我们丢掉这个frame
    if((pictureWidth!=0)&&(pictureWidth!=pCodecCtx->width)){
        setRecordResolveState=0;
        pictureWidth=pCodecCtx->width;
        return -1;
    }
    
    //YUV 420 Y U V  -> RGB
    if(gotPicPtr)
    {
        
        unsigned int lumaLength= (pCodecCtx->height)*(MIN(pVideoFrame->linesize[0], pCodecCtx->width));
        unsigned int chromBLength=((pCodecCtx->height)/2)*(MIN(pVideoFrame->linesize[1], (pCodecCtx->width)/2));
        unsigned int chromRLength=((pCodecCtx->height)/2)*(MIN(pVideoFrame->linesize[2], (pCodecCtx->width)/2));
        
        H264YUV_Frame    yuvFrame;
        memset(&yuvFrame, 0, sizeof(H264YUV_Frame));
        
        yuvFrame.luma.length = lumaLength;
        yuvFrame.chromaB.length = chromBLength;
        yuvFrame.chromaR.length =chromRLength;
        
        yuvFrame.luma.dataBuffer=(unsigned char*)malloc(lumaLength);
        yuvFrame.chromaB.dataBuffer=(unsigned char*)malloc(chromBLength);
        yuvFrame.chromaR.dataBuffer=(unsigned char*)malloc(chromRLength);
        
        //复制
        copyDecodedFrame(pVideoFrame->data[0],yuvFrame.luma.dataBuffer,pVideoFrame->linesize[0],
                         pCodecCtx->width,pCodecCtx->height);
        copyDecodedFrame(pVideoFrame->data[1], yuvFrame.chromaB.dataBuffer,pVideoFrame->linesize[1],
                         pCodecCtx->width / 2,pCodecCtx->height / 2);
        copyDecodedFrame(pVideoFrame->data[2], yuvFrame.chromaR.dataBuffer,pVideoFrame->linesize[2],
                         pCodecCtx->width / 2,pCodecCtx->height / 2);
        
        yuvFrame.width=pCodecCtx->width;
        yuvFrame.height=pCodecCtx->height;
        
        if(setRecordResolveState==0){
//            [[Mp4VideoRecorder getInstance] setVideoWith:pCodecCtx->width withHeight:pCodecCtx->height];
            setRecordResolveState=1;
        }
        
        //主线程刷新界面
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            [self updateYUVFrameOnMainThread:(H264YUV_Frame*)&yuvFrame];
        });
        
        free(yuvFrame.luma.dataBuffer);
        free(yuvFrame.chromaB.dataBuffer);
        free(yuvFrame.chromaR.dataBuffer);
        
    }
    av_free_packet(&pAvPackage);
    
    return 0;
}
void copyDecodedFrame(unsigned char *src, unsigned char *dist,int linesize, int width, int height)
{
    
    width = MIN(linesize, width);
    
    for (NSUInteger i = 0; i < height; ++i) {
        memcpy(dist, src, width);
        dist += width;
        src += linesize;
    }
    
}
- (void)updateYUVFrameOnMainThread:(H264YUV_Frame*)yuvFrame
{
    if(yuvFrame!=NULL){
        if([self.updateDelegate respondsToSelector:@selector(updateDecodedH264FrameData: )]){
            [self.updateDelegate updateDecodedH264FrameData:yuvFrame];
        }
    }
}

@end
