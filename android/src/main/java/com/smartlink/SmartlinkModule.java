package com.smartlink;

import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.Arguments;

import androidx.annotation.Nullable;

import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkInfo;
import android.net.NetworkRequest;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.net.wifi.WifiConfiguration;

import com.hiflying.smartlink.ISmartLinker;
import com.hiflying.smartlink.OnSmartLinkListener;
import com.hiflying.smartlink.SmartLinkedModule;
import com.hiflying.smartlink.v3.SnifferSmartLinker;
import com.hiflying.smartlink.v7.MulticastSmartLinker;

import android.content.Context;
import android.util.Log;

class FailureCodes {
	static int SYSTEM_ADDED_CONFIG_EXISTS = 1;
	static int FAILED_TO_CONNECT = 2;
	static int FAILED_TO_ADD_CONFIG = 3;
	static int FAILED_TO_BIND_CONFIG = 4;
}

class EventName {
	static String SL_CONNECT = "SL_Connect";
}

public class SmartlinkModule extends ReactContextBaseJavaModule implements LifecycleEventListener {

	private final ReactApplicationContext reactContext;
	private WifiManager wifiManager;
	private ConnectivityManager connectivityManager;
	private static ISmartLinker mSmartLinker;
	private boolean mIsConncting = false;
	private static OnSmartLinkListener listener;
	private Promise mPromise;

	public SmartlinkModule(ReactApplicationContext reactContext) {
		super(reactContext);
		this.reactContext = reactContext;
		wifiManager = (WifiManager) getReactApplicationContext().getApplicationContext()
				.getSystemService(Context.WIFI_SERVICE);
		connectivityManager = (ConnectivityManager) getReactApplicationContext().getApplicationContext()
				.getSystemService(Context.CONNECTIVITY_SERVICE);
		listener = new OnSmartLinkListener() {
			@Override
			public void onLinked(SmartLinkedModule smartLinkedModule) {
				Log.e("Connected", "Connected");
				WritableMap params = Arguments.createMap();
				params.putBoolean("connected", true);
				params.putString("id", smartLinkedModule.getId());
				params.putString("mac", smartLinkedModule.getMac());
				params.putString("ip", smartLinkedModule.getIp());
				sendEvent(EventName.SL_CONNECT, params);
				mPromise.resolve("");
			}

			@Override
			public void onCompleted() {
				Log.e("onCompleted", "onCompleted");
			}

			@Override
			public void onTimeOut() {
				Log.e("onTimeOut", "onTimeOut");
				WritableMap params = Arguments.createMap();
				params.putBoolean("connected", false);
				sendEvent(EventName.SL_CONNECT, params);
				mPromise.reject(EventName.SL_CONNECT, "timeout");
			}
		};
	}

	private void sendEvent(String eventName, @Nullable WritableMap params) {
		this.reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(eventName, params);
	}

	private String errorFromCode(int errorCode) {
		return "ErrorCode: " + errorCode;
	}

	private void stopSLConnect() {
		if (mSmartLinker != null) {
			mSmartLinker.setOnSmartLinkListener(null);
			mSmartLinker.stop();
			mIsConncting = false;
		}
	}

	private boolean pollForValidSSSID(int maxSeconds, String expectedSSID) {
		try {
			for (int i = 0; i < maxSeconds; i++) {
				String ssid = this.getWifiSSID();
				if (ssid != null && ssid.equalsIgnoreCase(expectedSSID)) {
					return true;
				}
				Thread.sleep(1000);
			}
		} catch (InterruptedException e) {
			return false;
		}
		return false;
	}

	private String getWifiSSID() {
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

		return ssid;
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
		//
	}

	@Override
	public void onHostDestroy() {
		if (mIsConncting) {
			stopSLConnect();
		}
	}

	@ReactMethod
	public void SL_Connect(String ssid, String pwd, Promise promise) {
		if (mSmartLinker != null) {
			stopSLConnect();
		}
		if (!mIsConncting) {
			try {
				mPromise = promise;
				mSmartLinker = MulticastSmartLinker.getInstance();
				mIsConncting = true;
				mSmartLinker.setOnSmartLinkListener(listener);
				mSmartLinker.start(this.reactContext, ssid.trim(), pwd.trim());
			} catch (Exception err) {
				mIsConncting = false;
				promise.reject(err);
			}
		}
	}

	@ReactMethod
	public void AP_Connect(String ssid, String pwd, Boolean apssid, Boolean appwd) {
		//
	}

	@ReactMethod
	public void SL_StopConnect(Promise promise) {
		if (mSmartLinker != null) {
			stopSLConnect();
		}
		promise.resolve("");
	}

	@ReactMethod
	public void isAvailableConnectWiFi(Promise promise) {
		promise.resolve(true);
	}

	@ReactMethod
	public void Get_SSID(Promise promise) {
		String ssid = this.getWifiSSID();

		promise.resolve(ssid);
	}

	@ReactMethod
	public void Connect_WiFi_Secure(String ssid, String pwd, Boolean isWEP, Promise promise) {
		WifiConfiguration configuration = new WifiConfiguration();
		configuration.SSID = String.format("\"%s\"", ssid);

		if (pwd.equals("")) {
			configuration.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.NONE);
		} else if (isWEP) {
			configuration.wepKeys[0] = "\"" + pwd + "\"";
			configuration.wepTxKeyIndex = 0;
			configuration.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.NONE);
			configuration.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.WEP40);
		} else { // WPA/WPA2
			configuration.preSharedKey = "\"" + pwd + "\"";
		}

		if (!wifiManager.isWifiEnabled()) {
			wifiManager.setWifiEnabled(true);
		}

		int networkId = wifiManager.addNetwork(configuration);

		if (networkId != -1) {
			wifiManager.disconnect();
			boolean success = wifiManager.enableNetwork(networkId, true);
			if (!success) {
				promise.reject(errorFromCode(FailureCodes.FAILED_TO_ADD_CONFIG), "Failed to add " +
						"config");
				return;
			}
			success = wifiManager.reconnect();
			if (!success) {
				promise.reject(errorFromCode(FailureCodes.FAILED_TO_CONNECT), "Failed to connect " +
						"WiFi");
				return;
			}
			boolean connected = pollForValidSSSID(10, ssid);
			if (!connected) {
				promise.reject(errorFromCode(FailureCodes.FAILED_TO_CONNECT), "Failed to connect " +
						"WiFi");
				return;
			}
		}
	}
}
