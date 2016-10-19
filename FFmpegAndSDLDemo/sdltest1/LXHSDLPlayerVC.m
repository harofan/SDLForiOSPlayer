//
//  LXHSDLPlayerVC.m
//  FFmpegAndSDLDemo
//
//  Created by fy on 2016/10/19.
//
//

#import "LXHSDLPlayerVC.h"

#import "avcodec.h"

#import "avformat.h"

#import <SDL2/SDL.h>

#import "swscale.h"

#import <SDL2/SDL_main.h>

@interface LXHSDLPlayerVC ()

@end

@implementation LXHSDLPlayerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self play];
}

-(void)play{
    
    AVFormatContext *pFormatCtx;
    int             i, videoindex;
    AVCodecContext  *pCodecCtx;
    AVCodec         *pCodec;
    AVFrame *pFrame,*pFrameYUV;
    unsigned char *out_buffer;
    AVPacket *packet;
    int y_size;
    int ret, got_picture;
    struct SwsContext *img_convert_ctx;
    
    NSString * path = [[NSBundle mainBundle]pathForResource:@"bigbuckbunny_480x272.h265" ofType:nil];
    
    const char * filepath = [path UTF8String];
    

//    char filepath[]="bigbuckbunny_480x272.h265";
    //SDL---------------------------
    int screen_w=0,screen_h=0;
    SDL_Window *screen;
    SDL_Renderer* sdlRenderer;
    SDL_Texture* sdlTexture;
    SDL_Rect sdlRect;
    
    FILE *fp_yuv;
    
    av_register_all();
    avformat_network_init();
    pFormatCtx = avformat_alloc_context();
    
    if(avformat_open_input(&pFormatCtx,filepath,NULL,NULL)!=0){
        printf("Couldn't open input stream.\n");
        return ;
    }
    if(avformat_find_stream_info(pFormatCtx,NULL)<0){
        printf("Couldn't find stream information.\n");
        return ;
    }
    videoindex=-1;
    for(i=0; i<pFormatCtx->nb_streams; i++)
        if(pFormatCtx->streams[i]->codec->codec_type==AVMEDIA_TYPE_VIDEO){
            videoindex=i;
            break;
        }
    if(videoindex==-1){
        printf("Didn't find a video stream.\n");
        return ;
    }
    
    pCodecCtx=pFormatCtx->streams[videoindex]->codec;
    pCodec=avcodec_find_decoder(pCodecCtx->codec_id);
    if(pCodec==NULL){
        printf("Codec not found.\n");
        return ;
    }
    if(avcodec_open2(pCodecCtx, pCodec,NULL)<0){
        printf("Could not open codec.\n");
        return ;
    }
    
    pFrame=av_frame_alloc();
    pFrameYUV=av_frame_alloc();
    out_buffer=(unsigned char *)av_malloc(av_image_get_buffer_size(AV_PIX_FMT_YUV420P,  pCodecCtx->width, pCodecCtx->height,1));
    av_image_fill_arrays(pFrameYUV->data, pFrameYUV->linesize,out_buffer,
                         AV_PIX_FMT_YUV420P,pCodecCtx->width, pCodecCtx->height,1);
    
    packet=(AVPacket *)av_malloc(sizeof(AVPacket));
    //Output Info-----------------------------
    printf("--------------- File Information ----------------\n");
    av_dump_format(pFormatCtx,0,filepath,0);
    printf("-------------------------------------------------\n");
    img_convert_ctx = sws_getContext(pCodecCtx->width, pCodecCtx->height, pCodecCtx->pix_fmt,
                                     pCodecCtx->width, pCodecCtx->height, AV_PIX_FMT_YUV420P, SWS_BICUBIC, NULL, NULL, NULL);
    
#if OUTPUT_YUV420P
    fp_yuv=fopen("output.yuv","wb+");
#endif
    
    if(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_TIMER)) {
        printf( "Could not initialize SDL - %s\n", SDL_GetError());
        return ;
    }
    
    screen_w = pCodecCtx->width;
    screen_h = pCodecCtx->height;
    //SDL 2.0 Support for multiple windows
    screen = SDL_CreateWindow("Simplest ffmpeg player's Window", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
                              screen_w, screen_h,
                              SDL_WINDOW_OPENGL);
    
    if(!screen) {
        printf("SDL: could not create window - exiting:%s\n",SDL_GetError());
        return ;
    }
    
    sdlRenderer = SDL_CreateRenderer(screen, -1, 0);
    //IYUV: Y + U + V  (3 planes)
    //YV12: Y + V + U  (3 planes)
    sdlTexture = SDL_CreateTexture(sdlRenderer, SDL_PIXELFORMAT_IYUV, SDL_TEXTUREACCESS_STREAMING,pCodecCtx->width,pCodecCtx->height);
    
    sdlRect.x=0;
    sdlRect.y=0;
    sdlRect.w=screen_w;
    sdlRect.h=screen_h;
    
    //SDL End----------------------
    while(av_read_frame(pFormatCtx, packet)>=0){
        if(packet->stream_index==videoindex){
            ret = avcodec_decode_video2(pCodecCtx, pFrame, &got_picture, packet);
            if(ret < 0){
                printf("Decode Error.\n");
                return ;
            }
            if(got_picture){
                sws_scale(img_convert_ctx, (const unsigned char* const*)pFrame->data, pFrame->linesize, 0, pCodecCtx->height,
                          pFrameYUV->data, pFrameYUV->linesize);
                
#if OUTPUT_YUV420P
                y_size=pCodecCtx->width*pCodecCtx->height;
                fwrite(pFrameYUV->data[0],1,y_size,fp_yuv);    //Y
                fwrite(pFrameYUV->data[1],1,y_size/4,fp_yuv);  //U
                fwrite(pFrameYUV->data[2],1,y_size/4,fp_yuv);  //V
#endif
                //SDL---------------------------
#if 0
                SDL_UpdateTexture( sdlTexture, NULL, pFrameYUV->data[0], pFrameYUV->linesize[0] );
#else
                SDL_UpdateYUVTexture(sdlTexture, &sdlRect,
                                     pFrameYUV->data[0], pFrameYUV->linesize[0],
                                     pFrameYUV->data[1], pFrameYUV->linesize[1],
                                     pFrameYUV->data[2], pFrameYUV->linesize[2]);
#endif
                
                SDL_RenderClear( sdlRenderer );
                SDL_RenderCopy( sdlRenderer, sdlTexture,  NULL, &sdlRect);
                SDL_RenderPresent( sdlRenderer );
                //SDL End-----------------------
                //Delay 40ms
                SDL_Delay(40);
            }
        }
        av_free_packet(packet);
    }
    //flush decoder
    //FIX: Flush Frames remained in Codec
    while (1) {
        ret = avcodec_decode_video2(pCodecCtx, pFrame, &got_picture, packet);
        if (ret < 0)
            break;
        if (!got_picture)
            break;
        sws_scale(img_convert_ctx, (const unsigned char* const*)pFrame->data, pFrame->linesize, 0, pCodecCtx->height,
                  pFrameYUV->data, pFrameYUV->linesize);
#if OUTPUT_YUV420P
        int y_size=pCodecCtx->width*pCodecCtx->height;
        fwrite(pFrameYUV->data[0],1,y_size,fp_yuv);    //Y
        fwrite(pFrameYUV->data[1],1,y_size/4,fp_yuv);  //U
        fwrite(pFrameYUV->data[2],1,y_size/4,fp_yuv);  //V
#endif
        //SDL---------------------------
        SDL_UpdateTexture( sdlTexture, &sdlRect, pFrameYUV->data[0], pFrameYUV->linesize[0] );
        SDL_RenderClear( sdlRenderer );
        SDL_RenderCopy( sdlRenderer, sdlTexture,  NULL, &sdlRect);
        SDL_RenderPresent( sdlRenderer );
        //SDL End-----------------------
        //Delay 40ms
        SDL_Delay(40);
    }
    
    sws_freeContext(img_convert_ctx);
    
#if OUTPUT_YUV420P
    fclose(fp_yuv);
#endif   
    
    SDL_Quit();  
    
    av_frame_free(&pFrameYUV);  
    av_frame_free(&pFrame);  
    avcodec_close(pCodecCtx);  
    avformat_close_input(&pFormatCtx);
}

@end
