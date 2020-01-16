#import "Smartlink.h"
#import "HFSmartLink.h"
#import "HFSmartLinkDeviceInfo.h"
#import <NetworkExtension/NetworkExtension.h>
#import <net/if.h>
#import <ifaddrs.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import "MFUtil.h"

static BOOL isConnecting = false;

@interface Smartlink(){
    //FrontEnd Info
    NSString *apSSID;
    NSString *currentSSID;
    NSString *currentPwd;
    
    RCTPromiseResolveBlock sendResolve;
    RCTPromiseRejectBlock sendReject;
    
    //SmartLink Instance
    HFSmartLink * smtlk;
    
    //Advanced Link Instance
    SmtlkManager *smtlkManager;
    NSMutableArray *wscanList;
    NSDate *startTime;
    
    //Send Command Router Info
    NSString *str;
    NSString *inSSID;
    NSString *inKey;
    NSString *cmdWSSSID;
}

@end

@implementation Smartlink

NSString * const WIFI_DISCONNECTED_MSG = @"Please enable WiFi and connect to your router...";
NSString * const TRY_AGAIN_MSG = @"Please try again...";
NSString * const NOT_SUPPORTED_DEVICE_MSG = @"Not supported in iOS<11.0...";
NSString * const NOT_DETECTED_SSID_MSG = @"Cannot detect SSID...Please grant location permission";
NSString * const UNMATCH_AP_DEVICE_MSG = @"Connected to wroung AP...";
NSString * const FAIL_SEND_CONFIG_MSG = @"Fail to send config request...";
NSString * const UNABLE_CONNECT_THERMOSTAT_MSG = @"Unable to connect thermostat\n\nplease make sure to turn your thermostat into AP mode...";
NSString * const UNSUPPORTED_ROUTER_MSG = @"Unsupported router...\n\nPlease try another router.";

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
    return dispatch_queue_create("com.facebook.React.AsyncLocalStorageQueue", DISPATCH_QUEUE_SERIAL);
}

RCT_EXPORT_METHOD(AP_ConfigWiFi:(NSString *)ssid pwd:(NSString *)pwd
                  connectResolver:(RCTPromiseResolveBlock)resolve
                  connectRejecter:(RCTPromiseRejectBlock)reject){
    if([MFUtil isWiFiConnected]){
        if ([self isIOS11OrNewer]) {
            if([[self get_ssid] isEqualToString: self->apSSID]){
                isConnecting = true;
                
                self-> currentSSID = ssid;
                self-> currentPwd = pwd;
                
                wscanList=[[NSMutableArray alloc] initWithCapacity:0];
                self->sendReject = reject;
                self->sendResolve = resolve;
                self->smtlkManager = [SmtlkManager sharedManager];
                self->smtlkManager.delegate = self;
                self->smtlkManager.startTime = [NSDate date];
                [self->smtlkManager startSmtlk];
                
            } else {
                reject(@"Error", UNMATCH_AP_DEVICE_MSG, nil);
            }
        } else {
            reject(@"Error", NOT_SUPPORTED_DEVICE_MSG, nil);
        }
    }else{
        reject(@"Error", WIFI_DISCONNECTED_MSG, nil);
    }
}

RCT_EXPORT_METHOD(SL_Connect:(NSString *)ssid pwd:(NSString *)pwd
                  connectResolver:(RCTPromiseResolveBlock)resolve
                  connectRejecter:(RCTPromiseRejectBlock)reject)
{
    smtlk = [HFSmartLink shareInstence];
    smtlk.isConfigOneDevice = false;
    smtlk.waitTimers = 30;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Call long-running code on background thread
        if(!isConnecting){
            isConnecting = true;
            [self->smtlk startWithSSID:ssid Key:pwd UserStr:@"" withV3x:false processblock: ^(NSInteger pro) {
            } successBlock:^(HFSmartLinkDeviceInfo *dev) {
                NSDictionary * device = @{
                    @"mac": dev.mac,
                    @"ip" : dev.ip
                };
                resolve(device);
            } failBlock:^(NSString *failmsg) {
                reject(@"error", failmsg, nil);
            } endBlock:^(NSDictionary *deviceDic) {
                isConnecting  = false;
            }
             ];
        } else {
            [self->smtlk stopWithBlock:^(NSString *stopMsg, BOOL isOk) {
                if(isOk){
                    isConnecting  = false;
                    reject(@"error", TRY_AGAIN_MSG, nil);
                }else{
                    reject(@"error", stopMsg, nil);
                }
            }];
        }
    });
}

