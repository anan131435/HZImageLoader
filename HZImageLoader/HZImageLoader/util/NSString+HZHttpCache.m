//
//  NSString+HZHttpCache.m
//  HZHttpCache
//
//  Created by 韩志峰 on 2017/10/9.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import "NSString+HZHttpCache.h"
#import <CommonCrypto/CommonDigest.h>
@implementation NSString (HZHttpCache)
- (NSString *)md5Encrypt
{
    const char *original_str = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(original_str, (unsigned int)strlen(original_str), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < 16; i++)
    {
        [hash appendFormat:@"%02X", result[i]];
    }
    return [hash lowercaseString];
}
+ (NSString *)appVersionString{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}
//缓存文件的名字，名字用MD5进行加密
+ (NSString *)cacheFileKeyNameWithUrlString:(NSString *)urlString method:(NSString *)method params:(NSDictionary *)params{
    NSString *requestInfo = [NSString stringWithFormat:@"url:%@method:%@params:%@version:%@",urlString,method,params,[NSString appVersionString]];
    return [requestInfo md5Encrypt];
}

@end
