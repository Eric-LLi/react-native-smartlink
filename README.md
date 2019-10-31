# react-native-smartlink

## Getting started

`$ npm install react-native-smartlink --save`

### Mostly automatic installation

`$ react-native link react-native-smartlink`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-smartlink` and add `Smartlink.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libSmartlink.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainApplication.java`
  - Add `import com.smartlink.SmartlinkPackage;` to the imports at the top of the file
  - Add `new SmartlinkPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-smartlink'
  	project(':react-native-smartlink').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-smartlink/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-smartlink')
  	```


## Usage
```javascript
import Smartlink from 'react-native-smartlink';

// TODO: What to do with the module?
Smartlink;
```
