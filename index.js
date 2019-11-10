import { NativeModules } from 'react-native';

const { Smartlink } = NativeModules;

//SL_Connect(ssid, pwd)

//AP_Connect(ssid ,pwd ,apssid, appwd)

//SL_StopConnect()

//AP_StopConnect()

//isAvailableConnectWiFi()

//Get_SSID()

//Connect_WiFi(ssid)

//Connect_WiFi_Secure(ssid, pwd, bindNetwork, isWEP)

//Remove_SSID(ssid)

export default Smartlink;
