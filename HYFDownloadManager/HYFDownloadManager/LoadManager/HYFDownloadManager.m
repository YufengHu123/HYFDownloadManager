//
//  HYFDownloadManager.m
//  HYFDownloadManager
//
//  Created by hyf on 16/7/14.



#import "HYFDownloadManager.h"

@interface HYFDownloadManager ()<NSCopying,NSURLSessionDelegate>

/** 保存所有任务(注：用下载地址/后作为key) */
@property (nonatomic, strong) NSMutableDictionary *tasks;
/** 保存所有下载相关信息字典 */
@property (nonatomic, strong) NSMutableDictionary *sessionModels;
/** 所有本地存储的所有下载信息数据数组 */
@property (nonatomic, strong) NSMutableArray *sessionModelsArray;
/** 下载完成的模型数组*/
@property (nonatomic, strong) NSMutableArray *downloadedArray;
/** 下载中的模型数组*/
@property (nonatomic, strong) NSMutableArray *downloadingArray;

@end

@implementation HYFDownloadManager

/****属性懒加载部分****/
- (NSMutableDictionary *)tasks
{
    if (!_tasks) {
        _tasks = [NSMutableDictionary dictionary];
    }
    return _tasks;
}

- (NSMutableDictionary *)sessionModels
{
    if (!_sessionModels) {
        _sessionModels = [NSMutableDictionary dictionary];
    }
    return _sessionModels;
}


- (NSMutableArray *)sessionModelsArray
{
    if (!_sessionModelsArray) {
        _sessionModelsArray = [NSMutableArray array];
        //如果程序退出，第二次登陆可以通过解档获取曾经的下载记录
        [_sessionModelsArray addObjectsFromArray:[self getSessionModels]];
    }
    return _sessionModelsArray;
}

- (NSMutableArray *)downloadingArray
{
    if (!_downloadingArray) {
        _downloadingArray = [NSMutableArray array];
        for (HYFSessionModel *obj in self.sessionModelsArray) {
            //比较当前下载url所对应的文件是否下载完成
            if (![self isCompletion:obj.url]) {
                [_downloadingArray addObject:obj];
            }
        }
    }
    return _downloadingArray;
}

- (NSMutableArray *)downloadedArray
{
    if (!_downloadedArray) {
        _downloadedArray = [NSMutableArray array];
        for (HYFSessionModel *obj in self.sessionModelsArray) {
            if ([self isCompletion:obj.url]) {
                [_downloadedArray addObject:obj];
            }
        }
    }
    return _downloadedArray;
}

static  HYFDownloadManager *_downloadManager;//静态编译

+ (instancetype)DefaultInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _downloadManager = [[self alloc] init];
    });
    
    return _downloadManager;
}
/**
 * 归档
 */
- (void)save:(NSArray *)sessionModels
{
    [NSKeyedArchiver archiveRootObject:sessionModels toFile:ZFDownloadDetailPath];
}
/**
 * 解档model
 */
- (NSArray *)getSessionModels
{
    // 文件信息
    NSArray *sessionModels = [NSKeyedUnarchiver unarchiveObjectWithFile:ZFDownloadDetailPath];
    return sessionModels;
}


