//
//  LWButton.h
//  moduleProject_YZY
//
//  Created by wen on 2017/8/11.
//  Copyright © 2017年 wen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LWButton : UIButton

@property(copy,nonatomic)void(^action)(LWButton *button);

@end
