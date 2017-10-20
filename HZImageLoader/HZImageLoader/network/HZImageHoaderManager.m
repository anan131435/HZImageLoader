//
//  HZImageHoaderManager.m
//  EOCNEWS
//
//  Created by 韩志峰 on 2017/10/20.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import "HZImageHoaderManager.h"
#import "HZCache.h"

@implementation HZImageHoaderManager
- (UIImage *)loadImageWithUrl:(NSString *)imageUrl complete:(loadImageCompletionHandler)completeHandler{
    if (!imageUrl || imageUrl.length == 0) {
        if (completeHandler) {
            completeHandler(nil,[NSError errorWithDomain:@"com.imageloaderManager" code:-1 userInfo:@{@"error":@"imageUrl nil"}]);
        }
        return nil;
    }
    
    return nil;
}
@end
