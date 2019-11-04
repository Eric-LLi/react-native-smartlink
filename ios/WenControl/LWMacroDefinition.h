//
//  LWMacroDefinition.h
//  moduleProject_YZY
//
//  Created by wen on 2017/8/11.
//  Copyright © 2017年 wen. All rights reserved.
//

#ifndef LWMacroDefinition_h
#define LWMacroDefinition_h

//.h文件
#define  LWSingleManagerH(name) +(instancetype)shared##name;

//.m文件

#if __has_feature(objc_arc)

#define LWSingleManagerM(name)\
static id _instace; \
\
+ (id)allocWithZone:(struct _NSZone *)zone \
{ \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instace = [super allocWithZone:zone]; \
}); \
return _instace; \
} \
\
+ (instancetype)shared##name \
{ \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instace = [[self alloc] init]; \
}); \
return _instace; \
} \
\
- (id)copyWithZone:(NSZone *)zone \
{ \
return _instace; \
}


#else
#define MySingleManagerM(name) \
static id _instace; \
\
+ (id)allocWithZone:(struct _NSZone *)zone \
{ \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instace = [super allocWithZone:zone]; \
}); \
return _instace; \
} \
\
+ (instancetype)shared##name \
{ \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instace = [[self alloc] init]; \
}); \
return _instace; \
} \
\
- (id)copyWithZone:(NSZone *)zone \
{ \
return _instace; \
} \
\
- (oneway void)release { } \
- (id)retain { return self; } \
- (NSUInteger)retainCount { return 1;} \
- (id)autorelease { return self;}

#endif


#define kTimeOutInterval 5

#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self;
//弱引用
#define __WeakSelf__ __weak typeof (self)

//weak self
#define __weakSelf(obj) __weak typeof(obj) weakSelf = obj
//strong self
#define __strongSelf(obj) __strong typeof(obj) strongSelf = obj


//字体
#define LWUIFont_size(size) [UIFont systemFontOfSize:size]

//版本号判定
#define iOS10_Later [[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0f
//图片渲染模式
#define LWImageNameRenderStr(str) [[UIImage imageNamed:(str)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
//屏幕宽高
#define LWScreen_Width [UIScreen mainScreen].bounds.size.width
#define LWScreen_Height [UIScreen mainScreen].bounds.size.height
//屏幕系数
#define LWWidthRatio  screen_Width/320.0
#define LWHeightRatio screen_Height/568.0

// tabBar 高度
#define LWTabBarHeight 49.0f
// 导航栏高度
#define LWNavigatHeight  64.f

//颜色设定
#define LWRandColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0f]


//十六进制颜色
#define LWUIColorFromRGB(rgbValue)    [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

// 处理打印函数
#ifdef DEBUG
#define LWLog(FORMAT,...) fprintf(stderr,"%s:%d\t%s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
//#define LWLog(...) NSLog(__VA_ARGS__)
#define LWLogFunc NSLog(@"%s", __func__)

#else
#define LWLog(...)
#define LWLogFunc

#endif

// 主窗口
#define LQKeyWindow [UIApplication sharedApplication].keyWindow




#endif /* LWMacroDefinition_h */
