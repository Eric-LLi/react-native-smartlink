//
//  UIImageView+LWColorAtPixel.m
//  moduleProject_YZY
//
//  Created by wen on 2017/8/11.
//  Copyright © 2017年 wen. All rights reserved.
//

#import "UIImageView+LWColorAtPixel.h"

@implementation UIImageView (LWColorAtPixel)

-(RGBAColor)colorAtPixel:(CGPoint)point{
    
    RGBAColor color = {0, 0, 0, 0};
    
    // Cancel if point is outside image coordinates
    if (!CGRectContainsPoint(CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height), point)) {
        return color;
    }
    
    
    //取整
    NSInteger pointX = trunc(point.x);
    NSInteger pointY = trunc(point.y);
    
    //获取自己的cgimage
    CGImageRef cgImage = self.image.CGImage;
    
    //获取图片的宽高
    NSUInteger width = self.frame.size.width;
    NSUInteger height = self.frame.size.height;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    int bytesPerPixel = 4;
    int bytesPerRow = bytesPerPixel * 1;
    NSUInteger bitsPerComponent = 8;
    unsigned char pixelData[4] = { 0, 0, 0, 0 };
    CGContextRef context = CGBitmapContextCreate(pixelData,
                                                 1,
                                                 1,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    
    // Draw the pixel we are interested in onto the bitmap context
    CGContextTranslateCTM(context, -pointX, pointY-(CGFloat)height);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, (CGFloat)width, (CGFloat)height), cgImage);
    CGContextRelease(context);
    
    // Convert color values [0..255] to floats [0.0..1.0]
    //    CGFloat red   = (CGFloat)pixelData[0] / 255.0f;
    //    CGFloat green = (CGFloat)pixelData[1] / 255.0f;
    //    CGFloat blue  = (CGFloat)pixelData[2] / 255.0f;
    //    CGFloat alpha = (CGFloat)pixelData[3] / 255.0f;
    //    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
    
    color.red = pixelData[0];
    color.green = pixelData[1];
    color.blue = pixelData[2];
    color.alpha = pixelData[3];
    return color;
}

@end
