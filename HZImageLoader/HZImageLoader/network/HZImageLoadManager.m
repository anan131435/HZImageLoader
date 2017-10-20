//
//  EOCDownImageManager.m
//  EOCNEWS
//
//  Created by 韩志峰 on 2017/8/29.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import "HZImageLoadManager.h"
#import <SDWebImageManager.h>
#import "HZObject.h"

#define SDWEBIMAGE_MANAGER [SDWebImageManager sharedManager]

@interface EOCDownTask : NSObject
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) void (^complete) (UIImage *image,NSURL *url,NSError *error);
+ (instancetype)downTaskWithUrl:(NSURL *)url complete:(void (^) (UIImage *image,NSURL *imageUrl,NSError *error))complete;
@end


@implementation EOCDownTask

+ (instancetype)downTaskWithUrl:(NSURL *)url complete:(void (^)(UIImage *, NSURL *, NSError *))complete{
    EOCDownTask *task = [[EOCDownTask alloc] init];
    task.url = url;
    task.complete = complete;
    return task;
}

@end

@interface HZImageLoadManager ()
@property (nonatomic, strong) NSMutableDictionary  *downOperations;
@property (nonatomic, strong) NSMutableArray  *nextDownQueue;
@end

@implementation HZImageLoadManager
+ (instancetype)shareInstance{
    static HZImageLoadManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HZImageLoadManager alloc] init];
    });
    return manager;
}
- (UIImage *)loadImageWithUrl:(NSString *)url complete:(void (^)(UIImage *, NSURL *, NSError *))completeHandler{
    if (!url) {
        completeHandler(nil,nil,[NSError errorWithDomain:@"com.leo.news" code:0 userInfo:@{@"url":@"null"}]);
        return nil;
    }
    NSURL *imageUrl = [NSURL URLWithString:url];
    UIImage *cacheImage = [self cacheImageWithUrl:imageUrl];
    if (cacheImage) {
        if (completeHandler) {
            completeHandler(cacheImage,imageUrl,nil);
        }
        return cacheImage;
    }
    //磁盘缓存
//    SDImageCache *cache = [[SDWebImageManager sharedManager] imageCache];
//    NSString *cacheKey = [[SDWebImageManager sharedManager] cacheKeyForURL:imageUrl];
//    [cache diskImageExistsWithKey:cacheKey completion:^(BOOL isInCache) {
//        if (isInCache) {
//            [EOCObject runInBackground:^{
//                UIImage *image = [cache imageFromDiskCacheForKey:cacheKey];
//                if (completeHandler) {
//                    completeHandler(image,imageUrl,nil);
//                }
//            }];
//            return nil;
//        }
//    }];
    
    //正在下载
    if ([self.downOperations objectForKey:url]) {
        return nil;
    }
    if ([self.downOperations count] > 3) {
        [[self nextDownQueue] addObject:[EOCDownTask downTaskWithUrl:imageUrl complete:completeHandler]];
        return nil;
    }
    NSOperation *operation = [[SDWebImageManager sharedManager] downloadImageWithURL:imageUrl options:SDWebImageRefreshCached progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        if (completeHandler) {
            if (image) {
                //解压缩
            }
            completeHandler(image,imageURL,error);
        }
        [self.downOperations removeObjectForKey:url];
        EOCDownTask *task = [self.nextDownQueue firstObject];
        if (task) {
            [self.nextDownQueue removeObjectAtIndex:0];
        }
        [self loadImageWithUrl:[task.url absoluteString] complete:task.complete];
    }];
    [self.downOperations setObject:operation forKey:url];
    return nil;
}
- (UIImage *)cacheImageWithUrl:(NSURL *)url{
    SDImageCache *cache = [[SDWebImageManager sharedManager] imageCache];
    NSString *cacheKey = [[SDWebImageManager sharedManager] cacheKeyForURL:url];
    UIImage *image = [cache imageFromMemoryCacheForKey:cacheKey];
    return image;
    
}

- (NSMutableDictionary *)downOperations{
    if (!_downOperations) {
        _downOperations = [NSMutableDictionary dictionary];
    }
    return _downOperations;
}
- (NSMutableArray *)nextDownQueue{
    if (!_nextDownQueue) {
        _nextDownQueue = [NSMutableArray array];
    }
    return _nextDownQueue;
}




























@end
