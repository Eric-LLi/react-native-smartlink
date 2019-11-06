//
//  UIView+LWQuickControl.m
//  moduleProject_YZY
//
//  Created by wen on 2017/8/11.
//  Copyright © 2017年 wen. All rights reserved.
//

#import "UIView+LWQuickControl.h"
#import "LWButton.h"
@implementation UIView (LWQuickControl)

//生成一个UIBarButtonItem
-(UIBarButtonItem *)createBarButtonItem:(UIButton*)button
{
    button.titleLabel.textAlignment=NSTextAlignmentRight;
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font=[UIFont systemFontOfSize:18];
    
    UIBarButtonItem *barItem=[[UIBarButtonItem alloc]initWithCustomView:button];
    
    return barItem;
}

//创建并加载系统按钮
-(UIButton *)addSystemButtonWithFrame:(CGRect)frame title:(NSString *)title action:(void(^)(LWButton *button))action
{
    LWButton *button=[LWButton buttonWithType:UIButtonTypeSystem];
    button.frame=frame;
    [button setTitle:title forState:UIControlStateNormal];
    button.action=action;
    [self addSubview:button];
    return button;
}
-(UIButton *)createSystemButtonWithFrame:(CGRect)frame title:(NSString *)title action:(void(^)(LWButton *button))action
{
    LWButton *button=[LWButton buttonWithType:UIButtonTypeSystem];
    button.frame=frame;
    [button setTitle:title forState:UIControlStateNormal];
    button.action=action;
    return button;
}
//创建并加载图片按钮
-(UIButton *)addImageButtonWithFrame:(CGRect)frame title:(NSString *)title image:(NSString *)image action:(void(^)(LWButton *button))action
{
    LWButton *button=[LWButton buttonWithType:UIButtonTypeCustom];
    button.frame=frame;
    [button setTitle:title forState:UIControlStateNormal];
    
    [button setBackgroundImage:[UIImage imageNamed:image] forState:UIControlStateNormal];
    button.action=action;
    [self addSubview:button];
    return button;
}
//创建一个图片按钮
-(UIButton *)createImageButtonWithFrame:(CGRect)frame title:(NSString *)title image:(NSString *)image action:(void(^)(LWButton *button))action
{
    LWButton *button=[LWButton buttonWithType:UIButtonTypeCustom];
    button.frame=frame;
    [button setTitle:title forState:UIControlStateNormal];
    
    [button setBackgroundImage:[UIImage imageNamed:image] forState:UIControlStateNormal];
    button.action=action;
    return button;
}
//创建label
-(UILabel *)addLabelWithFrame:(CGRect)frame title:(NSString *)title;
{
    UILabel *label=[[UILabel alloc]initWithFrame:frame];
    label.text=title;
    label.textColor=[UIColor whiteColor];
    [self addSubview:label];
    return label;
}

-(UILabel *)addLabelWithFrame:(CGRect)frame title:(NSString *)title font:(CGFloat)font textcolor:(UIColor *)color
{
    UILabel *label=[[UILabel alloc]initWithFrame:frame];
    label.numberOfLines=0;
    label.text=title;
    label.textColor=color;
    label.font=[UIFont systemFontOfSize:font];
    [self addSubview:label];
    return label;
}
//只创建label
-(UILabel*)createLabelWithFrame:(CGRect)frame title:(NSString *)title font:(CGFloat)font textColor:(UIColor*)color
{
    UILabel *label=[[UILabel alloc]initWithFrame:frame];
    label.text=title;
    label.textColor=color;
    label.font=[UIFont systemFontOfSize:font];
    return label;
}


//创建ImageView
-(UIImageView *)addImageViewWithFrame:(CGRect)frame image:(NSString *)image
{
    UIImageView *imageView=[[UIImageView alloc]initWithFrame:frame];
    
    imageView.image=[UIImage imageNamed:image];
    imageView.userInteractionEnabled=YES;
    [self addSubview:imageView];
    return imageView;
}
-(UIImageView *)createImageViewWithFrame:(CGRect)frame image:(NSString *)image
{
    UIImageView *imageView=[[UIImageView alloc]initWithFrame:frame];
    imageView.image=[UIImage imageNamed:image];
    imageView.userInteractionEnabled=YES;
    return imageView;
}
//创建textfiled
-(UITextField *)addTextFieldWithFrame:(CGRect)frame style:(UITextBorderStyle)style delegate:(id)delegate
{
    UITextField *textfield=[[UITextField alloc]initWithFrame:frame];
    textfield.borderStyle=style;
    textfield.delegate=delegate;
    [self addSubview:textfield];
    return textfield;
}

//创建scrollview
-(UIScrollView *)addScrollViewWithFrame:(CGRect)frame
{
    UIScrollView *scrollView=[[UIScrollView alloc]initWithFrame:frame];
    scrollView.showsVerticalScrollIndicator=NO;
    scrollView.showsHorizontalScrollIndicator=NO;
    scrollView.bounces=NO;
    [self addSubview:scrollView];
    return scrollView;
}

-(UIScrollView *)createScrollViewWithFrame:(CGRect)frame
{
    UIScrollView *scrollView=[[UIScrollView alloc]initWithFrame:frame];
    scrollView.showsVerticalScrollIndicator=NO;
    scrollView.showsHorizontalScrollIndicator=NO;
    scrollView.bounces=NO;
    return scrollView;
}

//创建tableView
-(UITableView *)addTableViewWtithFrame:(CGRect)frame style:(UITableViewStyle)style delegate:(id)delegate
{
    UITableView *tableView=[[UITableView alloc]initWithFrame:frame style:style];
    [self addSubview:tableView];
    tableView.showsVerticalScrollIndicator=NO;
    tableView.showsHorizontalScrollIndicator=NO;
    tableView.delegate=delegate;
    tableView.dataSource=delegate;
    
    return tableView;
}

-(UIView *)addViewWithFrame:(CGRect)frame backgroundcolor:(UIColor *)color
{
    UIView *view=[[UIView alloc]initWithFrame:frame];
    view.backgroundColor=color;
    [self addSubview:view];
    return view;
}


@end
