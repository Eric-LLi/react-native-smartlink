//
//  MFUtil.m
//  PingAnMiFi
//
//  Created by Jeffrey on 2/24/16.
//  Copyright © 2016 PingAn. All rights reserved.
//

#import "MFUtil.h"
#import "sys/utsname.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#include <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#include <netdb.h>
#import <SystemConfiguration/SCNetworkReachability.h>
#import "getgateway.h"
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>


#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IOS_VPN         @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"
#define ROUNDUP(a) \
((a) > 0 ? (1 + (((a) - 1) | (sizeof(long) - 1))) : sizeof(long))

@implementation MFUtil

// 十六进制转换为普通字符串的。
+ (NSString *)stringFromHexString:(NSString *)hexString { //
    
    char *myBuffer = (char *)malloc((int)[hexString length] / 2 + 1);
    bzero(myBuffer, [hexString length] / 2 + 1);
    for (int i = 0; i < [hexString length] - 1; i += 2) {
        unsigned int anInt;
        NSString * hexCharStr = [hexString substringWithRange:NSMakeRange(i, 2)];
        NSScanner * scanner = [[NSScanner alloc] initWithString:hexCharStr];
        [scanner scanHexInt:&anInt];
        myBuffer[i / 2] = (char)anInt;
    }
    NSString *unicodeString = [NSString stringWithCString:myBuffer encoding:4];
    NSLog(@"------字符串=======%@",unicodeString);
    return unicodeString;
    
    
}

//普通字符串转换为十六进制的。

+ (NSString *)hexStringFromString:(NSString *)string{
    NSData *myD = [string dataUsingEncoding:NSUTF8StringEncoding];
    Byte *bytes = (Byte *)[myD bytes];
    //下面是Byte 转换为16进制。
    NSString *hexStr=@"";
    for(int i=0;i<[myD length];i++)
        
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        
        if([newHexStr length]==1)
            
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        
        else
            
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr]; 
    } 
    return hexStr; 
}

#pragma mark - 获取设备当前网络IP地址
+ (NSString *)getIPAddress:(BOOL)preferIPv4
{
    NSArray *searchArray = preferIPv4 ?
    @[ IOS_VPN @"/" IP_ADDR_IPv4, IOS_VPN @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
    @[ IOS_VPN @"/" IP_ADDR_IPv6, IOS_VPN @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;
    
    NSDictionary *addresses = [self getIPAddresses];
    NSLog(@"addresses: %@", addresses);
    
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
     {
         address = addresses[key];
         //筛选出IP地址格式
         if([self isValidatIP:address]) *stop = YES;
     } ];
    return address ? address : @"0.0.0.0";
}

+ (BOOL)isValidatIP:(NSString *)ipAddress {
    if (ipAddress.length == 0) {
        return NO;
    }
    NSString *urlRegEx = @"^([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
    "([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
    "([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
    "([01]?\\d\\d?|2[0-4]\\d|25[0-5])$";
    
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:urlRegEx options:0 error:&error];
    
    if (regex != nil) {
        NSTextCheckingResult *firstMatch=[regex firstMatchInString:ipAddress options:0 range:NSMakeRange(0, [ipAddress length])];
        
        if (firstMatch) {
//            NSRange resultRange = [firstMatch rangeAtIndex:0];
//            NSString *result = [ipAddress substringWithRange:resultRange];
            //输出结果
//            NSLog(@"%@",result);
            return YES;
        }
    }
    return NO;
}

+ (NSDictionary *)getIPAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}