- (void)download:(NSString *)url progress:(HYFDownloadProgressBlock)progressBlock state:(HYFDownloadStateBlock)stateBlock{

    //如果url为nil直接返回
    if (!url) {return;}
    //判断当前文件是否已在下载任务中和是否下载完成
    if ([self JudgeIsComplete:url]) {
        stateBlock(HYFDownloadStateCompleted);
        return;
    }
    //暂停
    if ([self.tasks valueForKey:HYFFileName(url)]) {
        [self handle:url];
        return;
    }
    
    //创建缓存目录文件
    [self createCacheDirectory];
    
    
    //下载相关
    
    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc]init]];
    //创建流
    NSOutputStream * stream = [NSOutputStream outputStreamToFileAtPath:HYFFileFullpath(url) append:YES];
    //创建请求体
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    //设置请求头
    NSString * range = [NSString stringWithFormat:@"byte=%zd-",HYFDownloadLength(url)];

    [request setValue:range forHTTPHeaderField:@"Range"];
    //创建datatask
    NSURLSessionDataTask * task = [session dataTaskWithRequest:request];//讲请求体配置到任务中
    NSUInteger taskIdentifier = arc4random() % ((arc4random() % 10000 + arc4random() % 10000));//产生一个随机数这里随便
    [task setValue:@(taskIdentifier) forKey:@"taskIdentifier"];//为task的属性taskIdentifier赋值，用于唯一表示它
    
    //保存任务
    [self.tasks setValue:task forKey:HYFFileName(url)];//保存当前任务
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:HYFFileFullpath(url)]) {
        HYFSessionModel *sessionModel = [[HYFSessionModel alloc] init];
        sessionModel.url = url;
        sessionModel.progressBlock = progressBlock;//将block传递给model
        sessionModel.stateBlock = stateBlock;//将block传递给model
        sessionModel.stream = stream;
        sessionModel.startTime = [NSDate date];
        sessionModel.fileName = HYFFileName(url);
        [self.sessionModels setValue:sessionModel forKey:@(task.taskIdentifier).stringValue];
        
        [self.sessionModelsArray addObject:sessionModel];
        [self.downloadingArray addObject:sessionModel];
        // 保存
        [self save:self.sessionModelsArray];
    }else{
        for (HYFSessionModel *sessionModel in self.sessionModelsArray) {
            if ([sessionModel.url isEqualToString:url]) {
                sessionModel.url = url;
                sessionModel.progressBlock = progressBlock;
                sessionModel.stateBlock = stateBlock;
                sessionModel.stream = stream;
                sessionModel.startTime = [NSDate date];
                sessionModel.fileName = HYFFileName(url);
                [self.sessionModels setValue:sessionModel forKey:@(task.taskIdentifier).stringValue];
            }
        }
    }
    [self start:url];//开启任务
    
}
//判断文件是否下载完
- (BOOL)JudgeIsComplete:(NSString * )url{

    if ([self fileTotalLength:url]&&HYFDownloadLength(url) == [self fileTotalLength:url]) {
        return YES;
    }
    return NO;
    
}
//获取该文件总大小
- (NSInteger)fileTotalLength:(NSString *)url
{
    for (HYFSessionModel *model in self.sessionModelsArray) {
        if ([model.url isEqualToString:url]) {
            
            NSLog(@"%ld",model.totalLength);
            NSLog(@"%ld",HYFDownloadLength(url));
            
            
            return model.totalLength;
        }
    }
    return 0;
}
- (void)handle:(NSString *)url
{
    NSURLSessionDataTask *task = [self getTask:url];
    if (task.state == NSURLSessionTaskStateRunning) {
        [self pause:url];
    } else {
        [self start:url];
    }
}
/**
 *  开始下载
 */
- (void)start:(NSString *)url
{
    NSURLSessionDataTask *task = [self getTask:url];
    [task resume];
    [self getSessionModel:task.taskIdentifier].stateBlock(HYFDownloadStateStart);
}

/**
 *  暂停下载
 */
- (void)pause:(NSString *)url
{
    NSURLSessionDataTask *task = [self getTask:url];
    [task suspend];
    
    [self getSessionModel:task.taskIdentifier].stateBlock(HYFDownloadStateSuspended);
}
/**
 *  根据url获得对应的下载任务
 */
- (NSURLSessionDataTask *)getTask:(NSString *)url
{
    return (NSURLSessionDataTask *)[self.tasks valueForKey:HYFFileName(url)];
}
/**
 *  根据url获取对应的下载信息模型
 */
- (HYFSessionModel *)getSessionModel:(NSUInteger)taskIdentifier
{
    return (HYFSessionModel *)[self.sessionModels valueForKey:@(taskIdentifier).stringValue];
}
/**
 *  判断该文件是否下载完成
 */
- (BOOL)isCompletion:(NSString *)url
{
    if ([self fileTotalLength:url] && HYFDownloadLength(url) == [self fileTotalLength:url]) {
        return YES;
    }
    return NO;
}
/**
 *  创建缓存目录文件
 */
