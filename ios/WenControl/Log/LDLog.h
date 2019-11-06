//
//  LDLog.h
//  WuZhu
//
//  Created by WuJiezhong on 2017/5/27.
//  Copyright © 2017年 WuZhu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HHLogFormatter.h"

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@interface LDLog : NSObject

+ (void)installCocoaLumberjackLog;

@end

