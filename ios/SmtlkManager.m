//
//  SmtlkManager.m
//  SmartLink V2.0
//
//  Created by Peter on 14-3-4.
//  Copyright (c) 2014年 Peter. All rights reserved.
//

#import "SmtlkManager.h"
#import "GCDAsyncUdpSocket.h"
#import "STDPingServices.h"
#import "Macros.h"
#import "MFUtil.h"

#define SMTLKUDPBCADD @"255.255.255.255"
#define SMTLKUDPRMPORT 48899
#define SMTLKDISCOVERY_DEFAULT      @"HF-A11ASSISTHREAD"
#define PINGTIMOUT_MAXRETRY      5
static SmtlkManager* _instance = nil;

@interface SmtlkManager()<GCDAsyncUdpSocketDelegate>
{

    
    NSString *hostMAC;
    NSString *hostMID;
    NSString *udpHost;
    uint16_t udpLocalPort;

}
@property (nonatomic, retain) GCDAsyncUdpSocket *udpSockBroadCast;

@property (nonatomic, retain) NSMutableArray *arrAP;
@property (nonatomic, retain) NSString *udpBCAddr;
@property (nonatomic, assign) NSInteger udpRMPort;
@property (nonatomic, retain) NSString *cmdDiscovery;
@property (nonatomic, assign) BOOL inCommandMode;
@property (nonatomic, retain) dispatch_source_t timer;
@property (nonatomic, retain) dispatch_source_t timerForWMode;
@property (nonatomic, retain) STDPingServices *pingServices;
@property (nonatomic, assign) NSInteger pingTimeoutRetry;
@property (nonatomic, assign) BOOL autoWSCAN;
@end

@implementation SmtlkManager

+ (id)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[SmtlkManager alloc] init];
    });
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _cmdStatus = SmtlkCmdStatus_None;
        
        if(![[NSUserDefaults standardUserDefaults] objectForKey:@"kUDPBCAddr"])
        {
            [[NSUserDefaults standardUserDefaults] setObject:SMTLKUDPBCADD forKey:@"kUDPBCAddr"];

        }
        _udpBCAddr = [[NSUserDefaults standardUserDefaults] objectForKey:@"kUDPBCAddr"];
        
        if(![[NSUserDefaults standardUserDefaults] objectForKey:@"kUDPRMPort"])
        {
            [[NSUserDefaults standardUserDefaults] setValue:@(SMTLKUDPRMPORT) forKey:@"kUDPRMPort"];
            
        }
        _udpRMPort = [[[NSUserDefaults standardUserDefaults] valueForKey:@"kUDPRMPort"] integerValue];
        
        if(![[NSUserDefaults standardUserDefaults] objectForKey:@"kCMDDiscovery"])
        {
            [[NSUserDefaults standardUserDefaults] setObject:SMTLKDISCOVERY_DEFAULT forKey:@"kCMDDiscovery"];
            
        }


    }
    return self;
}

-(void) resetUDPArgs
{
    [[NSUserDefaults standardUserDefaults] setObject:SMTLKUDPBCADD forKey:@"kUDPBCAddr"];
    [[NSUserDefaults standardUserDefaults] setValue:@(SMTLKUDPRMPORT) forKey:@"kUDPRMPort"];
    [[NSUserDefaults standardUserDefaults] setObject:SMTLKDISCOVERY_DEFAULT forKey:@"kCMDDiscovery"];

    _udpBCAddr = [[NSUserDefaults standardUserDefaults] objectForKey:@"kUDPBCAddr"];
    _udpRMPort = [[[NSUserDefaults standardUserDefaults] valueForKey:@"kUDPRMPort"] integerValue];
    _cmdDiscovery = [[NSUserDefaults standardUserDefaults] valueForKey:@"kCMDDiscovery"];
}

-(void) reloadUDPArgs
{
    _udpBCAddr = [[NSUserDefaults standardUserDefaults] objectForKey:@"kUDPBCAddr"];
    _udpRMPort = [[[NSUserDefaults standardUserDefaults] valueForKey:@"kUDPRMPort"] integerValue];
    _cmdDiscovery = [[NSUserDefaults standardUserDefaults] valueForKey:@"kCMDDiscovery"];
}

-(void) restartSmtlk
{
    [self stopSmtlk];
    [self startSmtlk];
}

