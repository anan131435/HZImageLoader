//
//  EOCObject.m
//  EOCNEWS
//
//  Created by 韩志峰 on 2017/8/29.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import "HZObject.h"

@implementation HZObject
+ (void)runInMain:(void (^)(void))block{
    if ([[NSThread currentThread] isMainThread]) {
        block();
    }else{
        dispatch_async(dispatch_get_main_queue(), block);
    }
}
+ (void)runInBackground:(void (^)(void))block{
    if ([[NSThread currentThread] isMainThread]) {
        dispatch_async(dispatch_get_global_queue(0, 0), block);
    }else{
        block();
    }
}
@end
