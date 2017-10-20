//
//  HZImageHoaderManager.h
//  EOCNEWS
//
//  Created by 韩志峰 on 2017/10/20.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^loadImageCompletionHandler)(UIImage *image,NSError *error);

@interface HZImageHoaderManager : NSObject
+ (instancetype)shrarImageLoaderManager;
- (UIImage *)loadImageWithUrl:(NSString *)imageUrl complete:(loadImageCompletionHandler)completeHandler;
@end
