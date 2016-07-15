//
//  HYFDownloadManager.h
//  HYFDownloadManager
//
//  Created by hyf on 16/7/14.


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HYFSessionModel.h"
//各种缓存路径宏
/*
 缓存主目录
 */
#define HYFCachesDirectory [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject]stringByAppendingPathComponent:@"HYFCache"]
/*
 保存文件名
 截取下载地址url尾部字符创作为文件名
 */
#define HYFFileName(url)  [[url componentsSeparatedByString:@"/"] lastObject]
/*
 文件存放路径
 */
#define HYFFileFullpath(url) [HYFCachesDirectory stringByAppendingPathComponent:HYFFileName(url)]
/*
 文件已下载长度
 获取文件已经下载的长度
 */
#define HYFDownloadLength(url) [[[NSFileManager defaultManager] attributesOfItemAtPath:HYFFileFullpath(url) error:nil][NSFileSize] integerValue]
/*
 存储文件信息的路径
 */
#define ZFDownloadDetailPath [HYFCachesDirectory stringByAppendingPathComponent:@"HYFdownloadDetail.data"]


@protocol HYFDownloadDelegate <NSObject>
//用代理实现的一次回调
- (void)downloadResponse:(HYFSessionModel *)sessionModel;

@end
@interface HYFDownloadManager : NSObject

@property (nonatomic,weak) id<HYFDownloadDelegate> delegate;


+(instancetype)DefaultInstance;

/**通过url开始下载******/
- (void)download:(NSString *)url progress:(HYFDownloadProgressBlock)progressBlock state:(HYFDownloadStateBlock)stateBlock;
/***判断文件是否下载完***/

- (BOOL)JudgeIsComplete:(NSString * )url;


@end
