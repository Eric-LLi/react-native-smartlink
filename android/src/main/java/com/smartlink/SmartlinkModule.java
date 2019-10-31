package com.smartlink;

import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;

import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkInfo;
import android.net.NetworkRequest;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.net.wifi.WifiConfiguration;

import com.hiflying.smartlink.OnSmartLinkListener;
import com.hiflying.smartlink.SmartLinkedModule;
import com.hiflying.smartlink.v3.SnifferSmartLinker;
import com.hiflying.smartlink.v7.MulticastSmartLinker;

public class SmartlinkModule extends ReactContextBaseJavaModule implements LifecycleEventListener {

	private final ReactApplicationContext reactContext;
	private WifiManager wifiManager;
	private ConnectivityManager connectivityManager;

	public SmartlinkModule(ReactApplicationContext reactContext) {
		super(reactContext);
		this.reactContext = reactContext;
	}

	@Override
	public String getName() {
		return "Smartlink";
	}

	@Override
	public void onHostResume() {

	}

	@Override
	public void onHostPause() {

	}

	@Override
	public void onHostDestroy() {

	}

	@ReactMethod
	public void SL_Connect(String ssid, String pwd) {
		//
	}

	@ReactMethod
	public void AP_Connect(String ssid, String pwd, Boolean apssid, Boolean appwd) {
		//
	}

	@ReactMethod
	public void SL_StopConnect() {
		//
	}

	@ReactMethod
	public void isAvailableConnectWiFi(Promise promise) {
		promise.resolve(true);
	}

	@ReactMethod
	public void Connect_WiFi(String ssid) {
		//
	}

	@ReactMethod
	public void Get_SSID(Promise promise) {
		WifiInfo info = wifiManager.getConnectionInfo();
		String ssid = info.getSSID();

		if (ssid == null || ssid.equalsIgnoreCase("<unknown ssid>")) {
			NetworkInfo nInfo = connectivityManager.getActiveNetworkInfo();
			if (nInfo != null && nInfo.isConnected()) {
				ssid = nInfo.getExtraInfo();
			}
		}

		if (ssid != null && ssid.startsWith("\"") && ssid.endsWith("\"")) {
			ssid = ssid.substring(1, ssid.length() - 1);
		}
		promise.resolve(ssid);
	}

	@ReactMethod
	public void Connect_WiFi_Secure(String ssid, String pwd, Boolean bindNetwork, Boolean isWEP) {
		//
	}
}
