//
//  RHSocketConfig.h
//  PingAnMiFi
//
//  Created by true me on 12/22/2016.
//  Copyright © 2016年 PingAn. All rights reserved.
//

#ifndef RHSocketDemo_RHSocketConfig_h
#define RHSocketDemo_RHSocketConfig_h

#ifdef DEBUG
#define RHSocketDebug
#endif

#ifdef RHSocketDebug
#define RHSocketLog(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define RHSocketLog(format, ...)
#endif

#endif
