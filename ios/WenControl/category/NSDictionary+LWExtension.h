//
//  NSDictionary+LWExtension.h
//  AirPurge
//
//  Created by wen on 2017/11/13.
//  Copyright © 2017年 wen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (LWExtension)
/// 字典转JSON字符串
- (NSString *)jsonString;

/// json字符串转字典
+ (NSDictionary *)dictionaryWithjsonString:(NSString *)jString;
@end
