//
//  EOCObject.h
//  EOCNEWS
//
//  Created by 韩志峰 on 2017/8/29.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HZObject : NSObject
+ (void)runInMain:(void (^) (void))block;
+ (void)runInBackground:(void (^) (void))block;
@end
