//
//  MainVC.m
//  SDLPlayerDemo
//
//  Created by fy on 2016/10/13.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "MainVC.h"

#import <Masonry/Masonry.h>

#import "FFmpegVC.h"

#import "OpenglVC.h"

#import "LXHOpenGLVC.h"

@interface MainVC ()<UITableViewDelegate,UITableViewDataSource>

@end

@implementation MainVC

- (void)viewDidLoad {
    [super viewDidLoad];
  
    
    [self createUpUI];
}

#pragma mark -  UI
-(void)createUpUI{
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UITableView * tableView = [[UITableView alloc]init];
    
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    
    [self.view addSubview:tableView];
    
    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.edges.equalTo(@0);
        
    }];
    
    tableView.dataSource = self;
    
    tableView.delegate = self;
    
}

#pragma mark -  dataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return 20;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"ffmpeg解码";
            break;
        case 1:
            cell.textLabel.text = @"别人的opengl渲染yuv数据";
            break;
            
        case 2:
            cell.textLabel.text = @"雷博教程写的OpenGL渲染";
            break;
            
        case 3:
            cell.textLabel.text = @"播放器搭建";
            break;
        default:
            cell.textLabel.text = @"";
            break;
    }
    
    return cell;
    
}

#pragma mark -  delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    switch (indexPath.row) {
        case 0:
        {
            FFmpegVC * vc = [[FFmpegVC alloc]init];
            
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        case 1:
        {
            OpenglVC * vc = [[OpenglVC alloc]init];
            
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;

        case 2:
        {
            LXHOpenGLVC * vc = [[LXHOpenGLVC alloc]init];
            
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
//
//        case 3:
//        {
//            IJKPlayerVC * vc = [[IJKPlayerVC alloc]init];
//            
//            [self.navigationController pushViewController:vc animated:YES];
//        }
//            break;
            
            
            
        default:
            break;
    }
    
}
@end
