#import "Smartlink.h"
#import "HFSmartLink.h"
#import "HFSmartLinkDeviceInfo.h"
#import <NetworkExtension/NetworkExtension.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <net/if.h>
#import <ifaddrs.h>

@implementation Smartlink

static BOOL isConnecting = false;
BOOL v3xSupport= false;
static NSString *apSSID;
static NSString *currentSSID;
static NSString *currentPwd;
NSString * const WIFI_DISCONNECTED_MSG = @"Please enable Wifi and connect to your router.";
NSString * const TRY_AGAIN_MSG = @"Please try again...";
NSString * const NOT_SUPPORTED_MSG = @"Not supported in iOS<11.0";
NSString * const NOT_DETECTED_SSID_MSG = @"Cannot detect SSID";
NSString * const UNMATCH_AP_DEVICE_MSG = @"Connected to wroung AP...";
NSString * userStr= @"";
static HFSmartLink * smtlk;

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
    return dispatch_queue_create("com.facebook.React.AsyncLocalStorageQueue", DISPATCH_QUEUE_SERIAL);
}

RCT_EXPORT_METHOD(AP_ConfigWiFi:(NSString *)ssid pwd:(NSString *)pwd
                  connectResolver:(RCTPromiseResolveBlock)resolve
                  connectRejecter:(RCTPromiseRejectBlock)reject){
    if([self isWiFiEnabled]){
        if (@available(iOS 11.0, *)) {
            NSString * current = [self get_ssid];
            if(current == apSSID){
                currentSSID = ssid;
                currentPwd = pwd;
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
            [smtlk startWithSSID:ssid Key:pwd UserStr:userStr withV3x:v3xSupport processblock: ^(NSInteger pro) {
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
            [smtlk stopWithBlock:^(NSString *stopMsg, BOOL isOk) {
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
        if([self isWiFiEnabled]){
            currentSSID = ssid;
            currentPwd = passphrase;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NEHotspotConfiguration* configuration = [[NEHotspotConfiguration alloc] initWithSSID:ssid passphrase:passphrase isWEP:false];
                configuration.joinOnce = true;
                
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
    if (@available(iOS 11.0, *)) { dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        apSSID = ssid;
        NEHotspotConfiguration* configuration = [[NEHotspotConfiguration alloc] initWithSSID:ssid];
        configuration.joinOnce = true;
        
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

- (BOOL) isWiFiEnabled {
    NSCountedSet * cset = [[NSCountedSet alloc] init];
    struct ifaddrs *interfaces;
    if( ! getifaddrs(&interfaces) ) {
        for( struct ifaddrs *interface = interfaces; interface; interface = interface->ifa_next) {
            if ( (interface->ifa_flags & IFF_UP) == IFF_UP ) {
                [cset addObject:[NSString stringWithUTF8String:interface->ifa_name]];
            }
        }
    }
    return [cset countForObject:@"awdl0"] > 1 ? YES : NO;
}

@end
