//
//  EOCDownImageManager.h
//  EOCNEWS
//
//  Created by 韩志峰 on 2017/8/29.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface HZImageLoadManager : NSObject
+ (instancetype)shareInstance;
- (UIImage *)loadImageWithUrl:(NSString *)url complete:(void (^) (UIImage *image,NSURL *imageUrl,NSError *error))block;
@end
