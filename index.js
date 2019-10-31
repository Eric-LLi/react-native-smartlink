import { NativeModules } from 'react-native';

const { Smartlink } = NativeModules;

// SL_Connect(ssid, pwd)

//AP_Connect(ssid ,pwd ,apssid, appwd)

//SL_StopConnect()

//isAvailableConnectWiFi()

//Connect_WiFi(ssid)

//Get_SSID()

//Connect_WiFi_Secure(ssid, pwd, bindNetwork, isWEP)

export default Smartlink;
