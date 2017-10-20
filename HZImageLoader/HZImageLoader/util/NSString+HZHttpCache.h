//
//  NSString+HZHttpCache.h
//  HZHttpCache
//
//  Created by 韩志峰 on 2017/10/9.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (HZHttpCache)
//md5 加密
- (NSString *)md5Encrypt;
//获取当前应用版本
+ (NSString *)appVersionString;
//存储文件名
+ (NSString *)cacheFileKeyNameWithUrlString:(NSString *)urlString method:(NSString *)method params:(NSDictionary *)params;
@end
