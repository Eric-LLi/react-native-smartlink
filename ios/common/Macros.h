//
//  Macros.h
//  PingAnMiFi
//
//  Created by wangmi on 16/2/19.
//  Copyright © 2016年 PingAn. All rights reserved.
//

#ifndef Macros_h
#define Macros_h

//#import <VEYUIControl/UIConfig.h>
#define APP_VERSION  [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]
#define BUILD_VERSION  [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]
#define APP_BUNDEL_IDENTIFIER  [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]

#pragma mark - 颜色值

///导航栏背景色
#define MiFi_NAVI_BG_COLOR_STYLE HexRGB(0x242328)

///背景色
#define MiFi_BG_COLOR_STYLE HexRGB(0xefefef)

///间隔线色
#define MiFi_LINE_COLOR_STYLE HexRGB(0xe4e4e4)

///列表背景色
#define MiFi_LIST_BG_COLOR_STYLE HexRGB(0xffffff)

///按钮/高亮色
#define MiFi_MENU_COLOR_STYLE HexRGB(0xfe7900)

///辅助色
#define MiFi_AUXI_COLOR_STYLE HexRGB(0x5aafee)

///文字颜色
#define MiFi_WORD_COLOR_STYLE_1 HexRGB(0xffffff)
#define MiFi_WORD_COLOR_STYLE_2 HexRGB(0x303030)
#define MiFi_WORD_COLOR_STYLE_3 HexRGB(0xa7a7a7)
#define MiFi_WORD_COLOR_STYLE_4 HexRGB(0x656565)


#pragma mark - 其他

///window
#define Window  [(MiFiAppDelegate*)[[UIApplication sharedApplication] delegate] window]
//AppDelegate
#define APPDelegate ((MiFiAppDelegate*)[[UIApplication sharedApplication] delegate])


//弱引用
#define WEAK_SELF __weak typeof(self)weakSelf = self
#define STRONG_SELF __strong typeof(weakSelf)self = weakSelf




#pragma mark - NSUserDefaults

///NSUserDefaults
#define USER_DEFAULT [NSUserDefaults standardUserDefaults]

#pragma mark - iconfont相关
#define ICON_FONT @"iconfont"

// 返回
#define ICON_Back   @"\U0000e63e"
// 右角号
#define ICON_RArrow @"\U0000e621"

// device ios version
#define IOS6_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0f)
#define IOS7_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f)
#define IOS8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0f)
#define IOS9_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0f)
#define IOS10_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0f)
#define IOS6_7_DELTA(V,X,Y,W,H) if(IOS7_OR_LATER) {CGRect f = V.frame;f.origin.x += X;f.origin.y += Y;f.size.width +=W;f.size.height += H;V.frame=f;}

// NQ定义
#define NQ_LOGOUT               @"NQ_LOGOUT"


// NSUserDefaults定义
//#define kMiFiLaunchADImage      @"kMiFiLaunchADImage"



// color定义
#define HexRGB(rgbValue)    [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define HexRGBA(rgbValue,a) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:(a)]
#define HexRGBClear         [UIColor clearColor]

#pragma mark - tools define
#define IsNilOrNull(_ref)   (((_ref) == nil) || ([(_ref) isEqual:[NSNull null]]))

// Block self no arc
#define BLOCKSELF(blockSelf) __block __typeof(&*self) blockSelf = self;
#define WEAKSELF __typeof(self) __weak weakSelf = self;

#ifndef WS
#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self;
#endif

#pragma mark - 750 标注图的比例系数

// device module
#ifndef iPhone4
#define iPhone4 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960),[[UIScreen mainScreen] currentMode].size) : NO)
#endif

#ifndef iPhone5
#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136),[[UIScreen mainScreen] currentMode].size) : NO)
#endif

#ifndef iPhone6
#define iPhone6 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(750, 1334), [[UIScreen mainScreen] currentMode].size) : NO)
#endif

#ifndef iPhone6Plus
#define iPhone6Plus ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size) : NO)
#endif

///当前系统版本号
#define CURRENT_SYSTEM_VERSION  [[[UIDevice currentDevice] systemVersion] floatValue]
///屏幕尺寸
#define SCREEN_SIZE           [[UIScreen mainScreen] bounds].size                 //(e.g. 320,480)
///屏幕宽
#ifndef SCREEN_WIDTH
#define SCREEN_WIDTH          [[UIScreen mainScreen] bounds].size.width           //(e.g. 320)
#endif
//屏幕高
#ifndef SCREEN_HEIGHT
#define SCREEN_HEIGHT         [[UIScreen mainScreen] bounds].size.height          //包含状态bar的高度(e.g. 480)
#endif

#define Anno750(x) ((x) * 2 / 1334.0f) * SCREEN_HEIGHT
#define font750(x) ((x) * 2 / 1334.0f) * SCREEN_HEIGHT

//基准屏幕是375*667
//屏幕宽度比例
#define ScreenWidthScale  (SCREEN_WIDTH/375.0f)
//屏幕高度比例
#define ScreenHeightScale (SCREEN_HEIGHT/667.0f)

/*
*适合在不同宽度的屏幕上以6(s)为基准，按宽度比例设置控件的宽度
*即用来在不同宽度的屏幕上进行适配
*比较常用，因为5，6和6+宽高比基本是一致的，按宽度适配相当于也按高度进行了适配，即进行了等比例缩放
*从4和5宽一样，5比4长了88，按宽度进行适配在很多情况下也是比较合适的，有时也是必须的
 */
#define FitWidth(x)  ScreenWidthScale*((x))

//适合在不同长度的屏幕上以6(s)为基准，按长度比例设置控件的长度
//用来在不同长度的屏幕上进行适配
//很少用的到，因为5，6及6+上宽高比基本一致，4和5同宽不等高
#define FitHeight(x) (ScreenHeightScale*(x))

/*字体适配方案一：4(s)、5(s)/6(s)/6+(s)，以6(s)为设计基准，按宽度比例适配字体
 *其中4(s)、5(s)宽度一样，字体也一样。
 */
#define FitFont(x)  (ScreenWidthScale*(x))

/*字体适配方案二：4(s)、5(s)/6(s)字体一样，6+(s)是4(s)、5(s)/6(s)字体的1.5倍
 *  x>:?
 */
//#define FitFont(x) ((SCREEN_HEIGHT > 667)?(x*1.5):(x))


/*字体适配方案三：4(s)、5(s)/6(s)/6+(s)，以6(s)为设计基准，按宽度比例适配字体
 *如果是6+(s),字体是6(s)的1.5倍
 */
//#define FitFont(x) ((SCREEN_HEIGHT > 667)？(x*1.5):(ScreenWidthScale*(x)))

#ifdef DEBUG
#define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
//#define DLog(fmt, ...) fprintf((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);


#else
#define DLog(...)
#endif

#endif /* Macros_h */
