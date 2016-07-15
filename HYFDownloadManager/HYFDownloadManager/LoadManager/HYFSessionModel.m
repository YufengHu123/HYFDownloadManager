//
//  HYFSessionModel.m
//  HYFDownloadManager
//
//  Created by 万商维盟 on 16/7/14.
//  Copyright © 2016年 万商维盟. All rights reserved.
//

#import "HYFSessionModel.h"

@implementation HYFSessionModel
- (float)calculateFileSizeInUnit:(unsigned long long)contentLength
{
    if(contentLength >= pow(1024, 3)) { return (float) (contentLength / (float)pow(1024, 3)); }
    else if (contentLength >= pow(1024, 2)) { return (float) (contentLength / (float)pow(1024, 2)); }
    else if (contentLength >= 1024) { return (float) (contentLength / (float)1024); }
    else { return (float) (contentLength); }
}

- (NSString *)calculateUnit:(unsigned long long)contentLength
{
    if(contentLength >= pow(1024, 3)) { return @"GB";}
    else if(contentLength >= pow(1024, 2)) { return @"MB"; }
    else if(contentLength >= 1024) { return @"KB"; }
    else { return @"B"; }
}
//归档解档
- (void)encodeWithCoder:(NSCoder *)aCoder //将属性进行编码
{
    [aCoder encodeObject:self.url forKey:@"url"];
    [aCoder encodeObject:self.fileName forKey:@"fileName"];
    [aCoder encodeInteger:self.totalLength forKey:@"totalLength"];
    [aCoder encodeObject:self.totalSize forKey:@"totalSize"];
}

- (id)initWithCoder:(NSCoder *)aDecoder //将属性进行解码
{
    self = [super init];
    if (self) {
        self.url = [aDecoder decodeObjectForKey:@"url"];
        self.fileName = [aDecoder decodeObjectForKey:@"fileName"];
        self.totalLength = [aDecoder decodeIntegerForKey:@"totalLength"];
        self.totalSize = [aDecoder decodeObjectForKey:@"totalSize"];
    }
    return self;
}

@end
