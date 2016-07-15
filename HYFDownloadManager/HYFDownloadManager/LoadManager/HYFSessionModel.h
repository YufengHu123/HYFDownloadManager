//
//  HYFSessionModel.h
//  HYFDownloadManager
//
//  Created by 万商维盟 on 16/7/14.
//  Copyright © 2016年 万商维盟. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//枚举下载状态
typedef NS_ENUM(NSInteger,HYFDownloadState) {
    HYFDownloadStateStart = 0,  //下载进行中
    HYFDownloadStateSuspended,  //下载暂停
    HYFDownloadStateCompleted,  //下载完成
    HYFDownloadStateFailed,     //下载失败
};
//定义回调的block
typedef void(^HYFDownloadProgressBlock)(CGFloat progress, NSString *speed, NSString *remainingTime, NSString *writtenSize, NSString *totalSize);

typedef void (^HYFDownloadStateBlock)(HYFDownloadState state);

@interface HYFSessionModel : NSObject
/** 输出流 */
@property (nonatomic, strong) NSOutputStream *stream;
/** 下载地址 */
@property (nonatomic, copy) NSString *url;
/** 开始下载时间 */
@property (nonatomic, strong) NSDate *startTime;
/** 文件名 */
@property (nonatomic, copy) NSString *fileName;
/** 文件大小 */
@property (nonatomic, copy) NSString *totalSize;
/** 获得服务器这次请求 返回数据的总长度 */
@property (nonatomic, assign) NSInteger totalLength;

/** 下载进度 */
@property (atomic, copy) HYFDownloadProgressBlock progressBlock;

/** 下载状态 */
@property (atomic, copy) HYFDownloadStateBlock stateBlock;

- (float)calculateFileSizeInUnit:(unsigned long long)contentLength;

- (NSString *)calculateUnit:(unsigned long long)contentLength;


@end