-(void) startSmtlk
{

    [self reloadUDPArgs];
    if(_timer)
    {
        
        dispatch_cancel(_timer);
        self.timer = nil;;
    }
    if(_timerForWMode)
    {
        dispatch_cancel(_timerForWMode);
        self.timerForWMode = nil;
    }
    // Peter: code for UDP
    self.udpSockBroadCast = [[GCDAsyncUdpSocket alloc] initWithDelegate:self
                                            delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    

    
    NSError *error = nil;
    
    // Peter: enable BroadCast
    if(![self.udpSockBroadCast enableBroadcast:YES error:&error])
    {
        NSLog(@"\Error enable broadcast: %@", error);
        return;
        
    }
    
    if(![self.udpSockBroadCast enableReusePort:YES error:&error])
    {
        NSLog(@"\Error enable ReusePort: %@", error);
        return;
        
    }
    
    
    if (![self.udpSockBroadCast bindToPort:10013 error:&error])
    {
        NSLog(@"\Error binding: %@", error);
        return;
    }
    
    if (![self.udpSockBroadCast beginReceiving:&error])
    {
        NSLog(@"Error receiving: %@", error);
        return;
    }
    
    self.arrAP = [[NSMutableArray alloc] initWithCapacity:0];
    self.cmdStatus = SmtlkCmdStatus_None;
    self.dateATWMODE = nil;
    NSLog(@"\nUDP bind&enable broadcast, localHost= %@, port=%hu!", self.udpSockBroadCast.localHost, self.udpSockBroadCast.localPort);
//    self.timer = [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(smtlkTimeOut) userInfo:nil repeats:YES];
    
    [self smtlkTimeOut];
}

-(void) stopSmtlk
{
    // Peter: code for UDP
    [self.udpSockBroadCast close];
    self.arrAP = [[NSMutableArray alloc] initWithCapacity:0];
    self.cmdStatus = SmtlkCmdStatus_None;
    if(_timer)
    {
        dispatch_cancel(_timer);
        self.timer = nil;;
    }
    if(_timerForWMode)
    {
        dispatch_cancel(_timerForWMode);
        self.timerForWMode = nil;
    }
    self.inCommandMode = NO;
    self.pingServices = nil;
    self.pingTimeoutRetry = 0;
    self.dateATWMODE = nil;

    
    // 主线程执行：
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->_delegate && [self->_delegate respondsToSelector:@selector(smtlkV20CleanAPList)])
        {
            [self->_delegate smtlkV20CleanAPList];
        }
    });


    NSLog(@"UDP closed");

}


-(void) postDiscovery:(BOOL) autoWSCAN
{
    NSData *sd;
    self.autoWSCAN = autoWSCAN;
    self.inCommandMode = NO;
    self.cmdStatus = SmtlkCmdStatus_ASSISTHREAD;
    self.dateATWMODE = nil;
    NSLog(@"send:%@", _cmdDiscovery);
    sd = [_cmdDiscovery dataUsingEncoding: NSASCIIStringEncoding];
    
    [self.udpSockBroadCast sendData:sd
               toHost:_udpBCAddr
                 port:_udpRMPort
          withTimeout:-1
                  tag:SmtlkCommand_DISCOVERY];
}

- (void)smtlkTimeOut
{
    WS(ws);
    NSTimeInterval period = 3.0; //设置时间间隔
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t timerOne = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(timerOne, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0); //每period秒执行
        dispatch_source_set_event_handler(timerOne, ^{
        
        if([MFUtil isWiFiConnected] && [MFUtil routerIp])
        {
            // when the wifi has been selected, and the AP module has an ip address. to check ping
            NSLog(@"udpHost=%@", self->udpHost);
            if(!(ws.inCommandMode))
            {
                [ws postDiscovery:YES];
            }
            
            NSString *apIp = [NSString stringWithFormat:@"%@", self->udpHost?self->udpHost:@""];
            if(apIp && [apIp length] > 0)
            {
                if(!(ws.pingServices))
                {
                    
                    NSString *pingToIP = [NSString stringWithFormat:@"%@", apIp];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        ws.pingServices =
                        [STDPingServices startPingAddress:apIp
                                          callbackHandler:^(STDPingItem *pingItem, NSArray *pingItems)
                         {
                             if (pingItem.status != STDPingStatusFinished)
                             {
                                 NSLog(@"\nping %@ statue=%@,(%@)",pingToIP, @(pingItem.status), pingItem.description);
                                 if([pingToIP isEqualToString:apIp])
                                 {
                                     if(pingItem.status == STDPingStatusDidReceivePacket)
                                     {
                                         // When the AP module is able to be ping ok. try into the command mode;
                                         ws.pingTimeoutRetry = 0;
               
                                     }
                                     else if(pingItem.status == STDPingStatusDidTimeout
                                             || pingItem.status == STDPingStatusError)
                                     {
                                         // timeout or error, the retry count be increase;
                                         // if the retry reach to max count.
                                         // stop ping service. and reset retry count.
                                         // exit command mode.
                                         // notfiy the UI, clean ap list.
                                         
                                         ws.pingTimeoutRetry++;
                                         
                                         if(ws.pingTimeoutRetry >= PINGTIMOUT_MAXRETRY)
                                         {
//                                             ws.pingTimeoutRetry = 0;
//                                             ws.inCommandMode = NO;
//                                             udpHost = nil;
                                             
                                             
                                              ws.pingServices = nil;
                                             
                                             [ws restartSmtlk];
//                                             [ws.arrAP removeAllObjects];
                                             
//                                             if(ws.delegate
//                                                && [ws.delegate respondsToSelector:@selector(smtlkV20EventPingFailed)])
//                                             {
//                                                 [ws.delegate smtlkV20EventPingFailed];
//                                             }
                                         }
                                     }
                                 }
                                 else
                                 {
                                     ws.pingTimeoutRetry = 0;
                                     ws.pingServices = nil;
                                 }
                             }
                             else
                             {
                                 ws.pingTimeoutRetry = 0;
                                 ws.pingServices = nil;
                             }
                         }];
                    });
                    
                }
            }
            
            //
            
        }
        
    });
    
    dispatch_resume(timerOne);
    
    self.timer = timerOne;
    
}