RCT_EXPORT_METHOD(SL_StopConnect:
                  (RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    if(smtlk != nil && isConnecting){
        [smtlk stopWithBlock:^(NSString *stopMsg, BOOL isOk) {
            if(isOk){
                resolve(@YES);
            }else{
                reject(@"Error", stopMsg, nil);
            }
        }];
    } else {
        resolve(@YES);
    }
    smtlk = nil;
    isConnecting  = false;
    sendResolve = nil;
    sendReject = nil;
}

RCT_EXPORT_METHOD(AP_StopConnect:
                  (RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject){
    if([self ap_StopConnect: nil]){
        resolve(@YES);
    } else {
        resolve(@NO);
    }
}


RCT_EXPORT_METHOD(isAvailableConnectWiFi:
                  (RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    resolve([self isIOS11OrNewer]);
}

RCT_EXPORT_METHOD(Connect_WiFi_Secure:(NSString*)ssid
                  withPassphrase:(NSString*)passphrase
                  connectResolver:(RCTPromiseResolveBlock)resolve
                  connectRejecter:(RCTPromiseRejectBlock)reject)
{
    if ([self isIOS11OrNewer]) {
        if([MFUtil isWiFiConnected]){
            currentSSID = ssid;
            currentPwd = passphrase;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NEHotspotConfiguration* configuration = [[NEHotspotConfiguration alloc] initWithSSID:ssid passphrase:passphrase isWEP:false];
                configuration.joinOnce = false;
                
                [[NEHotspotConfigurationManager sharedManager] applyConfiguration:configuration completionHandler:^(NSError * _Nullable error) {
                    if (error != nil) {
                        NSString * msg =[error localizedDescription];
                        NSLog(@"%@",msg);
                        reject(@"Error", msg, nil);
                    } else {
                        resolve(@YES);
                    }
                }];
            });
        }else{
            reject(@"Error", WIFI_DISCONNECTED_MSG, nil);
        }
    } else {
        reject(@"Error", NOT_SUPPORTED_DEVICE_MSG, nil);
    }
}

RCT_EXPORT_METHOD(Connect_WiFi:(NSString*)ssid
                  connectResolver:(RCTPromiseResolveBlock)resolve
                  connectRejecter:(RCTPromiseRejectBlock)reject)
{
    if ([self isIOS11OrNewer]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NEHotspotConfiguration* configuration = [[NEHotspotConfiguration alloc] initWithSSID:ssid];
            configuration.joinOnce = false;
            
            [[NEHotspotConfigurationManager sharedManager] applyConfiguration:configuration completionHandler:^(NSError * _Nullable error) {
                if (error != nil) {
                    if(error.code == 7){
                        resolve(@NO);
                    }else{
                        NSString * msg =[error localizedDescription];
                        NSLog(@"%@",msg);
                        reject(@"Error", msg, nil);
                    }
                } else {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        for (int i=0; i < 5; i++) {
                            if([[self get_ssid] isEqualToString: ssid]){
                                self->apSSID = ssid;
                                resolve(@YES);
                                return;
                            }
                            [NSThread sleepForTimeInterval:1.0f];
                        }
                        reject(@"Error", UNABLE_CONNECT_THERMOSTAT_MSG, nil);
                    });
                }
            }];
        });
    } else {
        reject(@"Error", NOT_SUPPORTED_DEVICE_MSG, nil);
    }
}

RCT_REMAP_METHOD(Get_SSID,
                 connectResolver:(RCTPromiseResolveBlock)resolve
                 connectRejecter:(RCTPromiseRejectBlock)reject)
{
    NSString *ssid = [self get_ssid];
    if(ssid != nil){
        resolve(ssid);
    }else{
        reject(@"Error",NOT_DETECTED_SSID_MSG, nil);
    }
}

RCT_EXPORT_METHOD(Remove_SSID:(NSString*)apssid
                  connectResolver:(RCTPromiseResolveBlock)resolve
                  connectRejecter:(RCTPromiseRejectBlock)reject)
{
    if([self isIOS11OrNewer]){
        [[NEHotspotConfigurationManager sharedManager] getConfiguredSSIDsWithCompletionHandler:^(NSArray<NSString *> *ssids) {
            if (ssids != nil && [ssids indexOfObject:apssid] != NSNotFound) {
                [[NEHotspotConfigurationManager sharedManager] removeConfigurationForSSID:apssid];
            }
            resolve(@YES);
        }];
    } else {
        reject(@"Error", NOT_SUPPORTED_DEVICE_MSG, nil);
    }
}

- (NSNumber *) ap_StopConnect: (NSString*) errorMsg{
    if(smtlkManager != nil && isConnecting){
        if(errorMsg!= nil){
            sendReject(@"Error", errorMsg, nil);
        }
        isConnecting = false;
        [smtlkManager stopSmtlk];
        [wscanList removeAllObjects];
        smtlkManager = nil;
        //        apSSID = nil;
        //        currentSSID = nil;
        //        currentPwd = nil;
        startTime = nil;
        str = nil;
        inSSID = nil;
        inKey = nil;
        cmdWSSSID = nil;
        sendResolve = nil;
        sendReject = nil;
    }
    return @YES;
}

- (NSString *) get_ssid {
    NSString *ssid = nil;
    
    NSString *kSSID = (NSString*) kCNNetworkInfoKeySSID;
    
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    for (NSString *ifnam in ifs) {
        NSDictionary *info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info[kSSID]) {
            ssid = info[kSSID];
        }
    }
    
    return ssid;
}

- (NSNumber *) isIOS11OrNewer {
    NSNumber *available = @NO;
    if (@available(iOS 11.0, *)) {
        available = @YES;
    }
    return available;
}

