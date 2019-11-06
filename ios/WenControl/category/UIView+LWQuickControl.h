//
//  UIView+LWQuickControl.h
//  moduleProject_YZY
//
//  Created by wen on 2017/8/11.
//  Copyright © 2017年 wen. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LWButton;
@interface UIView (LWQuickControl)

/**
 生成一个UIBarButtonItem
 */
-(UIBarButtonItem *)createBarButtonItem:(UIButton*)button;
/**创建并加载系统按钮*/
-(UIButton *)addSystemButtonWithFrame:(CGRect)frame title:(NSString *)title action:(void(^)(LWButton *button))action;
/**生成系统按钮*/
-(UIButton *)createSystemButtonWithFrame:(CGRect)frame title:(NSString *)title action:(void(^)(LWButton *button))action;
/**创建并加载图片按钮*/
-(UIButton *)addImageButtonWithFrame:(CGRect)frame title:(NSString *)title image:(NSString *)image action:(void(^)(LWButton *button))action;
/**生成图片按钮*/
-(UIButton *)createImageButtonWithFrame:(CGRect)frame title:(NSString *)title image:(NSString *)image action:(void(^)(LWButton *button))action;
/**创建并加载Label*/
-(UILabel *)addLabelWithFrame:(CGRect)frame title:(NSString *)title;

-(UILabel *)addLabelWithFrame:(CGRect)frame title:(NSString *)title font:(CGFloat)font textcolor:(UIColor *)color;
/**创建label不加载到view上 */
-(UILabel*)createLabelWithFrame:(CGRect)frame title:(NSString *)title font:(CGFloat)font textColor:(UIColor*)color;
/**创建并加载ImageView*/
-(UIImageView *)addImageViewWithFrame:(CGRect)frame image:(NSString *)image;
/**
 只创建不加载
 */
-(UIImageView *)createImageViewWithFrame:(CGRect)frame image:(NSString *)image;

/**创建并加载textField*/
-(UITextField *)addTextFieldWithFrame:(CGRect)frame style:(UITextBorderStyle)style delegate:(id)delegate;

/**创建并加载scrollView*/
-(UIScrollView *)addScrollViewWithFrame:(CGRect)frame;
/**生成scrollView*/
-(UIScrollView *)createScrollViewWithFrame:(CGRect)frame;

/**
 创建tableView并加载
 */
-(UITableView *)addTableViewWtithFrame:(CGRect)frame style:(UITableViewStyle)style delegate:(id)delegate;

-(UIView *)addViewWithFrame:(CGRect)frame backgroundcolor:(UIColor *)color;

@end
