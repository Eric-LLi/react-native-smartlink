//
//  SmtlkV20.m
//  SmartLink V2.0
//
//  Created by Peter on 14-3-4.
//  Copyright (c) 2014年 Peter. All rights reserved.
//

#import "SmtlkV20.h"
#import "GCDAsyncUdpSocket.h"
#import "MFUtil.h"
//10.10.100.254
#define SMTLKUDPBCADD @"10.10.100.254"
#define SMTLKUDPRMPORT 48899

#define SMTLKDISCOVERY_DEFAULT      @"HF-A11ASSISTHREAD"

@implementation SmtlkV20
{
    id<SmtlkV20Event> delegate;
    GCDAsyncUdpSocket *udpSock;

    NSInteger state;
    NSString *discoveryStr;
    
    NSString *hostMAC;
    NSString *hostMID;
    NSString *udpHost;
    uint16_t udpLocalPort;
    uint16_t udpRmPort;
}

-(id)initWithDelegate:(id<SmtlkV20Event>)del
{
    self=[super init];
    if (self==nil)
        return nil;
    delegate=del;
    [self initSmatlkV30UDP];
    state= 0;
    NSLog(@"initWithDelegate.state=%@", @(state));
    return self;
}

- (void)initSmatlkV30UDP
{
    // Peter: code for UDP
	udpSock = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    udpRmPort= SMTLKUDPRMPORT;
    
	NSError *error = nil;
	if (![udpSock bindToPort:0 error:&error])
	{
		NSLog(@"Error binding: %@", error);
		return;
	}
	if (![udpSock beginReceiving:&error])
	{
		NSLog(@"Error receiving: %@", error);
		return;
	}
    // Peter: enable BroadCast
    [udpSock enableBroadcast:TRUE error:&error];
    
    NSLog(@"UDP Connected, localHost= %@, port=%hu!", udpSock.localHost, udpSock.localPort);
}

-(void)sendDiscovery:(NSString *)strDis
{
    NSData *sd;
    if (strDis==nil)
        discoveryStr=SMTLKDISCOVERY_DEFAULT;
    NSLog(@"send:%@", discoveryStr);
    sd= [discoveryStr dataUsingEncoding: NSASCIIStringEncoding];
    [udpSock sendData:sd toHost:SMTLKUDPBCADD port:udpRmPort withTimeout:-1 tag:0];
    [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(smtlkWaitingForDiscovey) userInfo:nil repeats:NO];
}

- (void)smtlkWaitingForDiscovey
{
    if (state== 0)
        [self sendDiscovery:discoveryStr];
}

-(void)sendATCMD:(NSString *)strCmd
{
    NSData *sd;
    if (state== 0)
        return;
    if (strCmd!= nil)
    {
        NSLog(@"send:%@", strCmd);
        sd= [strCmd dataUsingEncoding: NSASCIIStringEncoding];
        [udpSock sendData:sd toHost:udpHost port:udpRmPort withTimeout:-1 tag:0];
    }
}



