import { NativeModules } from 'react-native';

const { Smartlink } = NativeModules;

class Index{
    constructor(){
        //
    }

    SL_Connect = (ssid, pwd) => {
        return Smartlink.SL_Connect(ssid, pwd);
    }

    AP_Connect = (ssid ,pwd ,apssid, appwd) => {
        return Smartlink.AP_Connect(ssid ,pwd ,apssid, appwd);
    }
    
    SL_StopConnect = () => {
        return Smartlink.SL_StopConnect();
    }
    
    AP_StopConnect = () => {
        return Smartlink.AP_StopConnect();
    }

    IsAvailableConnectWiFi = () => {
        return Smartlink.IsAvailableConnectWiFi();
    }

    Get_SSID = () => {
        return Smartlink.Get_SSID();
    }
    
    Connect_WiFi = (ssid) => {
        return Smartlink.Connect_WiFi(ssid);
    }

    Connect_WiFi_Secure = (ssid, pwd, bindNetwork, isWEP) => {
        return Smartlink.Connect_WiFi_Secure(ssid, pwd, bindNetwork, isWEP);
    }

    Remove_SSID = (ssid) => {
        return Smartlink.Remove_SSID(ssid);
    }

    AP_ConfigWiFi = (ssid, pwd) => {
        return Smartlink.AP_ConfigWiFi(ssid, pwd);
    }
}

// export default Smartlink;
export default new Index();