-(void) sendATCmd:(NSString *)sCmd tag:(SmtlkCommand) tag completion:(void (^)(BOOL result)) handler
{
    if(!sCmd && [sCmd length] <= 0)
    {
        if(handler)
        {
            handler(NO);
        }
    }
    NSLog(@"send:%@", sCmd);
    NSData *sd= [sCmd dataUsingEncoding: NSASCIIStringEncoding];
    
    NSInteger timeout = -1;
    if(tag == SmtlkCommand_AT_WMODE)
    {
        timeout = 10;
    }
    [self.udpSockBroadCast sendData:sd toHost:udpHost port:_udpRMPort withTimeout:timeout tag:tag];
    
    if(handler)
    {
        handler(YES);
    }
}

-(void) startListenerForATWMODE
{
    WS(ws);
    NSTimeInterval period = 1.0; //设置时间间隔
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_source_t timerOne = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    dispatch_source_set_timer(timerOne, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0); //每秒执行
    
    dispatch_source_set_event_handler(timerOne, ^{
        
        //在这里执行事件
        if(ws.dateATWMODE)
        {
            double intervalTime = [ws.dateATWMODE timeIntervalSinceNow];
            if(intervalTime < -10)
            {
                dispatch_cancel(timerOne);
                ws.timerForWMode = nil;
                [ws restartSmtlk];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    // 主线程执行：
                    dispatch_async(dispatch_get_main_queue(), ^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (self->_delegate && [self->_delegate respondsToSelector:@selector(smtlkV20EventReConnected)])
                            {
                                [self->_delegate smtlkV20EventReConnected];
                            }
                        });
                    });
                    
                });
           
            }

        }

        
    });
    
    dispatch_resume(timerOne);
    
    self.timerForWMode = timerOne;
}

#pragma mark - delegate
- (void)udpSocket:(GCDAsyncUdpSocket *)sock
   didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    NSString *host = nil;
    uint16_t port = 0;
    [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
    
    NSString *s = [[[NSString alloc] initWithData:data
                                         encoding:NSASCIIStringEncoding]
                   stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
    
    
    NSLog(@"udpSocket.state=%@, resp:%@", @(self.cmdStatus), s);
    if(s && [s isEqualToString:@"+ok"])
    {
        // wmode has been done;
        [self setDateATWMODE:[NSDate date]];
    }
    
    if([sock isEqual:self.udpSockBroadCast] &&  self.cmdStatus == SmtlkCmdStatus_ASSISTHREAD)
    {
        // 成功进入命令行
        [self onEventDiscovery:s];
        self.cmdStatus = SmtlkCmdStatus_ASSISTHREAD_Done;
        
        if(self.autoWSCAN)
        {
            self.cmdStatus = SmtlkCmdStatus_AT_WSCAN;
            
            [self sendATCmd:@"AT+WSCAN\r\n" tag:SmtlkCommand_AT_WSCAN completion:^(BOOL result) {
                
            }];
        }
        return;
    }
    
    if([sock isEqual:self.udpSockBroadCast] && self.cmdStatus == SmtlkCmdStatus_AT_WSCAN)
    {
        NSLog(@"\n%@", [MFUtil hexStringFromString:s]);
        
        [self parseWSCANResult:s];
    }
    
 

}


- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address
{

}


- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError * _Nullable)error
{
    NSLog(@"error=%@", error);

}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSLog(@"tag=%@", @(tag));
}


- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError * _Nullable)error
{
    self.inCommandMode = NO;
    NSLog(@"tag=%@", @(tag));
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError  * _Nullable)error
{
    NSLog(@"close, error=%@", error);
}

#pragma mark - data handler
-(void)parseWSCANResult:(NSString *)sResult
{
    WS(ws);

    BOOL isRefresh = YES;
    if([sResult hasPrefix:@"+ok="])
    {
        // AP list packet header "+ok="
        // clean first.
        isRefresh = YES;
        [self.arrAP removeAllObjects];
    }
    else
    {
        isRefresh = NO;
    }
    
    NSArray *arr = [sResult componentsSeparatedByString:@"\r\n"];
    if([arr count] == 1)
    {
        NSMutableArray *arrThisAP = [[NSMutableArray alloc] initWithCapacity:0];
        NSString *row = arr[0];
        NSArray *arrColumn =[row componentsSeparatedByString:@","];
        if([arrColumn count] == 5 && ![[arrColumn[1] uppercaseString] isEqualToString:@"SSID"])
        {
            NSLog(@"last the AP， %@", row);
            [arrThisAP addObject:@{@"ssid":arrColumn[1], @"mac":arrColumn[2], @"security":arrColumn[3]}];
            NSLog(@"callback the result for delegate.1");

            
            [ws.arrAP addObjectsFromArray:arrThisAP];

            // 主线程执行：
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self->_delegate && [self->_delegate respondsToSelector:@selector(smtlkV20ScanAPList:isRefresh:)])
                {
                    [self->_delegate smtlkV20ScanAPList:arrThisAP isRefresh:isRefresh];
                }
            });
     
        }
        else if([arrColumn count] == 1)
        {
            NSLog(@"Instruction， %@", row);
        }
        else
        {
            NSLog(@"Unknown，%@", row);
        }
    }
    else if([arr count] > 1)
    {
        // no first，no last
        __block BOOL hadAP = NO;
        
        NSMutableArray *arrThisAP = [[NSMutableArray alloc] initWithCapacity:0];
        [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *row = obj;
            NSArray *arrColumn =[row componentsSeparatedByString:@","];
            if([arrColumn count] == 5 && ![[arrColumn[1] uppercaseString] isEqualToString:@"SSID"])
            {
                // Intermediate AP.
                NSLog(@"Intermediate AP， %@", row);
                [arrThisAP addObject:@{@"ssid":arrColumn[1], @"mac":arrColumn[2], @"security":arrColumn[3]}];
                hadAP = YES;
            }
            else if([arrColumn count] == 1)
            {
                NSLog(@"Instruction， %@", row);
                hadAP = NO;

            }
            else
            {
                NSLog(@"Unknown，%@", obj);
                hadAP = NO;
            }
        }];
        
        NSLog(@"callback the result for delegate.2");
        if(hadAP)
        {
            [ws.arrAP addObjectsFromArray:arrThisAP];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self->_delegate && [self->_delegate respondsToSelector:@selector(smtlkV20ScanAPList:isRefresh:)])
                {
                    [self->_delegate smtlkV20ScanAPList:arrThisAP isRefresh:isRefresh];
                }
            });
   

        }

    }
    else
    {
        NSLog(@"Nothing");
    }
    
    //        self.cmdStatus = SmtlkCmdStatus_AT_WSCAN_Done;
    //        [self onEventGetList:s];
    return;
    
}

-(void)onEventDiscovery:(NSString *)str
{
    
    NSArray *a = [str componentsSeparatedByString:@","];
    NSInteger num = [a count];
    if ((num!= 2) && (num!= 3))
    {
        return;
    }
    
    if (num== 3)
    {
        udpHost = a[0];
        hostMAC = a[1];
        hostMID = a[2];
    }
    else
    {
        udpHost = a[0];
        hostMAC = a[1];
    }
    WS(ws);
    [self sendATCmd:@"+ok" tag:SmtlkCommand_PLUS_OK completion:^(BOOL result) {
        ws.inCommandMode = YES;
    }];
    
    // 主线程执行：
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_delegate && [_delegate respondsToSelector:@selector(smtlkV20EventDiscover:MAC:MID:)])
        {
            [_delegate smtlkV20EventDiscover:udpHost MAC:hostMAC MID:hostMID];
        }
    });

}

@end
