//
//  MFUtil.h
//  PingAnMiFi
//
//  Created by Jeffrey on 2/24/16.
//  Copyright © 2016 PingAn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MFUtil : NSObject

+ (NSString *)stringFromHexString:(NSString *)hexString;
+ (NSString *)hexStringFromString:(NSString *)string;

+ (NSString *)getIPAddress:(BOOL)preferIPv4;

+ (NSString *) getGatewayIPAddress;
+ (NSString *) localIP;
+ (NSString *) routerIp;

+ (BOOL) isWiFiConnected;
@end
