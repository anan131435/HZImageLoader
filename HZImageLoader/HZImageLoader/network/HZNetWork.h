//
//  EOCNetWork.h
//  EOCNEWS
//
//  Created by 韩志峰 on 2017/8/29.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HZNetWork : NSObject
+ (instancetype)shareManager;
- (void)loadStart:(int)start pageCount:(int)pageCount complete:(void (^) (NSDictionary *response))successHandler failure:(void (^)(NSError *error))failureHandler;
@end
