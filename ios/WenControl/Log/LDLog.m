//
//  LDLog.m
//  WuZhu
//
//  Created by WuJiezhong on 2017/5/27.
//  Copyright © 2017年 WuZhu. All rights reserved.
//

#import "LDLog.h"




@implementation LDLog

+ (void)installCocoaLumberjackLog {
    // Add File Log
    DDFileLogger* fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [DDLog addLogger:fileLogger];
    
#ifdef DEBUG
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
#endif
    
    HHLogFormatter* logFormatter = [[HHLogFormatter alloc]init];
    [fileLogger setLogFormatter:logFormatter];
    [[DDTTYLogger sharedInstance] setLogFormatter:logFormatter];
    
}

@end