#pragma mark - delegate
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
                                                fromAddress:(NSData *)address
                                        withFilterContext:(id)filterContext
{
    NSString *host = nil;
    uint16_t port = 0;
    [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
    
    NSString *s = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
//    NSArray *a = [s componentsSeparatedByString:@" "];
    
    NSLog(@"udpSocket,state=%@, subStr:%@", @(state), s);
//    NSLog(@"%@", s);
    if (state== 0)
        [self onEventState0:s];
    NSInteger len=[s length];

    if (len<10)
        [self onEventOther:s];
    else
        [self onEventGetList:s];
}

-(void)onEventOther:(NSString *)str
{
    if (delegate== nil)
        return;
    if ([str length]< 3)
    {
        NSLog(@"too short:%d, %@", (int)[str length], str);
        return;
    }
    NSString *subStr=[str substringWithRange:NSMakeRange(0, 3)];
    NSLog(@"onEventOther,subStr:%@", subStr);
    if ([subStr isEqualToString:@"+ok"])
        [delegate smtlkV20Event:TRUE];
    else if ([subStr isEqualToString:@"+ER"])
        [delegate smtlkV20Event:FALSE];
}

-(void)onEventGetList:(NSString *)str
{
    if (delegate==nil)
        return;
    
//    NSLog(@"parse the ssid list=%@", str);

    // org
//    NSArray *a = [str componentsSeparatedByString:@","];
//    NSInteger num=[a count];
//    if (num< 4)
//        return;
//    NSString *ssid, *mac, *secu;
//    ssid=a[1];
//    mac=a[2];
//    secu=a[3];
//    if ([ssid isEqualToString:@"SSID"])
//        return;
//    [delegate smtlkV20Event:TRUE wscanSSid:ssid mac:mac security:secu];
    
    // majunfei
    
    NSLog(@"\n%@", str);
    NSLog(@"\n%@", [MFUtil hexStringFromString:str]);
    NSRange range = [str rangeOfString:@"\r\n"];
    if([str hasPrefix:@"+ok="] && range.location != NSNotFound)
    {
        // LPB 120 data
        NSLog(@"\nLPB 120=%@", str);
        
        NSString *str120 = [str stringByReplacingOccurrencesOfString:@"\n\n" withString:@"\n"];
        NSArray *arr = [str120 componentsSeparatedByString:@"\n"];
        
        NSMutableArray *arrSSID = [[NSMutableArray alloc] initWithCapacity:0];
        [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *sRow = (NSString *)obj;
            NSArray *arrColumn = [sRow componentsSeparatedByString:@","];
            
            if([arrColumn count] >= 5)
            {
                if([[arrColumn[0] uppercaseString] isEqualToString:@"CH"])
                {
                    // header
                }
                else if([arrColumn count] >= 5)
                {
                    // ssid info data
                    [delegate smtlkV20Event:TRUE wscanSSid:arrColumn[1] mac:arrColumn[2] security:arrColumn[3]];
                    
                }
            }
            
        }];
    }
    else
    {
        // LPB 120 other or LPB 100
        
        NSArray *arr = [str componentsSeparatedByString:@"\n"];
        
        if([arr count] <= 0)
        {
            NSArray *arrColumn = [str componentsSeparatedByString:@","];
            if([arrColumn count] >= 5 && [[arrColumn[0] uppercaseString] isEqualToString:@"CH"])
            {
                // ssid header
                NSLog(@"\nssid header%@", str);
            }
            else if([arrColumn count] >= 5)
            {
                // ssid information
                NSLog(@"\nssid info=%@", str);
                [delegate smtlkV20Event:TRUE wscanSSid:arrColumn[1] mac:arrColumn[2] security:arrColumn[3]];
            }
        }
        else if([arr count] == 1)
        {
            // WSCAN result for LPB100. single ssid
            NSLog(@"\nWSCAN result for LPB100:%@", str);
            NSString *sRow = arr[0];
            
            NSArray *arrColumn = [sRow componentsSeparatedByString:@","];
            
            if([arrColumn count] == 1)
            {
                // +ok=
                NSLog(@"\n%@", arrColumn[0]);
            }
            else if([arrColumn count] == 3)
            {
                // LPB Information
                NSLog(@"\nLPB Information=%@", str);
            }
            else if([arrColumn count] >= 5 && [[arrColumn[0] uppercaseString] isEqualToString:@"CH"])
            {
                // ssid header
                NSLog(@"\nssid header%@", str);
            }
            else if([arrColumn count] >= 5)
            {
                // ssid information
                NSLog(@"\nssid info=%@", str);
                [delegate smtlkV20Event:TRUE wscanSSid:arrColumn[1] mac:arrColumn[2] security:arrColumn[3]];
            }
            
            //
            //        NSLog(@"WSCAN result for LPB100:%@", str);
            //        [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            //            NSLog(@"idx=%@, %@", @(idx), obj);
            //        }];
            
        }
        else if([arr count] > 1)
        {
            //        NSLog(@"WSCAN result for LPB120:%@", str);
            //        [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            //            NSLog(@"idx=%@, %@", @(idx), obj);
            //
            //        }];
        }
    }
}

-(void)onEventState0:(NSString *)str
{
    NSInteger num;
    NSArray *a = [str componentsSeparatedByString:@","];
    num=[a count];
    if ((num!= 2)&&(num!= 3))
        return;
    
    if (num== 3)
    {
        udpHost=a[0];
        hostMAC=a[1];
        hostMID=a[2];
    }
    else
    {
        udpHost=a[0];
        hostMAC=a[1];
    }
    NSLog(@"onEventState0,host:%@", udpHost);
    NSLog(@"onEventState0,mac:%@", hostMAC);
    if (hostMID!= nil)
        NSLog(@"onEventState0,mid:%@", hostMID);

    state= 1;           // get host
    NSLog(@"onEventState0.state=%@", @(state));

    [self sendATCMD:@"+ok"];
    if (delegate!=nil)
        [delegate smtlkV20EventDiscover:udpHost MAC:hostMAC MID:hostMID];
}

@end
