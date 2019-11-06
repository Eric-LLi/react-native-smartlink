//
//  UIImageView+LWColorAtPixel.h
//  moduleProject_YZY
//
//  Created by wen on 2017/8/11.
//  Copyright © 2017年 wen. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef struct{
    unsigned int red:8;
    unsigned int green:8;
    unsigned int blue:8;
    unsigned int alpha:8;
}RGBAColor;
@interface UIImageView (LWColorAtPixel)

/**
 * 根据图片取色
 *
 */
-(RGBAColor)colorAtPixel:(CGPoint)point;


@end