#pragma mark - delegate
-(void)smtlkV20Event:(BOOL)success wscanSSid:(NSString *)ssid mac:(NSString *)mac security:(NSString *)secu{
    NSLog(@" smtlkV20Event");
}

/*发送AT+WSCAN命令后的返回，每条返回包括搜到的一个路由器的SSID、MAC、加密方式*/
-(void)smtlkV20EventDiscover:(NSString *)host MAC:(NSString *)mac MID:(NSString *)mid
{
    NSLog(@" smtlkV20EventDiscover");
    //    [smtlk sendATCMD:@"AT+WSCAN\r"];
}

-(void)smtlkV20EventDisconnected: (NSString *)errorMsg {
    NSLog(@"❌ smtlkV20EventDisconnected");
    NSString *msg = UNABLE_CONNECT_THERMOSTAT_MSG;
    if(errorMsg != nil){
        msg = errorMsg;
    }
    [self ap_StopConnect:msg ];
}

-(void)smtlkV20CleanAPList {
    NSLog(@" smtlkV20CleanAPList");
    [wscanList removeAllObjects];
}

-(void)smtlkV20ScanAPListDone {
    NSLog(@" smtlkV20ScanAPListDone");
    for (NSDictionary *item in wscanList) {
        NSLog( @"AP List .... : %@", item );
        NSLog( @"AP SSID .... : %@", item[@"ssid"] );
        if([item[@"ssid"] isEqualToString: currentSSID]){
            [self->smtlkManager startListenerForATWMODE];
            
            str=[item[@"security"] substringWithRange:NSMakeRange(0, 2)];
            inSSID = self->currentSSID ? self->currentSSID : @"";
            inKey = self->currentPwd ? self->currentPwd : @"";
            cmdWSSSID = [[NSString alloc] initWithFormat:@"AT+WSSSID=%@\r", inSSID];
            
            self->smtlkManager.cmdStatus = SmtlkCmdStatus_AT_WSSSID;
            [self->smtlkManager sendATCmd:cmdWSSSID tag:SmtlkCommand_AT_WSSSID completion:^(BOOL result) {
                //
            }];
            return;
        }
    }
    
    [self ap_StopConnect: UNSUPPORTED_ROUTER_MSG];
}

-(void)smtlkV20ScanAPList:(NSArray *)apList isRefresh:(BOOL)isRefresh;
{
    NSLog(@"\n\tscanResult=%@, refresh=%@", @([apList count]), @(isRefresh));
    if(isRefresh)
    {
        [wscanList removeAllObjects];
    }
    if(apList)
    {
        [apList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSDictionary *info = obj;
            [wscanList addObject:info];
        }];
    }
}

-(void)smtlkV20ScanWSSSID_Done {
    NSLog(@"\n smtlkV20ScanWSSSID_Done");
    
    self->smtlkManager.cmdStatus = SmtlkCmdStatus_AT_WSKEY;
    
    NSString *cmdWSKEY = @"";
    
    if ([str isEqualToString:@"WP"])
    {
        cmdWSKEY = [[NSString alloc] initWithFormat:@"AT+WSKEY=WPA2PSK,AES,%@\r", inKey];
    }
    else if ([str isEqualToString:@"WE"])
    {
        if (([inKey length]==5)||([inKey length]==13))
            cmdWSKEY = [[NSString alloc] initWithFormat:@"AT+WSKEY=SHARED,WEP-A,%@\r", inKey];
        else
            cmdWSKEY = [[NSString alloc] initWithFormat:@"AT+WSKEY=SHARED,WEP-H,%@\r", inKey];
    }
    else
    {
        cmdWSKEY = [[NSString alloc] initWithFormat:@"AT+WSKEY=open,none\r"];
    }
    
    [self->smtlkManager sendATCmd:cmdWSKEY tag:SmtlkCommand_AT_WSKEY completion:^(BOOL result) {
        //
    }];
}

-(void) smtlkV20ScanWSKEY_Done {
    NSLog(@"\n smtlkV20ScanWSKEY_Done");
    
    self->smtlkManager.cmdStatus = SmtlkCmdStatus_AT_WMODE;
    
    NSString *cmdWMODE = [[NSString alloc] initWithFormat:@"AT+WMODE=sta\r"];
    
    [self->smtlkManager setDateATWMODE:[NSDate date]];
    
    [self->smtlkManager sendATCmd:cmdWMODE tag:SmtlkCommand_AT_WMODE completion:^(BOOL result) {
        //
    }];
}
-(void) smtlkV20ScanWMODE_Done {
    NSLog(@"\n smtlkV20ScanWMODE_Done");
    
    self->smtlkManager.cmdStatus = SmtlkCmdStatus_AT_Z;
    
    NSString *cmdZ = [[NSString alloc] initWithFormat:@"AT+Z\r\n"];
    
    [self->smtlkManager sendATCmd:cmdZ tag:SmtlkCommand_AT_Z completion:^(BOOL result) {
        NSLog(@"\n SmtlkCmdStatus_AT_WMODE_Done");
        self->sendResolve(@YES);
        [self ap_StopConnect:nil];
    }];
}
@end
