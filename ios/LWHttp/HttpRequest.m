//
//  HttpRequest.m
//  HttpRequest
//
//  Created by xtmac on 29/10/15.
//  Copyright (c) 2015年 xtmac. All rights reserved.
//

#import "HttpRequest.h"
#import <CommonCrypto/CommonDigest.h>
#import "LWControlHeader.h"
#import "LWBasicNetWorkTools.h"
#import "CocoaSecurity.h"
#import "NSString+Encryption.h"
#import "Base64.h"


#define RequestTypeGet      @"GET"
#define RequestTypePUT      @"PUT"
#define RequestTypePOST     @"POST"
#define RequestTypeDelete   @"DELETE"

//正式
#define Domain @"http://10.10.100.24:80/"






@interface HttpRequest ()<NSURLConnectionDataDelegate>

@property (copy, nonatomic) MyBlock myBlock;

@end

@implementation HttpRequest{
    NSMutableData *_httpReceiveData;
}

-(id)init{
    if (self = [super init]) {
        _httpReceiveData = [[NSMutableData alloc] init];
    }
    return self;
}


#pragma mark - 配置wifi
+(void)connectModuleWithWiFiPwd:(NSString *)pwd
                    withNetSSID:(NSString *)netssid
                       withSSID:(NSString *)ssid didLoadData:(MyBlock)block{
    do {
        
        // 生成aes 加密需要的密钥和向量
        NSString *md5Key = [self getAESKeyWithLocalIP:[LWNSHelper getIPAddress] withDeviceSSID:ssid];
        
        //拼装加密的原始字符串
        NSString *bodyStr = [self getOriginBobyStrWithNetSSID:netssid withPassword:pwd];
        
        //aes加密
        CocoaSecurityResult *result = [CocoaSecurity aesEncrypt:bodyStr hexKey:md5Key hexIv:md5Key];
        
        // 得到NSData 的body
        NSData *baseBodyData = [result.base64 dataUsingEncoding:NSUTF8StringEncoding];
        [self pritDataWith:baseBodyData];

        
        [LWBasicNetWorkToolsnextBtnDidClicked APNetRequestPOSTWithRequestURL:@"http://10.10.100.254" WithBodyData:baseBodyData withRequestBlock:^(id result, NSError *err) {
           
            NSData *resultData = (NSData *)result;
            NSString *resultStr = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
            NSString *decryptStr = [resultStr aesBase64StringDecryptWithHexKey:md5Key hexIv:md5Key];
            
            NSDictionary *dic = [LWNSHelper dictionaryWithJsonString:decryptStr];
            LWLog(@"config 返回：%@",decryptStr);
            block(dic,err);
            
        }];
        
    } while (0);
}


+(void)setRestartCommandwithSSID:(NSString *)ssid didLoadData:(MyBlock)block{
    do {
        
        // 生成aes 加密需要的密钥和向量
        NSString *md5Key = [self getAESKeyWithLocalIP:[LWNSHelper getIPAddress] withDeviceSSID:ssid];
        
        //拼装加密的原始字符串
        NSString *bodyStr = [self getRestartBobyStr];
        
        //aes加密
        CocoaSecurityResult *result = [CocoaSecurity aesEncrypt:bodyStr hexKey:md5Key hexIv:md5Key];
        
        
        // 得到NSData 的body
        NSData *baseBodyData = [result.base64 dataUsingEncoding:NSUTF8StringEncoding];
        [self pritDataWith:baseBodyData];
        
        
        [LWBasicNetWorkTools APNetRequestPOSTWithRequestURL:@"http://10.10.100.254" WithBodyData:baseBodyData withRequestBlock:^(id result, NSError *err) {
            
            NSData *resultData = (NSData *)result;
            NSString *resultStr = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
            NSString *decryptStr = [resultStr aesBase64StringDecryptWithHexKey:md5Key hexIv:md5Key];
            
            NSDictionary *dic = [LWNSHelper dictionaryWithJsonString:decryptStr];
            LWLog(@"设置重启命令返回 %@",decryptStr);
            block(dic,err);
            
        }];
        
    } while (0);
}


#pragma mark - method

/**
 *  AES 密钥生成业务规则：手机IP+设备发出的SSID 进行 MD5 加密
 *  @param localIP  手机连接到设备热点时的iP地址
 *  @param ssid     设备发出的ssid
 *  @return  加密后的字符串
 */
+(NSString *)getAESKeyWithLocalIP:(NSString *)localIP withDeviceSSID:(NSString *)ssid{
    
    NSString *key = [NSString stringWithFormat:@"%@%@",localIP,ssid];
    NSString *md5Key = [[LWBasicNetWorkTools md5:key] uppercaseString];
    
    return md5Key;
}

