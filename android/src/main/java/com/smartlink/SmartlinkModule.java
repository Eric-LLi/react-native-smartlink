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
import android.net.NetworkInfo;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.net.wifi.WifiConfiguration;

import com.hiflying.smartlink.ISmartLinker;
import com.hiflying.smartlink.OnSmartLinkListener;
import com.hiflying.smartlink.SmartLinkedModule;
import com.hiflying.smartlink.v7.MulticastSmartLinker;

import android.content.Context;
import android.os.Build;
import android.util.Log;

class FailureCodes {
	static int SYSTEM_ADDED_CONFIG_EXISTS = 1;
	static int FAILED_TO_CONNECT = 2;
	static int FAILED_TO_ADD_CONFIG = 3;
	static int FAILED_TO_BIND_CONFIG = 4;
}

class EventName {
	static String SL_CONNECT = "SL_Connect";
	static String AP_CONNECT = "AP_Connect";
}

public class SmartlinkModule extends ReactContextBaseJavaModule implements LifecycleEventListener {

	private final ReactApplicationContext reactContext;
	private WifiManager wifiManager;
	private ConnectivityManager connectivityManager;
	private static ISmartLinker mSmartLinker;
	private static boolean slIsConnecting = false;
	private static boolean apIsConnecting = false;
	private static OnSmartLinkListener slListener;
	private static Promise mPromise;
	private static String currentSSID;
	private static String currentPwd;

	public SmartlinkModule(ReactApplicationContext reactContext) {
		super(reactContext);
		this.reactContext = reactContext;
		wifiManager = (WifiManager) getReactApplicationContext().getApplicationContext()
				.getSystemService(Context.WIFI_SERVICE);
		connectivityManager = (ConnectivityManager) getReactApplicationContext().getApplicationContext()
				.getSystemService(Context.CONNECTIVITY_SERVICE);
		slListener = new OnSmartLinkListener() {
			@Override
			public void onLinked(SmartLinkedModule smartLinkedModule) {
				Log.e("Connected", "Connected");
				WritableMap params = Arguments.createMap();
				params.putBoolean("connected", true);
				params.putString("id", smartLinkedModule.getId());
				params.putString("mac", smartLinkedModule.getMac());
				params.putString("ip", smartLinkedModule.getIp());
				sendEvent(EventName.SL_CONNECT, params);
				mPromise.resolve(true);
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
		switch (errorCode) {
			case 1: {
				return "SYSTEM_ADDED_CONFIG_EXISTS";
			}
			case 2: {
				return "FAILED_TO_CONNECT";
			}
			case 3: {
				return "FAILED_TO_ADD_CONFIG";
			}
			case 4: {
				return "FAILED_TO_BIND_CONFIG";
			}
			default: {
				return "unknown error";
			}
		}
	}

	private void stopSLConnect() {
		if (mSmartLinker != null) {
			mSmartLinker.setOnSmartLinkListener(null);
			mSmartLinker.stop();
			slIsConnecting = false;
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

	private WifiConfiguration createWifiConfiguration(String ssid, String passphrase) {
		WifiConfiguration configuration = new WifiConfiguration();
		configuration.SSID = String.format("\"%s\"", ssid);

		if (passphrase.equals("")) {
			configuration.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.NONE);
		} else { // WPA/WPA2
			configuration.preSharedKey = "\"" + passphrase + "\"";
		}

		if (!wifiManager.isWifiEnabled()) {
			wifiManager.setWifiEnabled(true);
		}
		return configuration;
	}

	private void connect_wifi_secure(String ssid, String passphrase) throws Exception {

		WifiConfiguration configuration = createWifiConfiguration(ssid, passphrase);
		int networkId = wifiManager.addNetwork(configuration);

		if (networkId != -1) {
			// Enable it so that android can connect
			wifiManager.disconnect();
			boolean success = wifiManager.enableNetwork(networkId, true);
			if (!success) {
				throw new Exception(errorFromCode(FailureCodes.FAILED_TO_ADD_CONFIG));
			}
			success = wifiManager.reconnect();
			if (!success) {
				throw new Exception(errorFromCode(FailureCodes.FAILED_TO_CONNECT));
			}
			boolean connected = pollForValidSSSID(10, ssid);
			if (!connected) {
				throw new Exception(errorFromCode(FailureCodes.FAILED_TO_CONNECT));
			}
		} else {
			throw new Exception(errorFromCode(FailureCodes.FAILED_TO_ADD_CONFIG));
		}
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
		if (slIsConnecting) {
			stopSLConnect();
		}
	}

	@ReactMethod
	public void SL_Connect(String ssid, String pwd, Promise promise) {
		if (mSmartLinker != null) {
			stopSLConnect();
		}
		if (!slIsConnecting) {
			try {
				mPromise = promise;
				mSmartLinker = MulticastSmartLinker.getInstance();
				slIsConnecting = true;
				mSmartLinker.setOnSmartLinkListener(slListener);
				mSmartLinker.start(this.reactContext, ssid.trim(), pwd.trim());
			} catch (Exception err) {
				slIsConnecting = false;
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
		promise.resolve(true);
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
	public void Connect_WiFi(final String ssid, final Promise promise) {
		if (Build.VERSION.SDK_INT > 28) {
			promise.reject(null, "Not supported on Android Q");
		} else {
			new Thread(new Runnable() {
				@Override
				public void run() {
					try {
						connect_wifi_secure(ssid, "");
						promise.resolve(true);
					} catch (Exception err) {
						promise.reject(null, err.getMessage());
					}
				}
			}).start();
		}
	}

	@ReactMethod
	public void Connect_WiFi_Secure(final String ssid, final String passphrase, final Promise promise) {
		if (Build.VERSION.SDK_INT > 28) {
			promise.reject(null, "Not supported on Android Q");
		} else {
			new Thread(new Runnable() {
				@Override
				public void run() {
					try {
						connect_wifi_secure(ssid, passphrase);
						promise.resolve(true);
					} catch (Exception err) {
						promise.reject(null, err.getMessage());
					}
				}
			}).start();
		}

	}
}
