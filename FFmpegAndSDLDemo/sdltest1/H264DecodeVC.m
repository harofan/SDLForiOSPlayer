//
//  H264DecodeVC.m
//  FFmpegAndSDLDemo
//
//  Created by fy on 2016/10/20.
//
//

#import "H264DecodeVC.h"

#import "H264DecodeTool.h"

@interface H264DecodeVC ()

@end

@implementation H264DecodeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    H264DecodeTool * tool = [[H264DecodeTool alloc]init];
    
    NSError * error;
    [tool initFFmpeg:&error];
    NSLog(@"%@",error);
    
}



@end
