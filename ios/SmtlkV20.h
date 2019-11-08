//
//  SmtlkV20.h
//  SmartLink V2.0
//
//  Created by Peter on 14-3-4.
//  Copyright (c) 2014年 Peter. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SmtlkV20Event <NSObject>

/*发送AT命令的返回，出AT+WSCAN，另外AT+Z无返回*/
-(void)smtlkV20Event:(BOOL)success;
/*发送口令后返回：WIFI模块的IP地址、MAC地址、MID*/
-(void)smtlkV20EventDiscover:(NSString *)host MAC:(NSString *)mac MID:(NSString *)mid;
/*发送AT+WSCAN命令后的返回，每条返回包括搜到的一个路由器的SSID、MAC、加密方式*/
-(void)smtlkV20Event:(BOOL)success wscanSSid:(NSString *)ssid mac:(NSString *)mac security:(NSString *)secu;

@end

@class GCDAsyncUdpSocket;

@interface SmtlkV20 : NSObject

-(id)initWithDelegate:(id<SmtlkV20Event>)del;
/*发送口令发现WIFI模块*/
-(void)sendDiscovery:(NSString *)strDis;
-(void)sendATCMD:(NSString *)strCmd;



@end