- (void)createCacheDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:HYFCachesDirectory]) {
        [fileManager createDirectoryAtPath:HYFCachesDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}
#pragma mark NSURLSessionData代理方法

/**
 * 接收到响应
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    
    HYFSessionModel *sessionModel = [self getSessionModel:dataTask.taskIdentifier];
    
    // 打开流
    [sessionModel.stream open];
    
    // 获得服务器这次请求 返回数据的总长度
    NSInteger totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] + HYFDownloadLength(sessionModel.url);
    sessionModel.totalLength = totalLength;
    
    // 总文件大小
    NSString *fileSizeInUnits = [NSString stringWithFormat:@"%.2f %@",
                                 [sessionModel calculateFileSizeInUnit:(unsigned long long)totalLength],
                                 [sessionModel calculateUnit:(unsigned long long)totalLength]];
    sessionModel.totalSize = fileSizeInUnits;
    // 更新数据(文件总长度)
    [self save:self.sessionModelsArray];
    
    // 添加下载中数组
    if (![self.downloadingArray containsObject:sessionModel]) {
        [self.downloadingArray addObject:sessionModel];
    }
    
    // 接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}

/**
 * 接收到服务器返回的数据
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    HYFSessionModel *sessionModel = [self getSessionModel:dataTask.taskIdentifier];
    
    // 写入数据
    [sessionModel.stream write:data.bytes maxLength:data.length];
    
    // 下载进度
    NSUInteger receivedSize = HYFDownloadLength(sessionModel.url);
    NSUInteger expectedSize = sessionModel.totalLength;
    CGFloat progress = 1.0 * receivedSize / expectedSize;
    
    // 每秒下载速度
    NSTimeInterval downloadTime = -1 * [sessionModel.startTime timeIntervalSinceNow];
    NSUInteger speed = receivedSize / downloadTime;
    if (speed == 0) { return; }
    float speedSec = [sessionModel calculateFileSizeInUnit:(unsigned long long) speed];
    NSString *unit = [sessionModel calculateUnit:(unsigned long long) speed];
    NSString *speedStr = [NSString stringWithFormat:@"%.2f%@/s",speedSec,unit];
    
    // 剩余下载时间
    NSMutableString *remainingTimeStr = [[NSMutableString alloc] init];
    unsigned long long remainingContentLength = expectedSize - receivedSize;
    int remainingTime = (int)(remainingContentLength / speed);
    int hours = remainingTime / 3600;
    int minutes = (remainingTime - hours * 3600) / 60;
    int seconds = remainingTime - hours * 3600 - minutes * 60;
    
    if(hours>0) {[remainingTimeStr appendFormat:@"%d 小时 ",hours];}
    if(minutes>0) {[remainingTimeStr appendFormat:@"%d 分 ",minutes];}
    if(seconds>0) {[remainingTimeStr appendFormat:@"%d 秒",seconds];}
    
    NSString *writtenSize = [NSString stringWithFormat:@"%.2f %@",
                             [sessionModel calculateFileSizeInUnit:(unsigned long long)receivedSize],
                             [sessionModel calculateUnit:(unsigned long long)receivedSize]];
    
    NSLog(@"剩余时间:%@",remainingTimeStr);
    
    if (sessionModel.stateBlock) {
        sessionModel.stateBlock(HYFDownloadStateStart);
    }
    if (sessionModel.progressBlock) {
        sessionModel.progressBlock(progress, speedStr, remainingTimeStr,writtenSize, sessionModel.totalSize);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(downloadResponse:)]) {
            [self.delegate downloadResponse:sessionModel];
        }
    });
}

/**
 * 请求完毕（成功|失败）
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    HYFSessionModel *sessionModel = [self getSessionModel:task.taskIdentifier];
    if (!sessionModel) return;
    
    // 关闭流
    [sessionModel.stream close];
    sessionModel.stream = nil;
    
    if ([self isCompletion:sessionModel.url]) {
        // 下载完成
        sessionModel.stateBlock(HYFDownloadStateCompleted);
    } else if (error){
        // 下载失败
        sessionModel.stateBlock(HYFDownloadStateFailed);
    }
    // 清除任务
    [self.tasks removeObjectForKey:HYFFileName(sessionModel.url)];
    [self.sessionModels removeObjectForKey:@(task.taskIdentifier).stringValue];
    
    [self.downloadingArray removeObject:sessionModel];
    
    // 清除任务
    [self.tasks removeObjectForKey:HYFFileName(sessionModel.url)];
    [self.sessionModels removeObjectForKey:@(task.taskIdentifier).stringValue];
    
    [self.downloadingArray removeObject:sessionModel];
    
    if (error.code == -999)    return;   // cancel
    
    if (![self.downloadedArray containsObject:sessionModel]) {
        [self.downloadedArray addObject:sessionModel];
    }
}



@end
