//
//  LWNSHelper.m
//  AirPurge
//
//  Created by wen on 2017/9/8.
//  Copyright © 2017年 wen. All rights reserved.
//

#import "LWNSHelper.h"
#import <CommonCrypto/CommonDigest.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
@implementation LWNSHelper
#pragma mark - 注册键盘弹起及隐藏的通知
+(void)registerForKeyBoardNotificationsWithDelegate:(id)delegate
                             keyboardWasShownMethod:(SEL)shownAction
                            keyboardWasHiddenMethod:(SEL)hiddenAction{
    [[NSNotificationCenter defaultCenter] addObserver:delegate selector:shownAction name: UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]  addObserver:delegate selector:hiddenAction name: UIKeyboardWillHideNotification object:nil];
}

#pragma mark 判断两个NSdate 是否为同一天
+(BOOL)isSameDayWithDate1:(NSDate*)date1 date2:(NSDate *)date2
{
    if (date1==nil) return NO;
    if (date2==nil) return NO;
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:date1];
    NSDate *today = [cal dateFromComponents:components];
    components = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:date2];
    NSDate *otherDate = [cal dateFromComponents:components];
    if([today isEqualToDate:otherDate])
        return YES;
    
    return NO;
}


#pragma mark 将NSString转换成十六进制的字符串
+(NSString *)convertStringToHexStr:(NSString *)str {
    if (!str || [str length] == 0) {
        return @"";
    }
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    
    return string;
}

#pragma mark 将十六进制的字符串转换成NSString
+(NSString *)convertHexStrToString:(NSString *)str {
    if (!str || [str length] == 0) {
        return nil;
    }
    
    NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:8];
    NSRange range;
    if ([str length] % 2 == 0) {
        range = NSMakeRange(0, 2);
    } else {
        range = NSMakeRange(0, 1);
    }
    for (NSInteger i = range.location; i < [str length]; i += 2) {
        unsigned int anInt;
        NSString *hexCharStr = [str substringWithRange:range];
        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];
        
        [scanner scanHexInt:&anInt];
        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
        [hexData appendData:entity];
        
        range.location += range.length;
        range.length = 2;
    }
    NSString *string = [[NSString alloc]initWithData:hexData encoding:NSUTF8StringEncoding];
    return string;
}


#pragma mark-根据一个int数据来配出重复的星期
+(NSArray *)configWeekArrWithInt:(int)week
{
    NSMutableArray *weekArr=[NSMutableArray array];
    if ((week&1)==1) {
        [weekArr addObject:@"周日"];
    }
    if (((week>>6)&1)==1) {
        [weekArr addObject:@"周六"];
    }
    if (((week>>5)&1)==1) {
        [weekArr addObject:@"周五"];
    }
    if (((week>>4)&1)==1) {
        [weekArr addObject:@"周四"];
    }
    if (((week>>3)&1)==1) {
        [weekArr addObject:@"周三"];
    }
    if (((week>>2)&1)==1) {
        [weekArr addObject:@"周二"];
    }
    if (((week>>1)&1)==1) {
        [weekArr addObject:@"周一"];
    }
    
    return weekArr;
}

