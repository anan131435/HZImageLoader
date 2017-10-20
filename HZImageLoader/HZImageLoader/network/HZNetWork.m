//
//  EOCNetWork.m
//  EOCNEWS
//
//  Created by 韩志峰 on 2017/8/29.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import "HZNetWork.h"
#import <AFNetworking.h>
#import "HZObject.h"


@interface HZNetWork ()
@property (nonatomic, strong) dispatch_queue_t  netQueue;
@end

@implementation HZNetWork
+ (instancetype)shareManager{
    static HZNetWork *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HZNetWork alloc] init];
    });
    return manager;
}
- (void)loadStart:(int)start pageCount:(int)pageCount complete:(void (^)(NSDictionary *))successHandler failure:(void (^)(NSError *))failureHandler{
    [self runInQueue:^{
        [self loadMoreNewsStart:start pagecount:pageCount complete:successHandler failure:failureHandler];
    }];
}
- (void)loadMoreNewsStart:(int)start pagecount:(int)count complete:(void (^) (NSDictionary *object))successHandler failure:(void (^) (NSError *))failure{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self diskCachePath:start]]) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSData *data = [NSData dataWithContentsOfFile:[self diskCachePath:start]];
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            if ([json isKindOfClass:[NSDictionary class]]) {
                successHandler(json);
            }
        });
        return;
    }
    //网络请求
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager GET:@"url" parameters:@{@"":@""} progress:^(NSProgress * _Nonnull downloadProgress) {
        NSLog(@"%@",downloadProgress);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *responsDict = responseObject;
        if ([responseObject isKindOfClass:[NSData class]]) {
            responsDict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:nil];
        }
        if (successHandler) {
            successHandler(responsDict);
            [HZObject runInBackground:^{
                [responsDict writeToFile:[self diskCachePath:start] atomically:YES];
            }];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(error);
        }
    }];
    
}
- (NSString *)diskCachePath:(int)start{
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *fileName = [NSString stringWithFormat:@"news%d",start];
    return [cachePath stringByAppendingPathComponent:fileName];
}
- (dispatch_queue_t)netQueue{
    if (!_netQueue) {
        _netQueue = dispatch_queue_create(0, DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL);
    }
    return _netQueue;
}
- (void)runInQueue:(void (^) (void))block{
    dispatch_async(self.netQueue, block);
}
@end
