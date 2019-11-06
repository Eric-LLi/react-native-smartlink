//
//  NSData+LWData.m
//  moduleProject_YZY
//
//  Created by wen on 2017/8/11.
//  Copyright © 2017年 wen. All rights reserved.
//

#import "NSData+LWData.h"

@implementation NSData (LWData)

+ (NSArray *)dataToByte:(NSData *)data{
    
    Byte *byte = (Byte *)[data bytes];
    
    NSMutableArray *mArr = [NSMutableArray array];
    
    for (int i = 0; i<data.length; i++) {
        
        [mArr addObject:@(byte[i])];
        
    }
    
    return mArr;
}

+ (NSData*)stringToData:(NSString *)hexString {
    
    NSUInteger len = hexString.length / 2;
    const char *hexCode = [hexString UTF8String];
    char * bytes = (char *)malloc(len);
    
    char *pos = (char *)hexCode;
    for (NSUInteger i = 0; i < hexString.length / 2; i++) {
        sscanf(pos, "%2hhx", &bytes[i]);
        pos += 2 * sizeof(char);
    }
    
    NSData * data = [[NSData alloc] initWithBytes:bytes length:len];
    
    free(bytes);
    return data;
}

@end