+(NSString *)configRepeatStrWithArr:(NSArray *)weekArr
{
    NSString *weekStr;
    if (weekArr.count==7) {
        weekStr=@"每天";
    }
    else if(weekArr.count==5){
        
        BOOL isWeekend=NO;
        NSString *dataStr=@"周";
        for (int i=0; i<weekArr.count; i++) {
            NSString *tempStr=[weekArr objectAtIndex:i];
            NSString *str;
            if (tempStr.length>=2) {
                str=[tempStr substringWithRange:NSMakeRange(0, 1)];
            }
            dataStr=[dataStr stringByAppendingString:str];
            if ([tempStr rangeOfString:@"周日"].length>0) {
                isWeekend=YES;
            }
            if ([tempStr rangeOfString:@"周六"].length>0) {
                isWeekend=YES;
            }
        }
        
        if (isWeekend) {
            weekStr=dataStr;
        }
        else{
            weekStr=@"工作日";
        }
    }
    else if (weekArr.count==2)
    {
        BOOL isWeekend=NO;
        NSString *dataStr=@"周";
        for (int i=0; i<weekArr.count; i++) {
            NSString *tempStr=[weekArr objectAtIndex:i];
            NSString *str;
            if (tempStr.length>=2) {
                str=[tempStr substringWithRange:NSMakeRange(0, 1)];
            }
            dataStr=[dataStr stringByAppendingString:str];
            
            
            
            if (!([tempStr rangeOfString:@"周日"].length>0)&&!([tempStr rangeOfString:@"周六"].length>0)) {
                isWeekend=YES;
            }
            
        }
        
        if (isWeekend) {
            weekStr=dataStr;
        }
        else{
            weekStr=@"周末";
        }
    }
    else{
        NSString *dataStr=@"周";
        for (int i=0; i<weekArr.count; i++) {
            NSString *tempStr=[weekArr objectAtIndex:i];
            NSString *str;
            if (tempStr.length>=2) {
                str=[tempStr substringWithRange:NSMakeRange(0, 1)];
            }
            dataStr=[dataStr stringByAppendingString:str];
            
        }
        
        weekStr=dataStr;
    }
    
    return weekStr;
}

+(UIBarButtonItem *)configRightBtnWith:(id)delegate action:(SEL)action text:(NSString *)text
{
    //右边按钮文字按钮
    UIBarButtonItem *buttonItem=[[UIBarButtonItem alloc]initWithTitle:text style:UIBarButtonItemStyleDone target:delegate action:action];
    //    [buttonItem setTintColor:UIColorFromRGB(0x34abff)];
    [buttonItem setTintColor:[UIColor whiteColor]];
    return buttonItem;
}
+(UIBarButtonItem *)configImageRightBtnWith:(id)delegate action:(SEL)action image:(UIImage *)image
{
    //右边按钮图片按钮
    UIButton *btn=[UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame=CGRectMake(0, 0, 60, 40);
    [btn setImage:image forState:UIControlStateNormal];
    [btn addTarget:delegate action:action forControlEvents:UIControlEventTouchUpInside];
    btn.imageEdgeInsets=UIEdgeInsetsMake(0, 0, 0, -30);
    UIBarButtonItem *right=[[UIBarButtonItem alloc]initWithCustomView:btn];
    return right;
}

+(UIBarButtonItem *)configImageLeftItemWith:(id)delegate action:(SEL)action image:(UIImage *)image
{
    
    UIButton *btn=[UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame=CGRectMake(0, 0, 60, 40);
    [btn setImage:image forState:UIControlStateNormal];
    [btn addTarget:delegate action:action forControlEvents:UIControlEventTouchUpInside];
    btn.imageEdgeInsets=UIEdgeInsetsMake(0, -30, 0, 0);
    UIBarButtonItem *left=[[UIBarButtonItem alloc]initWithCustomView:btn];
    return left;
}

+(NSMutableAttributedString *)setAttributWithStr:(NSString *)originalStr changeStr:(NSString *)changeStr
{
    NSRange range=[originalStr rangeOfString:changeStr];
    NSMutableAttributedString *attri=[[NSMutableAttributedString alloc]initWithString:originalStr];
    //改字体大小
    [attri addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:22] range:range];
    
    //改变文字偏移量 value大于0 就往上偏
    [attri addAttribute:NSBaselineOffsetAttributeName value:@(50) range:range];
    
    return attri;
}

#pragma mark - 设置下划线
+(NSMutableAttributedString *)setUnderLineWithStr:(NSString *)originStr withLineColor:(UIColor *)lineColor{
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:originStr];
    NSRange strRange = {0,[str length]};
    [str addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:strRange];
    [str addAttribute:NSForegroundColorAttributeName value:lineColor range:strRange];
    
    return str;
}

