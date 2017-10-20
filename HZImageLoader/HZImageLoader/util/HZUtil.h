//
//  EOCUtil.h
//  EOCNEWS
//
//  Created by 韩志峰 on 2017/8/27.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>

#define ENABLE_IMAGEDECODE       1     //开启图片解压
#define ENABLE_LIMIT_MAX_DOWNQUEUE      1     //限制最大下载数
#define ENABLE_BACKGROUND_CORETEXT       1     //使用后台coreText绘制
#define ENABLE_IMAGEDECODE       1     //开启图片解压
#define  EOCWEAKSELF __weak typeof(self) weakSelf = self
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height


@interface HZUtil : NSObject
//在主线程运行
+ (void)runInMain:(void (^) ())block;
//在后台线程运行
+ (void)runBackground:(void (^) ())block;
//图片宽高适配
+ (CGSize)sizeForImage:(UIImage *)image fitWidth:(CGFloat)width;
//图片解压
+(UIImage *)decodeImage:(UIImage *)image toSize:(CGSize)size;
//创建位图上下文
+ (CGContextRef)createARGBContextOfSize:(CGSize)size;
//压缩图片
- (UIImage *)originalImage:(UIImage *)originalImage size:(CGSize)size;

@end
