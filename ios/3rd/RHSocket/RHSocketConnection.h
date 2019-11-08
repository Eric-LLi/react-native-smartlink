//
//  RHSocketConnection.h
//  PingAnMiFi
//
//  Created by true me on 12/22/2016.
//  Copyright © 2016年 PingAn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RHSocketConfig.h"

@protocol RHSocketConnectionDelegate <NSObject>

- (void)didDisconnectWithError:(NSError *)error;
- (void)didConnectToHost:(NSString *)host port:(UInt16)port;
- (void)didReceiveData:(NSData *)data tag:(long)tag;

@end

@interface RHSocketConnection : NSObject

@property (nonatomic, weak) id<RHSocketConnectionDelegate> delegate;

- (void)connectWithHost:(NSString *)hostName port:(NSInteger)port;
- (void)connectWithHost:(NSString *)hostName port:(NSInteger)port timeout:(NSTimeInterval) timeout;
- (void)disconnect;

- (BOOL)isConnected;
- (void)readDataWithTimeout:(NSTimeInterval)timeout tag:(long)tag;
- (void)writeData:(NSData *)data timeout:(NSTimeInterval)timeout tag:(long)tag;

@end
