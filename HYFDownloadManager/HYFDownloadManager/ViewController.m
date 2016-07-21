                                                                                                                                                                                                                                                                                                                                                                               //
//  ViewController.m
//  HYFDownloadManager
//
//  Created by 万商维盟 on 16/7/14.
//  Copyright © 2016年 万商维盟. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<HYFDownloadDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"%@",NSHomeDirectory());
   
    
    
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)BeginDownLoad:(id)sender {
     [self downloadClick];
    
}

- (void)downloadClick{

    NSString * urlstr =  @"http://baobab.wdjcdn.com/14525705791193.mp4";
    //建立代理连接
    [HYFDownloadManager DefaultInstance].delegate = self;
    
    [[HYFDownloadManager DefaultInstance] download:urlstr progress:^(CGFloat progress, NSString *speed, NSString *remainingTime, NSString *writtenSize, NSString *totalSize) {
        
//        NSLog(@"下载进度 :%lf",progress);
//        NSLog(@"下载速度 :%@",speed);
//        NSLog(@"剩余时间 :%@",remainingTime);
        
        
        
    } state:^(HYFDownloadState state) {
        if (state == HYFDownloadStateCompleted) {
            NSLog(@"下载完成");
        }
        
    }];
}
#pragma mark 通过代理的回调
/**
 因为管理器是以单利的形式存在，所以，通过代理的回掉就显的更加方便随意
 可以让开起下载的界面和接收代理回调的界面不是同一个
 在这里我为了方面写到一个里面了
 **/
-(void)downloadResponse:(HYFSessionModel *)sessionModel{
    sessionModel.progressBlock = ^(CGFloat progress, NSString *speed, NSString *remainingTime, NSString *writtenSize, NSString *totalSize){
        NSLog(@"下载进度 :%lf",progress);
        NSLog(@"下载速度 :%@",speed);
        NSLog(@"剩余时间 :%@",remainingTime);
    
    };
    sessionModel.stateBlock = ^(HYFDownloadState state){
        if (state == HYFDownloadStateCompleted) {
            NSLog(@"下载完成");
        }
    
    };
   
    
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
