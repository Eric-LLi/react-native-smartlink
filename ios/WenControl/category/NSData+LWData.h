//
//  NSData+LWData.h
//  moduleProject_YZY
//
//  Created by wen on 2017/8/11.
//  Copyright © 2017年 wen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (LWData)
/**
 *  NSdata转为Byte数组
 */
+ (NSArray *)dataToByte:(NSData *)data;

/**
 *  十六进制表示的字符串转为NSData
 */
+ (NSData*)stringToData:(NSString *)hexString;


@end
