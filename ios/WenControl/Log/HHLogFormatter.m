//
//  HHLogFormatter.m
//  SuperTeacher
//
//  Created by CatchZeng on 15/9/29.
//  Copyright © 2015年 qingningxiezuo. All rights reserved.
//
#import "HHLogFormatter.h"
#import <libkern/OSAtomic.h>


static NSString *const LogFormatterCalendarKey = @"LogFormatterCalendarKey";
static const NSCalendarUnit LogFormatterCalendarUnit = (NSCalendarUnit)(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond);

@interface HHLogFormatter () {
    int32_t atomicLoggerCount;
    NSCalendar *logCalendar;
}

@end

@implementation HHLogFormatter

-(instancetype)init{
    self = [super init];
    if (self) {
        _showYear = YES;
        _showMonth = YES;
        _showDay  = YES;
        _showHour = YES;
        _showMinute = YES;
        _showSecond = YES;
    }
    return self;
}

/**
 *  获取Calendar
 *
 */
-(NSCalendar *)_logCalendar{
    int32_t loggerCount = OSAtomicAdd32(0, &atomicLoggerCount);
    
    if (loggerCount <=1) {//如果是单个线程
        if (!logCalendar) {
            logCalendar = [NSCalendar autoupdatingCurrentCalendar];
        }
        return logCalendar;
    }else{//如果是多线程
        NSMutableDictionary* dic = [[NSThread currentThread] threadDictionary];
        NSCalendar* calendar = [dic objectForKey:LogFormatterCalendarKey];
        if (!calendar) {
            calendar = [NSCalendar autoupdatingCurrentCalendar];
            [dic setObject:calendar forKey:LogFormatterCalendarKey];
        }
        return calendar;
    }
}

/**
 *  根据flag获取level字符串
 *
 *  @param flag log标志
 *
 *  @return level字符串
 */
-(NSString *)_logLevelWithFlag:(DDLogFlag)flag{
    if (flag == DDLogFlagError){
        return @"Error";
    }else if (flag == DDLogFlagInfo){
        return @"Info";
    }else if (flag == DDLogFlagDebug){
        return @"Debug";
    }else if (flag == DDLogFlagWarning){
        return @"Warn";
    }else if (flag == DDLogFlagVerbose){
        return @"Verbose";
    }else{
        return @"Unknow";
    }
    
}

/**
 *  协议方法
 */
-(NSString *)formatLogMessage:(DDLogMessage *)logMessage{
    NSDateComponents* components = [[self _logCalendar] components:LogFormatterCalendarUnit fromDate:logMessage->_timestamp];
    
    NSMutableString* logMsg = [NSMutableString stringWithFormat:@"[%@] ",[self _logLevelWithFlag:logMessage->_flag]];
    if (_showYear) {
        [logMsg appendString:[NSString stringWithFormat:@"%04ld-",(long)components.year]];
    }
    if (_showMonth) {
        [logMsg appendString:[NSString stringWithFormat:@"%02ld-",(long)components.month]];
    }
    if (_showDay) {
        [logMsg appendString:[NSString stringWithFormat:@"%02ld ",(long)components.day]];
    }
    if (_showHour) {
        [logMsg appendString:[NSString stringWithFormat:@"%02ld:",(long)components.hour]];
    }
    if (_showMinute) {
        [logMsg appendString:[NSString stringWithFormat:@"%02ld:",(long)components.minute]];
    }
    if (_showSecond) {
        [logMsg appendString:[NSString stringWithFormat:@"%02ld ",(long)components.second]];
    }
    
    [logMsg appendString:[NSString stringWithFormat:@"(%@:%lu)%@:%@",[logMessage->_file lastPathComponent],(unsigned long)logMessage->_line,logMessage->_function,logMessage->_message]];
    return logMsg;
}

/**
 *  协议方法
 */
- (void)didAddToLogger:(id <DDLogger> __unused)logger
{
    OSAtomicIncrement32(&atomicLoggerCount);
}

/**
 *  协议方法
 */
- (void)willRemoveFromLogger:(id <DDLogger> __unused)logger
{
    OSAtomicDecrement32(&atomicLoggerCount);
}

@end
