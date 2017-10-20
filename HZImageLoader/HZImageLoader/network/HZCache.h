//
//  HZCache.h
//  EOCNEWS
//
//  Created by 韩志峰 on 2017/10/20.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^imageCacheCompleteHandler)(void);
typedef void(^deleteOldFileHandler)(void);
@interface HZCache : NSObject
@property (nonatomic, assign) NSUInteger maxCacheSize; ///< 最大缓存空间 bytes
@property (nonatomic, assign,readonly) NSUInteger maxCacheAge;
+ (instancetype)shareCache;
#pragma mark - Store Operation async
- (void)storeImage:(UIImage *)image toDisk:(BOOL)toDisk forKey:(NSString *)key completion:(imageCacheCompleteHandler)completeHandler;
#pragma mark - Query Operation Sync
- (UIImage *)imageFromCachedForKey:(NSString *)key;
#pragma mark - cache Clean Operation
- (void)clearMemory;
- (void)deleteOldFiles;
@end
