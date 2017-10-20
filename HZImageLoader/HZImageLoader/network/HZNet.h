//
//  EOCNet.h
//  EOCNEWS
//
//  Created by 韩志峰 on 2017/8/28.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HZNet : NSObject
+ (instancetype)shareManager;
- (void)testLoadMore;
- (void)loadNewsStart:(int)start complete:(void (^)(NSDictionary *object))completeBlock failed:(void(^)(NSError *error))failedBlock;
- (void)loadNews:(void (^)(id jsonObjec))completeBlock failed:(void (^)(NSError *error))failureHandler;
@end
