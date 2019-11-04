//
//  NSDictionary+LWExtension.m
//  AirPurge
//
//  Created by wen on 2017/11/13.
//  Copyright © 2017年 wen. All rights reserved.
//

#import "NSDictionary+LWExtension.h"

@implementation NSDictionary (LWExtension)
/// 字典转JSON字符串
- (NSString *)jsonString {
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:self options:(NSJSONWritingPrettyPrinted) error:&error];
    if (error) {
        NSLog(@"%s -> JSONSerialization Error: %@", __FUNCTION__, error);
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (NSDictionary *)dictionaryWithjsonString:(NSString *)jString{
    NSData *jdata = [jString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error ;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jdata options:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"dictionaryWithjsonString error : %@",error.localizedDescription);
        return @{};
    }
    
    return dict;
    
}
@end
