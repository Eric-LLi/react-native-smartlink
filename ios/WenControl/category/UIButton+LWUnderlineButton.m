//
//  UIButton+LWUnderlineButton.m
//  moduleProject_YZY
//
//  Created by wen on 2017/8/11.
//  Copyright © 2017年 wen. All rights reserved.
//

#import "UIButton+LWUnderlineButton.h"

@implementation UIButton (LWUnderlineButton)

- (void)addLine{
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:self.titleLabel.text];
    NSRange strRange = {0,[str length]};
    [str addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:strRange];
    //    [str addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0x34abff) range:strRange];
    [self setAttributedTitle:str forState:UIControlStateNormal];
}

@end
