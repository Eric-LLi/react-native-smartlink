//
//  LWNSHelper.h
//  AirPurge
//
//  Created by wen on 2017/9/8.
//  Copyright © 2017年 wen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
@interface LWNSHelper : NSObject

/**
 * 注册键盘弹起及隐藏事件的通知
 */
+(void)registerForKeyBoardNotificationsWithDelegate:(id)delegate
                             keyboardWasShownMethod:(SEL)shownAction
                            keyboardWasHiddenMethod:(SEL)hiddenAction;
/**
 *判断两个NSDate 是否是同一天
 */
+(BOOL)isSameDayWithDate1:(NSDate*)date1 date2:(NSDate *)date2;

/**
 *将一个字符串转化成为16进制的字符串
 */
+(NSString *)convertStringToHexStr:(NSString *)str;

/**
 *将十六进制的字符串转换成NSString
 */
+(NSString *)convertHexStrToString:(NSString *)str;
/**
 返回导航栏右边文字按钮
 */
+(UIBarButtonItem *)configRightBtnWith:(id)delegate action:(SEL)action text:(NSString *)text;
/**
 返回导航栏右边图片按钮
 */
+(UIBarButtonItem *)configImageRightBtnWith:(id)delegate action:(SEL)action image:(UIImage *)image;

/**
 *  配置一个左边UIBarBUttonItem对象
 *  @return UIBarButtonItem 对象
 */
+(UIBarButtonItem *)configImageLeftItemWith:(id)delegate action:(SEL)action image:(UIImage *)image;


/**
 是否是邮箱
 */
+(BOOL)validateEmail:(NSString *)email;

+(BOOL)validateSpecialCharacter:(NSString *)chr;
/**
 是否是手机号
 */
+ (BOOL)isMobileNumber:(NSString *)mobileNum;

+(NSString*)md5:(NSString*)input;

+(void)printNSData:(NSData*)data;

/**
 将颜色转换为UIImage对象
 */
+(UIImage*)createImageWithColor:(UIColor*)color;

+(void)removeConstraint:(NSLayoutConstraint*)constraint fromView:(UIView*)view;

+(void)createFolder:(NSString *)path;

+ (NSData*)hexToData:(NSString *)hexString;

/**
 设置一段字符串的格式
 */
+(NSMutableAttributedString *)setAttributWithStr:(NSString *)originalStr changeStr:(NSString *)changeStr;

/**
 *根据一个int 来得到重复的周期数组
 *周字节表示：bit0-6表示周日一二三四五六
 */
+(NSArray *)configWeekArrWithInt:(int)week;

/**
 *根据一个数组来配置周期重复显示字符串
 *
 */
+(NSString *)configRepeatStrWithArr:(NSArray *)weekArr;

/**
 *  根据重复arr获取发送命令
 *
 *  @param arr 数组
 *
 *  @return 命令
 */
+(NSString *)getWeekCommand:(NSArray *)arr;

/**
 *  配置下划线attributeString
 *  @param  originStr 原始字符串
 *  @param  lineColor 下划线颜色
 *  @return NSMutableAttributedString 对象
 **/
+(NSMutableAttributedString *)setUnderLineWithStr:(NSString *)originStr withLineColor:(UIColor *)lineColor;
/**
 *  等比缩放本图片大小
 *
 *  @param newImageWidth 缩放后图片宽度，像素为单位
 *
 *  @return self-->(image)
 */+ (UIImage *)compressImage:(UIImage *)image newWidth:(CGFloat)newImageWidth;


/**
 * 获取手机ip地址
 * @return ip地址
 */
+(NSString *)getIPAddress;

+(NSString *)localBroadCastIP;

/**
 *  字典转json字符串
 */
+(NSString *)convertToJsonData:(NSDictionary *)dict;

/**
 * 将json字符串转为字典
 */
+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;

@end
