//
//  LWBasicNetWorkTools.h
//  AirPurge
//
//  Created by wen on 2018/4/13.
//  Copyright © 2018年 wen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^requestBlock) (id result, NSError *err);

@interface LWBasicNetWorkTools : NSObject

+ (void) NetRequestPOSTWithRequestURL: (NSString *) requestURLString
                        WithParameter: (NSDictionary *) parameter
                     withRequestBlock: (requestBlock)block;

+ (void) NetRequestPutWithRequestURL: (NSString *) requestURLString
                       WithParameter: (NSDictionary *) parameter
                    withRequestBlock: (requestBlock)block;

+ (void) NetRequestGetWithRequestURL: (NSString *) requestURLString
                       WithParameter: (NSDictionary *) parameter
                    withRequestBlock: (requestBlock)block;


+ (void) APNetRequestPOSTWithRequestURL: (NSString *) requestURLString
                           WithBodyData: (NSData *)bodyData
                       withRequestBlock: (requestBlock)block;
+ (NSString*)md5:(NSString*)input;
@end