//获取当前wifi连接的ssid
+ (NSString *)currentWifiSSID {
    // Does not work on the simulator.
    NSString *ssid = nil;
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    for (NSString *ifnam in ifs) {
        
        CFDictionaryRef dictRef = CNCopyCurrentNetworkInfo((__bridge CFStringRef)(ifnam));
        NSDictionary *info = (__bridge_transfer id)dictRef;
        if (info[@"SSID"]) {
            ssid = info[@"SSID"];
        }
        
        if (info) {
            
            
            //            NSLog(@"network info -> %@", info);
            
            //            NSString *wifiName = [info objectForKey:(__bridge NSString *)kCNNetworkInfoKeySSID];
            //
            //            CFRelease(dictRef);
            //
        }
    }
    //    return @"PingAnMiFi_6669";
    return ssid?ssid:@"";
}

+(NSString *) getGatewayIPAddress {
    
    NSString *address = nil;
    
    /* net.route.0.inet.flags.gateway */
    int mib[] = {CTL_NET, PF_ROUTE, 0, AF_INET,
        NET_RT_FLAGS, RTF_GATEWAY};
    size_t l;
    char * buf, * p;
    struct rt_msghdr * rt;
    struct sockaddr * sa;
    struct sockaddr * sa_tab[RTAX_MAX];
    int i;
    int r = -1;
    
    if(sysctl(mib, sizeof(mib)/sizeof(int), 0, &l, 0, 0) < 0) {
        address = @"192.168.1.1";
    }
    
    if(l>0) {
        buf = malloc(l);
        if(sysctl(mib, sizeof(mib)/sizeof(int), buf, &l, 0, 0) < 0) {
            address = @"192.168.1.1";
        }
        
        for(p=buf; p<buf+l; p+=rt->rtm_msglen) {
            rt = (struct rt_msghdr *)p;
            sa = (struct sockaddr *)(rt + 1);
            for(i=0; i<RTAX_MAX; i++)
            {
                if(rt->rtm_addrs & (1 << i)) {
                    sa_tab[i] = sa;
                    sa = (struct sockaddr *)((char *)sa + ROUNDUP(sa->sa_len));
                } else {
                    sa_tab[i] = NULL;
                }
            }
            
            if( ((rt->rtm_addrs & (RTA_DST|RTA_GATEWAY)) == (RTA_DST|RTA_GATEWAY))
               && sa_tab[RTAX_DST]->sa_family == AF_INET
               && sa_tab[RTAX_GATEWAY]->sa_family == AF_INET) {
                unsigned char octet[4]  = {0,0,0,0};
                int i;
                for (i=0; i<4; i++){
                    octet[i] = ( ((struct sockaddr_in *)(sa_tab[RTAX_GATEWAY]))->sin_addr.s_addr >> (i*8) ) & 0xFF;
                }
                if(((struct sockaddr_in *)sa_tab[RTAX_DST])->sin_addr.s_addr == 0) {
                    in_addr_t addr = ((struct sockaddr_in *)(sa_tab[RTAX_GATEWAY]))->sin_addr.s_addr;
                    r = 0;
                    address = [NSString stringWithFormat:@"%s", inet_ntoa(*((struct in_addr*)&addr))];
                    NSLog(@"\naddress%@",address);
                    break;
                }
            }
        }
        free(buf);
    }
    return address;
}

//+(NSInteger) getIpV4Value:(NSString *) sIP
//{
//    byte[] addr = getIpV4Bytes(ipOrMask);
//    int address1  = addr[3] & 0xFF;
//    address1 |= ((addr[2] << 8) & 0xFF00);
//    address1 |= ((addr[1] << 16) & 0xFF0000);
//    address1 |= ((addr[0] << 24) & 0xFF000000);
//    return address1;
//}
//
//+(NSData *) getIpV4Bytes:(NSString *) sIP
//{
//    NSArray *b = [sIP componentsSeparatedByString:@"."];
//    Byte bytes[[b count]];
//
//    for (int index = 0; index < [b count]; index++)
//    {
//        NSString *seg = (NSString *) b[index];
//        Byte byteOne = (Byte)([seg integerValue] & 0xff);
//        bytes[index] = byteOne;
//    }
//
//    NSData *adata = [[NSData alloc] initWithBytes:byte length:24];
//
//    try
//    {
//        String[] addrs = ipOrMask.split("\\.");
//        int length = addrs.length;
//        byte[] addr = new byte[length];
//        for (int index = 0; index < length; index++)
//        {
//            addr[index] = (byte) (Integer.parseInt(addrs[index]) & 0xff);
//        }
//        return addr;
//    }
//    catch (Exception e)
//    {
//    }
//    return new byte[4];
//}
//}

