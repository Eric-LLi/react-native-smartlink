#import "Smartlink.h"
#import "HFSmartLink.h"
#import "HFSmartLinkDeviceInfo.h"
#import <NetworkExtension/NetworkExtension.h>
#import <net/if.h>
#import <ifaddrs.h>
#import <SystemConfiguration/CaptiveNetwork.h>
//#import "SmtlkV20.h"
#import "MFUtil.h"

static BOOL isConnecting = false;

@interface Smartlink(){
    NSString *apSSID;
    NSString *currentSSID;
    NSString *currentPwd;
    HFSmartLink * smtlk;
    RCTPromiseResolveBlock sendResolve;
    RCTPromiseRejectBlock sendReject;
    SmtlkManager *smtlkManager;
    NSMutableArray *wscanList;
}

@end

@implementation Smartlink

NSString * const WIFI_DISCONNECTED_MSG = @"Please enable WiFi and connect to your router...";
NSString * const TRY_AGAIN_MSG = @"Please try again...";
NSString * const NOT_SUPPORTED_MSG = @"Not supported in iOS<11.0...";
NSString * const NOT_DETECTED_SSID_MSG = @"Cannot detect SSID...";
NSString * const UNMATCH_AP_DEVICE_MSG = @"Connected to wroung AP...";
NSString * const FAIL_SEND_CONFIG_MSG = @"Fail to send config request...";
NSString * const UNABLE_CONNECT_THERMOSTAT_MSG = @"Unable to connect thermostat, please make sure turn your thermostat into AP mode...";
NSString * const UNSUPPORTED_ROUTER_MSG = @"Unsupported router...Please connect to another router.";

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
    return dispatch_queue_create("com.facebook.React.AsyncLocalStorageQueue", DISPATCH_QUEUE_SERIAL);
}

RCT_EXPORT_METHOD(AP_ConfigWiFi:(NSString *)ssid pwd:(NSString *)pwd
                  connectResolver:(RCTPromiseResolveBlock)resolve
                  connectRejecter:(RCTPromiseRejectBlock)reject){
    if([MFUtil isWiFiConnected]){
        if (@available(iOS 11.0, *)) {
            if([[self get_ssid] isEqualToString: self->apSSID]){
                wscanList=[[NSMutableArray alloc] initWithCapacity:0];
                self-> sendReject = reject;
                self-> sendResolve = resolve;
                self->smtlkManager = [SmtlkManager sharedManager];
                self->smtlkManager.delegate = self;
                [self->smtlkManager startSmtlk];
                
            } else {
                reject(@"Error", UNMATCH_AP_DEVICE_MSG, nil);
            }
        } else {
            reject(@"Error", NOT_SUPPORTED_MSG, nil);
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
                isConnecting  = false;
                resolve(@YES);
            }else{
                reject(@"Error", stopMsg, nil);
            }
        }];
    } else {
        resolve(@YES);
    }
}

RCT_EXPORT_METHOD(AP_StopConnect:
                  (RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject){
    if(smtlkManager != nil){
        [wscanList removeAllObjects];
        [smtlkManager stopSmtlk];
    }
}

RCT_EXPORT_METHOD(isAvailableConnectWiFi:
                  (RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSNumber *available = @NO;
    if (@available(iOS 11.0, *)) {
        available = @YES;
    }
    resolve(available);
}

RCT_EXPORT_METHOD(Connect_WiFi_Secure:(NSString*)ssid
                  withPassphrase:(NSString*)passphrase
                  connectResolver:(RCTPromiseResolveBlock)resolve
                  connectRejecter:(RCTPromiseRejectBlock)reject)
{
    if (@available(iOS 11.0, *)) {
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
        reject(@"Error", NOT_SUPPORTED_MSG, nil);
    }
}

RCT_EXPORT_METHOD(Connect_WiFi:(NSString*)ssid
                  connectResolver:(RCTPromiseResolveBlock)resolve
                  connectRejecter:(RCTPromiseRejectBlock)reject)
{
    if (@available(iOS 11.0, *)) {
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
        reject(@"Error", NOT_SUPPORTED_MSG, nil);
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

//- (BOOL) isWiFiEnabled {
//    NSCountedSet * cset = [[NSCountedSet alloc] init];
//    struct ifaddrs *interfaces;
//    if( ! getifaddrs(&interfaces) ) {
//        for( struct ifaddrs *interface = interfaces; interface; interface = interface->ifa_next) {
//            if ( (interface->ifa_flags & IFF_UP) == IFF_UP ) {
//                [cset addObject:[NSString stringWithUTF8String:interface->ifa_name]];
//            }
//        }
//    }
//    return [cset countForObject:@"awdl0"] > 1 ? YES : NO;
//}
#pragma mark - delegate
-(void)smtlkV20Event:(BOOL)success wscanSSid:(NSString *)ssid mac:(NSString *)mac security:(NSString *)secu{
    NSLog(@"❌ smtlkV20Event");
}

/*发送AT+WSCAN命令后的返回，每条返回包括搜到的一个路由器的SSID、MAC、加密方式*/
-(void)smtlkV20EventDiscover:(NSString *)host MAC:(NSString *)mac MID:(NSString *)mid
{
    NSLog(@"❌ smtlkV20EventDiscover");
    //    [smtlk sendATCMD:@"AT+WSCAN\r"];
}

-(void)smtlkV20EventDisconnected {
    NSLog(@"❌ smtlkV20EventDisconnected");
    [self->smtlkManager stopSmtlk];
    sendReject(@"Error", UNABLE_CONNECT_THERMOSTAT_MSG, nil);
}

-(void)smtlkV20CleanAPList {
    NSLog(@"❌ smtlkV20CleanAPList");
    [wscanList removeAllObjects];
}

-(void)smtlkV20ScanAPListDone {
    NSLog(@"❌ smtlkV20ScanAPListDone");
    //    BOOL checkExisted = false;
    for (NSDictionary *item in wscanList) {
        NSLog( @"AP List .... : %@", item );
        if([item[@"ssid"] isEqualToString: currentSSID]){
            //            checkExisted = true;
            return;
        }
    }
    [smtlkManager stopSmtlk];
    sendReject(@"Error", UNSUPPORTED_ROUTER_MSG, nil);
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
        
        if([apList count] > 0)
        {
            //            [_tblWscanList reloadData];
        }
    }
}


@end
