#import "Smartlink.h"
#import "HFSmartLink.h"
#import "HFSmartLinkDeviceInfo.h"
#import <NetworkExtension/NetworkExtension.h>
#import <SystemConfiguration/CaptiveNetwork.h>

@implementation Smartlink

static BOOL isconnecting = false;
BOOL v3xSupport= false;
static NSString *currentSSID;
static NSString *currentPwd;

NSString * userStr= @"";
HFSmartLink * smtlk;

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
    return dispatch_queue_create("com.facebook.React.AsyncLocalStorageQueue", DISPATCH_QUEUE_SERIAL);
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
        if(!isconnecting){
            isconnecting = true;
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
                isconnecting  = false;
            }
             ];
        } else {
            [smtlk stopWithBlock:^(NSString *stopMsg, BOOL isOk) {
                if(isOk){
                    isconnecting  = false;
                    reject(@"error", @"Please try again...", nil);
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
    if(smtlk != nil && isconnecting){
        [smtlk stopWithBlock:^(NSString *stopMsg, BOOL isOk) {
            if(isOk){
                isconnecting  = false;
                resolve(@"");
            }else{
                reject(@"", stopMsg, nil);
            }
        }];
    } else {
        resolve(@"");
    }
}

RCT_EXPORT_METHOD(isAvailableConnectWiFi:
                  (RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSNumber *available = @NO;
    if (@available(iOS 11.0, *)) {
        available = @YES;
    }
    resolve(@[available]);
}

RCT_EXPORT_METHOD(Connect_WiFi_Secure:(NSString*)ssid
                  withPassphrase:(NSString*)passphrase
                  connectResolver:(RCTPromiseResolveBlock)resolve
                  connectRejecter:(RCTPromiseRejectBlock)reject)
{
    if (@available(iOS 11.0, *)) {
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
                    resolve(@"Done");
                }
            }];
        });
    } else {
        reject(@"Error", @"Not supported in iOS<11.0", nil);
    }
}

RCT_EXPORT_METHOD(Connect_WiFi:(NSString*)ssid
                  connectResolver:(RCTPromiseResolveBlock)resolve
                  connectRejecter:(RCTPromiseRejectBlock)reject)
{
    if (@available(iOS 11.0, *)) { dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NEHotspotConfiguration* configuration = [[NEHotspotConfiguration alloc] initWithSSID:ssid];
        configuration.joinOnce = true;
        
        [[NEHotspotConfigurationManager sharedManager] applyConfiguration:configuration completionHandler:^(NSError * _Nullable error) {
            if (error != nil) {
                NSString * msg =[error localizedDescription];
                NSLog(@"%@",msg);
                reject(@"Error", msg, nil);
            } else {
                resolve(@"Done");
            }
        }];
    });
    } else {
        reject(@"Error", @"Not supported in iOS<11.0", nil);
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
        reject(@"Error",@"Cannot detect SSID", nil);
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

@end