+(CGFloat)systemVersion{
    return [[UIDevice currentDevice].systemVersion floatValue];
}



//邮箱正则表达式
+(BOOL)validateEmail:(NSString *)email{
    
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:email];
}
/**
 检测是否是手机号码
 */
+ (BOOL)isMobileNumber:(NSString *)mobileNum
{
    /**
     * 手机号码
     * 移动：134[0-8],135,136,137,138,139,150,151,157,158,159,182,187,188
     * 联通：130,131,132,152,155,156,185,186
     * 电信：133,1349,153,180,189
     */
    NSString * MOBILE = @"^1(3[0-9]|5[0-35-9]|8[0-9])\\d{8}$";
    /**
     10         * 中国移动：China Mobile
     11         * 134[0-8],135,136,137,138,139,150,151,157,158,159,182,187,188
     12         */
    NSString * CM = @"^1(34[0-8]|(3[5-9]|5[017-9]|8[278])|7[0-9]\\d)\\d{7}$";
    /**
     15         * 中国联通：China Unicom
     16         * 130,131,132,152,155,156,185,186
     17         */
    NSString * CU = @"^1(3[0-2]|5[256]|8[56])\\d{8}$";
    /**
     20         * 中国电信：China Telecom
     21         * 133,1349,153,180,189
     22         */
    NSString * CT = @"^1((33|53|8[09])[0-9]|349)\\d{7}$";
    /**
     25         * 大陆地区固话及小灵通
     26         * 区号：010,020,021,022,023,024,025,027,028,029
     27         * 号码：七位或八位
     28         */
    // NSString * PHS = @"^0(10|2[0-5789]|\\d{3})\\d{7,8}$";
    
    NSPredicate *regextestmobile = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE];
    NSPredicate *regextestcm = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CM];
    NSPredicate *regextestcu = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CU];
    NSPredicate *regextestct = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CT];
    
    if (([regextestmobile evaluateWithObject:mobileNum] == YES)
        || ([regextestcm evaluateWithObject:mobileNum] == YES)
        || ([regextestct evaluateWithObject:mobileNum] == YES)
        || ([regextestcu evaluateWithObject:mobileNum] == YES))
    {
        return YES;
    }
    else
    {
        return NO;
    }
}
//特殊字符正则表达式
+(BOOL)validateSpecialCharacter:(NSString *)chr{
    NSString *passwordRegex = @"^[a-zA-Z0-9]+$";
    NSPredicate *passwordTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", passwordRegex];
    return [passwordTest evaluateWithObject:chr];
}

