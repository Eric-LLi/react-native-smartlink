//
//  HttpRequest.h
//  HttpRequest
//
//  Created by wen on 29/10/15.
//  Copyright (c) 2015年 wen. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ErrInfo(ErrCode) [HttpRequest getErrorInfoWithErrorCode:(ErrCode)]

typedef void (^MyBlock) (id result, NSError *err);


@interface HttpRequest : NSObject

/**
 * 配网请求接口
 * @param pwd 设备要连接的wifi 密码
 * @param netssid  设备要连接的wifi SSID
 * @param ssid   设备发出来的热点
 */
+(void)connectModuleWithWiFiPwd:(NSString *)pwd
                    withNetSSID:(NSString *)netssid
                       withSSID:(NSString *)ssid didLoadData:(MyBlock)block;

+(void)setRestartCommandwithSSID:(NSString *)ssid didLoadData:(MyBlock)block;

@end
