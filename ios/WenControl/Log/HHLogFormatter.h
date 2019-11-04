//
//  HHLogFormatter.h
//  SuperTeacher
//
//  Created by CatchZeng on 15/9/29.
//  Copyright © 2015年 qingningxiezuo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

@interface HHLogFormatter : NSObject <DDLogFormatter>

/**
 *  设置是否显示的log信息；
 *  以下信息默认都显示，不想显示的话可以设为NO
 */
@property (nonatomic,assign) BOOL showYear;
@property (nonatomic,assign) BOOL showMonth;
@property (nonatomic,assign) BOOL showDay;
@property (nonatomic,assign) BOOL showHour;
@property (nonatomic,assign) BOOL showMinute;
@property (nonatomic,assign) BOOL showSecond;

@end