//md5运算
+(NSString*)md5:(NSString*)input{
    const char *cStr = [input UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    return  output;
}

+(void)printNSData:(NSData *)data{
    const char *bytes = data.bytes;
    for (NSUInteger i = 0; i < data.length; i++) {
        printf("%.2hhx ", bytes[i]);
    }
    printf("\r\n");
}

+(UIImage*)createImageWithColor:(UIColor*)color{
    
    CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

+(void)removeConstraint:(NSLayoutConstraint *)constraint fromView:(UIView *)view{
    for (NSUInteger i = 0; i < view.constraints.count; i++) {
        NSLayoutConstraint *t = view.constraints[i];
        if (t.relation == constraint.relation && t.multiplier == constraint.multiplier && t.constant == constraint.constant && ((t.firstItem == constraint.firstItem && t.firstAttribute == constraint.firstAttribute && t.secondItem == constraint.secondItem && t.secondAttribute == constraint.secondAttribute) || (t.firstItem == constraint.secondItem && t.firstAttribute == constraint.secondAttribute && t.secondItem == constraint.firstItem && t.secondAttribute == constraint.firstAttribute))) {
            [view removeConstraint:t];
        }
    }
}

+(void)createFolder:(NSString *)path{
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]){
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

+ (NSData*)hexToData:(NSString *)hexString {
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

+(NSString *)getWeekCommand:(NSArray *)arr{
    int week=0;
    if (arr.count>0) {
        
        for (int i=0; i<arr.count; i++) {
            NSNumber *num=[arr objectAtIndex:i];
            if (i==1 && [num isEqualToNumber:@(1)]) {
                week= week|1<<1;
            }
            else if (i==2 && [num isEqualToNumber:@(1)]){
                week= week|1<<2;
            }
            else if (i==3 && [num isEqualToNumber:@(1)]){
                week= week|1<<3;
            }
            else if (i==4 && [num isEqualToNumber:@(1)]){
                week= week|1<<4;
            }
            else if (i==5 && [num isEqualToNumber:@(1)]){
                week= week|1<<5;
            }
            else if (i==6 && [num isEqualToNumber:@(1)]){
                week= week|1<<6;
            }
            else if (i==0 && [num isEqualToNumber:@(1)]){
                week= week|1;
            }
            
            
        }
        
    }
    
    return [NSString stringWithFormat:@"%02X",week];
    
}




+ (UIImage *)compressImage:(UIImage *)image newWidth:(CGFloat)newImageWidth
{
    if (!image){
        return nil;
    }
    float imageWidth = image.size.width;
    float imageHeight = image.size.height;
    float width = newImageWidth;
    float height = image.size.height/(image.size.width/width);
    
    float widthScale = imageWidth /width;
    float heightScale = imageHeight /height;
    
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    
    if (widthScale > heightScale) {
        [image drawInRect:CGRectMake(0, 0, imageWidth /heightScale , height)];
    }
    else {
        [image drawInRect:CGRectMake(0, 0, width , imageHeight /widthScale)];
    }
    
    // 从当前context中创建一个改变大小后的图片
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    return newImage;
    
}

#pragma mark - 获取手机ip地址
+(NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // 检索当前接口,在成功时,返回0
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // 循环链表的接口
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // 检查接口是否en0 wifi连接在iPhone上
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // 得到NSString从C字符串
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
                
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // 释放内存
    freeifaddrs(interfaces); return address;
    
}

+(NSString *)localBroadCastIP
{
    NSString *address = @"error";
    struct ifaddrs *interface = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    UInt32 uip,umask,ubroadip;
    
    success = getifaddrs(&interface);
    
    if(success == 0){
        temp_addr = interface;
        while (temp_addr != NULL) {
            if (temp_addr->ifa_addr->sa_family == AF_INET) {
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name]isEqualToString:@"en0"]) {
                    uip = NTOHL(((struct sockaddr_in *)(temp_addr->ifa_addr))->sin_addr.s_addr);
                    umask = NTOHL((((struct sockaddr_in *)(temp_addr->ifa_netmask))->sin_addr).s_addr);
                    ubroadip = (uip&umask)+(0XFFFFFFFF&(~umask));
                    struct in_addr inadd;
                    inadd.s_addr = HTONL(ubroadip);
                    char caddr[30]={0};
                    address=[NSString stringWithUTF8String:inet_ntop(AF_INET,(char *)&inadd,caddr,16)];
                    break;
                }
            }else if (temp_addr->ifa_addr->sa_family == AF_INET6){
                
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interface);
    return address;
}

+(NSString *)convertToJsonData:(NSDictionary *)dict{
    
    NSError *error;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString;
    
    if (!jsonData) {
        
        NSLog(@"%@",error);
        
    }else{
        
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
        
    }
    
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    
    NSRange range = {0,jsonString.length};
    
    //去掉字符串中的空格
    
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    
    NSRange range2 = {0,mutStr.length};
    
    //去掉字符串中的换行符
    
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    
    return mutStr;
    
}


+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString{
    
    jsonString = [jsonString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\0"]];
    
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

@end
