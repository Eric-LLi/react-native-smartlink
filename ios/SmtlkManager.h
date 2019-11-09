//
//  SmtlkManager.h
//  SmartLink V2.0
//
//  Created by Peter on 14-3-4.
//  Copyright (c) 2014年 Peter. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SmtlkCmdStatus) {
    SmtlkCmdStatus_None = 0,
    SmtlkCmdStatus_ASSISTHREAD,
    SmtlkCmdStatus_ASSISTHREAD_Done,
    SmtlkCmdStatus_AT_WSCAN,
    SmtlkCmdStatus_AT_WSCAN_Done,
    SmtlkCmdStatus_AT_WSSSID,
    SmtlkCmdStatus_AT_WSSSID_Done,
    SmtlkCmdStatus_AT_WSKEY,
    SmtlkCmdStatus_AT_WSKEY_Done,
    SmtlkCmdStatus_AT_WMODE,
    SmtlkCmdStatus_AT_WMODE_Done,
    SmtlkCmdStatus_AT_Z,
};

typedef NS_ENUM(NSInteger, SmtlkCommand) {
    SmtlkCommand_UNKNOWN = 0,
    SmtlkCommand_DISCOVERY,
    SmtlkCommand_AT_WSCAN,
    SmtlkCommand_AT_WSSSID,
    SmtlkCommand_AT_WSKEY,
    SmtlkCommand_AT_WMODE,
    SmtlkCommand_AT_Z,
    SmtlkCommand_PLUS_OK,
    
};

@protocol SmtlkManagerDelegate <NSObject>
@optional

/*发送口令后返回：WIFI模块的IP地址、MAC地址、MID*/
-(void)smtlkV20EventDiscover:(NSString *)host MAC:(NSString *)mac MID:(NSString *)mid;
-(void)smtlkV20EventPingFailed;
-(void)smtlkV20ScanAPList:(NSArray *)apList isRefresh:(BOOL) isRefresh;
-(void)smtlkV20ScanAPListDone;
-(void)smtlkV20CleanAPList;
-(void)smtlkV20EventReConnected;
-(void)smtlkV20EventDisconnected;

@end

@class GCDAsyncUdpSocket;

@interface SmtlkManager : NSObject
{
    
}
@property (nonatomic, assign) SmtlkCmdStatus cmdStatus;
@property (nonatomic, weak) id<SmtlkManagerDelegate> delegate;
@property (nonatomic, retain) NSDate *dateATWMODE;


+ (id)sharedManager;
-(void) startSmtlk;
-(void) stopSmtlk;

/*发送口令发现WIFI模块*/
-(void) postDiscovery:(BOOL) autoWSCAN;
-(void) sendATCmd:(NSString *)sCmd tag:(SmtlkCommand) tag completion:(void (^)(BOOL result)) handler;
-(void) reloadUDPArgs;

-(void) startListenerForATWMODE;
@end