+ (BOOL) isWiFiConnected
{
    NSCountedSet * cset = [[NSCountedSet alloc] init];
       struct ifaddrs *interfaces;
       if( ! getifaddrs(&interfaces) ) {
           for( struct ifaddrs *interface = interfaces; interface; interface = interface->ifa_next) {
               if ( (interface->ifa_flags & IFF_UP) == IFF_UP ) {
                   [cset addObject:[NSString stringWithUTF8String:interface->ifa_name]];
               }
           }
       }
       return [cset countForObject:@"awdl0"] > 1 ? YES : NO;
//    UIApplication *app = [UIApplication sharedApplication];
//    NSArray *children = [[[app valueForKeyPath:@"statusBar"] valueForKeyPath:@"foregroundView"] subviews];
//    //获得到网络返回码
//    for (id child in children) {
//        if ([child isKindOfClass:NSClassFromString(@"UIStatusBarDataNetworkItemView")]) {
//            int netType = [[child valueForKeyPath:@"dataNetworkType"] intValue];
//            if (netType == 1) {
//                DLog(@"type:%@, 2G", @(netType));
//                return NO;
//            }
//            else if (netType == 2) {
//                DLog(@"type:%@, 3G", @(netType));
//
//                return NO;
//            }
//            else if (netType == 3) {
//                DLog(@"type:%@, 4G", @(netType));
//
//                return NO;
//            }
//            else if (netType == 5){
//                DLog(@"type:%@, Wifi", @(netType));
//                return YES;
//            }
//            // 1，2，3，5 分别对应的网络状态是2G、3G、4G及WIFI。(需要判断当前网络类型写个switch 判断就OK)
//        }
//    }
//    DLog(@"not open network or no net work");
}

+ (NSString *)localIP
{
    NSString *address = nil;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while (temp_addr != NULL)
        {
            if( temp_addr->ifa_addr->sa_family == AF_INET)
            {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
                {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    // Free memory
    freeifaddrs(interfaces);
    
    if (!address || [address length] == 0)
    {
        address = @"127.0.0.1";
    }
    
    assert(address && [address length] > 0);
    return address;
}

+ (NSString *) routerIp {
    
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        //*/
        while(temp_addr != NULL)
        /*/
         int i=255;
         while((i--)>0)
         //*/
        {
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
                {
                    // Get NSString from C String //ifa_addr
                    //ifa->ifa_dstaddr is the broadcast address, which explains the "255's"
                    //                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_dstaddr)->sin_addr)];
                    
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    
                    //routerIP----192.168.1.255 广播地址
                    NSLog(@"broadcast address--%@",[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_dstaddr)->sin_addr)]);
                    //--192.168.1.106 本机地址
                    NSLog(@"local device ip--%@",[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)]);
                    //--255.255.255.0 子网掩码地址
                    NSLog(@"netmask--%@",[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr)]);
                    //--en0 端口地址
                    NSLog(@"interface--%@",[NSString stringWithUTF8String:temp_addr->ifa_name]);
                    
                }
                
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    // Free memory
    freeifaddrs(interfaces);
    
    
    
    in_addr_t i =inet_addr([address cStringUsingEncoding:NSUTF8StringEncoding]);
    in_addr_t* x =&i;
    
    
    unsigned char *s=getdefaultgateway(x);
    NSString *ip=[NSString stringWithFormat:@"%d.%d.%d.%d",s[0],s[1],s[2],s[3]];
    
    NSLog(@"路由器地址-----%@",ip);
    return ip;
}
@end