/**
 * 组装原始的body字符串
 * @param netSSID 设备要配置的wifi SSID
 * @param password 设备要配置的wifi 密码
 * @return 返回json 字符串
 */
+(NSString *)getOriginBobyStrWithNetSSID:(NSString *)netSSID
                            withPassword:(NSString *)password{
    
    //字典格式  {"CID":30005,"PL":{"Password":"taobao888","SSID":"Xiaomi_Tao_2.4"}}
    
    NSMutableDictionary *bodyDic =  [NSMutableDictionary dictionary];
    NSMutableDictionary *mdic = [NSMutableDictionary dictionary];
    [mdic setObject:netSSID forKey:@"SSID"];
    [mdic setObject:password forKey:@"Password"];
    [bodyDic setObject:@30005 forKey: @"CID"];
    [bodyDic setObject:mdic forKey:@"PL"];
    
    NSString *bodyStr = [LWNSHelper convertToJsonData:bodyDic];
    return bodyStr;
}


+(NSString *)getRestartBobyStr{
    NSMutableDictionary *bodyDic =  [NSMutableDictionary dictionary];
    NSMutableDictionary *mdic = [NSMutableDictionary dictionary];
   
    [bodyDic setObject:@30007 forKey: @"CID"];
    [bodyDic setObject:mdic forKey:@"PL"];
    
    NSString *bodyStr = [LWNSHelper convertToJsonData:bodyDic];
    return bodyStr;
}








#pragma mark
#pragma mark 辅助工具

#pragma mark - 打印NSData 以十六进制字符串格式
+(void)pritDataWith:(NSData *)data{
    //输出aes加密后的字符
    NSArray *bytes  = [NSData dataToByte:data];
    NSString *logString = @"";
    for (NSInteger i = 0; i<bytes.count; i++) {
        logString=[logString stringByAppendingString:[NSString stringWithFormat:@" %02X",[bytes[i] intValue]]];
    }
    LWLog(@"data == %@",logString);
}




-(void)dealloc{
    NSLog(@"%s", __func__);
}


#pragma mark - 打印请求log
-(void)logRequest:(NSURLRequest *)request {
    
#ifdef DEBUG
    NSDictionary *headersDict = request.allHTTPHeaderFields;
    NSMutableString *requestString = @"".mutableCopy;
    
    // 发送，发射（火箭🚀）
    [requestString appendFormat:@"🚀 %@ %@ HTTP/1.1\n", request.HTTPMethod, request.URL.path];
    [requestString appendFormat:@"Host:%@:%@\n", request.URL.host, request.URL.port ?: @""];
    for (NSString *header in headersDict.allKeys) {
        [requestString appendFormat:@"%@:%@\n", header, headersDict[header]];
    }
    NSString *body = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
    [requestString appendFormat:@"\n%@", body];
    
    
    NSString *output = [requestString stringByReplacingOccurrencesOfString:@"\n" withString:@"\n🚀 "];
    LWLog(@"\nRequest: \n🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀[%@]\n%@\n🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀\n", request.URL.absoluteString, output);
    
    //    DDLogVerbose(@"\nRequest: \n🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀[%@]\n%@\n🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀\n", request.URL.absoluteString, output);
    
#endif
}

-(void)logResponse:(NSURLResponse *)oresponse object:(NSDictionary *)respDict {
#ifdef DEBUG
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)oresponse;
    NSMutableString *output = @"".mutableCopy;
    // 接收回复，收（手✋）
    [output appendFormat:@"✋ HTTP/1.1 %ld %@\n", (long)response.statusCode, [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode]];
    NSDictionary *headers = response.allHeaderFields;
    for (NSString *header in headers.allKeys) {
        [output appendFormat:@"%@:%@\n", header, headers[header]];
    }
    if (respDict && [respDict isKindOfClass:[NSDictionary class]]) {
        [output appendFormat:@"\n%@", [respDict jsonString]];
    }
    NSString *outputStr = [output stringByReplacingOccurrencesOfString:@"\n" withString:@"\n✋ "];
    LWLog(@"\nResponse: \n✋✋✋✋✋✋✋✋✋✋[%@]:\n%@\n✋✋✋✋✋✋✋✋✋✋\n", response.URL.absoluteString, outputStr);
    //    DDLogVerbose(@"\nResponse: \n✋✋✋✋✋✋✋✋✋✋[%@]:\n%@\n✋✋✋✋✋✋✋✋✋✋\n", response.URL.absoluteString, outputStr);
#endif
}

@end
