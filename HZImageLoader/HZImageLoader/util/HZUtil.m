//
//  EOCUtil.m
//  EOCNEWS
//
//  Created by 韩志峰 on 2017/8/27.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import "HZUtil.h"
#import <CoreGraphics/CoreGraphics.h>

@implementation HZUtil
+ (void)runInMain:(void (^)())block{
    if ([[NSThread currentThread] isMainThread]) {
        block();
    }else{
        dispatch_async(dispatch_get_main_queue(), block);
    }
}
+ (void)runBackground:(void (^)())block{
    if ([[NSThread currentThread] isMainThread]) {
        dispatch_async(dispatch_get_global_queue(0, 0), block);
    }else{
        block();
    }
}
+ (CGSize)sizeForImage:(UIImage *)image fitWidth:(CGFloat)width{
    if (!image) {
        return CGSizeMake(0, 0);
    }
    return CGSizeMake(width, width/(image.size.width *image.scale) * (image.size.height * image.scale));
}
- (UIImage *)originalImage:(UIImage *)originalImage size:(CGSize)size{
    UIGraphicsBeginImageContext(size);
    //绘制整个图片，size小于原始图片size时会压缩图片质量
    [originalImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
+ (UIImage *)decodeImage:(UIImage *)image toSize:(CGSize)size{
    if (image == nil) { //preven cgbitmapContextCreateImage invalid context "0X0" error
        return nil;
    }
    @autoreleasepool { //do not decode animated images
        if (image.images != nil) {
            return image;
        }
        CGImageRef imageRef = image.CGImage;
        CGImageAlphaInfo alpha = CGImageGetAlphaInfo(imageRef);
        BOOL anyAlpha = (alpha == kCGImageAlphaLast || alpha == kCGImageAlphaFirst || alpha == kCGImageAlphaPremultipliedLast || alpha == kCGImageAlphaPremultipliedFirst);
        if (anyAlpha) {
            NSLog(@"图片解压失败，存在alpha通道");
            return image;
        }
        CGColorSpaceModel imageColorSpaceModel = CGColorSpaceGetModel(CGImageGetColorSpace(imageRef));
        CGColorSpaceRef colorSpaceRef = CGImageGetColorSpace(imageRef);
        BOOL unsupportedColorSpace = (imageColorSpaceModel == kCGColorSpaceModelUnknown || imageColorSpaceModel == kCGColorSpaceModelMonochrome || imageColorSpaceModel == kCGColorSpaceModelCMYK || imageColorSpaceModel == kCGColorSpaceModelIndexed);
        if (unsupportedColorSpace) {
            colorSpaceRef = CGColorSpaceCreateDeviceRGB();
        }
        size_t width = size.width;
        size_t height = size.height;
        NSUInteger bytesPerPixel = 4;
        NSInteger bytesPerRow = bytesPerPixel *width;
        NSUInteger bitsPerComponent = 8;
        CGContextRef context = CGBitmapContextCreate(NULL, width, height, bitsPerComponent, bytesPerRow, colorSpaceRef, kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipLast);
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
        CGImageRef imageRefWithoutAlpha = CGBitmapContextCreateImage(context);
        UIImage *imageWithOutAlpha = [UIImage imageWithCGImage:imageRefWithoutAlpha scale:image.scale orientation:image.imageOrientation];
        if (unsupportedColorSpace) {
            CGColorSpaceRelease(colorSpaceRef);
        }
        CGContextRelease(context);
        CGImageRelease(imageRefWithoutAlpha);
        NSLog(@"图片解压成功");
        return  imageWithOutAlpha;
        
    }
}
//UIGraphicGetCurrentContext只能在主线程，在后台线程创建bitMap context在后台线程解压
+ (CGContextRef)createARGBContextOfSize:(CGSize)size{
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    void *  bitmapData;
    int bitmapByteCount;
    int bitmapBytesPerRow;
    size_t pixelsWide = size.width;
    size_t pixelsHigh = size.height;
    bitmapBytesPerRow = (int)(pixelsWide * 4);
    bitmapByteCount = (int)(bitmapBytesPerRow * pixelsHigh);
    colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace == NULL) {
        fprintf(stderr, "Error allocating color space\n");
        return NULL;
    }
    NSMutableData *data = [NSMutableData dataWithLength:bitmapByteCount];
    bitmapData = [data mutableBytes];
    memset(bitmapData, 0, [data length]);
    context = CGBitmapContextCreate(bitmapData, pixelsWide, pixelsHigh, 8, bitmapBytesPerRow, colorSpace, kCGImageAlphaPremultipliedFirst);
    if (context == NULL || context == nil) {
        free(bitmapData);
        fprintf(stderr, "Context not created");
    }
    CGColorSpaceRelease(colorSpace);
    CFAutorelease(context);
    return context;
}

































@end
