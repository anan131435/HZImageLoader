//
//  EOCNet.m
//  EOCNEWS
//
//  Created by 韩志峰 on 2017/8/28.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import "HZNet.h"
#import <AFNetworking.h>
#import "HZUtil.h"
#define SERVER_URL_NEWS             @"http://api.jisuapi.com/news/get"

#define CHANNEL_TOUTIAO     @"头条"
#define CHANNEL_TIYUE       @"体育"
#define CHANNEL_JUNSHI      @"军事"

@interface HZNet ()
@property (nonatomic, strong) dispatch_queue_t  netQueue;
@end

@implementation HZNet
+ (instancetype)shareManager{
    static HZNet *_netManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _netManager = [[HZNet alloc] init];
    });
    return _netManager;
}
- (void)loadNewsStart:(int)start complete:(void (^)(NSDictionary *))completeBlock failed:(void (^)(NSError *))failedBlock{
    
    [self runInQueue:^{
        [self loadMoreNews:SERVER_URL_NEWS channel:CHANNEL_TOUTIAO start:start num:10 complete:completeBlock failure:failedBlock];
    }];
}

- (void)loadMoreNews:(NSString *)url channel:(NSString *)channel start:(int)start num:(int)count complete:(void (^)(NSDictionary *jsonObject))successHandler failure:(void (^) (NSError *error))failure{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self dataPathWithStart:start]]) {//存在缓存数据
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            if (successHandler) {
                NSData *data = [NSData dataWithContentsOfFile:[self dataPathWithStart:start]];
                NSDictionary *objectDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                successHandler(objectDict);
            }
        });
        return;
    }
    //网络获取
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    NSDictionary *params = @{@"channel":channel,@"num":@(count),@"start":@(start)};
    [manager GET:SERVER_URL_NEWS parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dict = responseObject;
        if ([responseObject isKindOfClass:[NSData class]]) {
            dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:nil];
        }
        if (successHandler) {
            successHandler(dict);
            [HZUtil runBackground:^{
                [responseObject writeToFile:[self dataPathWithStart:start] atomically:YES];
            }];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(error);
        }
    }];
    
    
    
}
//返回缓存文件的路径
- (NSString *)dataPathWithStart:(int)start{
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *fileName = [@"news" stringByAppendingFormat:@"%d",start];
    return [filePath stringByAppendingPathComponent:fileName];
}
- (dispatch_queue_t)netQueue{
    if (!_netQueue) {
        _netQueue = dispatch_queue_create("com.net.que", DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL);
    }
    return _netQueue;
}
- (void)runInQueue:(void (^) ())block{
    dispatch_async(self.netQueue, block);
}









































@end
