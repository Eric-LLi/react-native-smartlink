//
//  LWBasicNetWorkTools.m
//  AirPurge
//
//  Created by wen on 2018/4/13.
//  Copyright © 2018年 wen. All rights reserved.
//  

#import "LWBasicNetWorkTools.h"
#import "LWControlHeader.h"
//#import <CocoaLumberjack/CocoaLumberjack.h>
#import "AFNetworking.h"
//#import "LDLog.h"
#import <CommonCrypto/CommonDigest.h>


//NSString * const ServerBaseURL = @"http://111.230.176.55:8080";
NSString * const ServerBaseURL = @"http://10.10.100.254/24:80";


@implementation LWBasicNetWorkTools
    
#pragma mark - 监测网络的可链接性
+ (BOOL) netWorkReachability{
    __block BOOL netState = NO;
    //1.创建网络监测者
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    [manager startMonitoring];
    
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        //这里是监测到网络改变的block  可以写成switch方便
        //在里面可以随便写事件
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                LWLog(@"未知网络状态");
                netState = YES;
                break;
            case AFNetworkReachabilityStatusNotReachable:
                LWLog(@"无网络");
                netState = NO;
                break;
                
            case AFNetworkReachabilityStatusReachableViaWWAN:
                LWLog(@"蜂窝数据网");
                netState = YES;
                break;
                
            case AFNetworkReachabilityStatusReachableViaWiFi:
                LWLog(@"WiFi网络");
                netState = YES;
                
                break;
                
            default:
                break;
        }
    }] ;
    return netState;
}

+(AFHTTPSessionManager *)getManager
{
    NSURL *baseURL = [NSURL URLWithString:ServerBaseURL];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];

    
    manager.requestSerializer.timeoutInterval = kTimeOutInterval;
    
    manager.requestSerializer  = [[AFJSONRequestSerializer alloc] init];
    [manager.requestSerializer setValue:@"text/plain;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [manager.requestSerializer setValue:@"UTF-8" forHTTPHeaderField:@"Charset"];
    [manager.requestSerializer setValue:@"true" forHTTPHeaderField:@"Keep-Alive"];

   
  
    
    manager.responseSerializer =  [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html", nil ];

    return manager;
}


#pragma mark - POST请求方式

+ (void) APNetRequestPOSTWithRequestURL: (NSString *) requestURLString
                        WithBodyData: (NSData *)bodyData
                     withRequestBlock: (requestBlock)block{
    // 创建请求类
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"POST" URLString:requestURLString parameters:nil error:nil];
    request.timeoutInterval = 10000;
    [request setHTTPBody:bodyData];
    
    [request setValue:@"text/plain;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    [self logRequest:request];

    
    AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
    responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",
                                                 @"text/html",
                                                 @"text/json",
                                                 @"text/javascript",
                                                 @"text/plain",
                                                 nil];
    manager.responseSerializer = responseSerializer;
    
    [[manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        
        block(responseObject,error);
        [self logResponse:response object:responseObject];
        
    }] resume] ;
    
    
}







+ (void) NetRequestPOSTWithRequestURL: (NSString *) requestURLString
                        WithParameter: (NSDictionary *) parameter
                     withRequestBlock: (requestBlock)block{
    // 创建请求类
    AFHTTPSessionManager *manager = [self getManager];
  NSURLSessionDataTask *task =  [manager POST:requestURLString
       parameters:parameter
         progress:^(NSProgress * _Nonnull uploadProgress) {
             // 这里可以获取到目前数据请求的进度
             
         } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
             // 请求成功
             [self logResponse:task.response object:responseObject];

             if(responseObject){
                 block(responseObject,nil);
             } else {
                 block(@{@"msg":@"暂无数据"},nil);
             }
         } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
             // 请求失败
             [self logResponse:task.response object:nil];

             block(nil,error);
         }];
    
    [self logRequest:task.originalRequest];

}

+ (void)NetRequestPutWithRequestURL: (NSString *) requestURLString
                       WithParameter: (NSDictionary *) parameter
                    withRequestBlock: (requestBlock)block{
    // 创建请求类
    AFHTTPSessionManager *manager = [self getManager];
    [manager PUT:requestURLString parameters:parameter success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // 请求成功
        [self logRequest:task.originalRequest];
        if(responseObject){
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
            block(dict,nil);
        }else{
            block(@{@"msg":@"暂无数据"},nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self logRequest:task.originalRequest];
        
        
        block(nil,error);
    }];
}


+ (void)NetRequestGetWithRequestURL: (NSString *) requestURLString
                       WithParameter: (NSDictionary *) parameter
                    withRequestBlock: (requestBlock)block{
    // 创建请求类
    AFHTTPSessionManager *manager = [self getManager];
    
  NSURLSessionDataTask *task =  [manager GET:requestURLString parameters:parameter progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
       
      [self logResponse:task.response object:responseObject];
        
      if(responseObject){
          block(responseObject,nil);
      } else {
          block(@{@"msg":@"暂无数据"},nil);
      }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self logResponse:task.response object:nil];

        block(nil,error);
    }];
    [self logRequest:task.originalRequest];
}




#pragma mark - 辅助工具
+ (NSString*)md5:(NSString*)input{
    const char *cStr = [input UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    return  output;
}






#pragma mark - 打印请求log
+ (void)logRequest:(NSURLRequest *)request {
    
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

+ (void)logResponse:(NSURLResponse *)oresponse object:(NSDictionary *)respDict {
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
