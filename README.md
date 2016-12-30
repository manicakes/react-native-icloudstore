# react-native-icloudstore 📱☁️📱

[![npm version](https://badge.fury.io/js/react-native-icloudstore.svg)](http://badge.fury.io/js/react-native-icloudstore)

A drop in replacement for [React Native](https://github.com/facebook/react-native)'s [AsyncStorage](https://facebook.github.io/react-native/docs/asyncstorage.html) API that wraps the [iCloud Ubiquitous Key-Value Store](https://developer.apple.com/library/content/documentation/General/Conceptual/iCloudDesignGuide/Chapters/DesigningForKey-ValueDataIniCloud.html).

## Usage

For this to work, you must enable iCloud is switched on as well as make sure that the `Key-value storage` option is checked. These are found under your target's Capabilities tab in Xcode.

API is the same as [AsyncStorage](https://facebook.github.io/react-native/docs/asyncstorage.html). There is one additional feature: a native event (`iCloudStoreDidChangeRemotely`) that lets you know when your store changes due to a remote change (i.e. from another device on the same iCloud account). See the example below for how to make use of that in your React Native component.

```javascript
import iCloudStorage from 'react-native-icloudstore';

...

  componentWillMount() {
    this.eventEmitter = new NativeEventEmitter(iCloudStorage);
    this.eventEmitter.addListener('iCloudStoreDidChangeRemotely', this.loadData);
  }

  componentWillUnmount() {
    this.eventEmitter.remove();
  }

  loadData = () => {
    iCloudStorage.getItem(MY_STORAGE_KEY).then(result => this.setState({ storage: result }));
  }
```

## Install

```shell
npm install --save react-native-icloudstore
```

## Automatically link

#### With React Native 0.27+

```shell
react-native link react-native-icloudstore
```

#### With older versions of React Native

You need [`rnpm`](https://github.com/rnpm/rnpm) (`npm install -g rnpm`)

```shell
rnpm link react-native-icloudstore
```

## Manually link

### iOS (via Cocoa Pods)
Add the following line to your build targets in your `Podfile`

`pod 'RNICloudStore', :path => '../node_modules/react-native-icloudstore'`

Then run `pod install`

### iOS (without Cocoa Pods)

In XCode, in the project navigator:
- Right click _Libraries_
- Add Files to _[your project's name]_
- Go to `node_modules/react-native-icloudstore`
- Add the `.xcodeproj` file

In XCode, in the project navigator, select your project.
- Add the `libicloudstorage.a` from the _deviceinfo_ project to your project's _Build Phases ➜ Link Binary With Libraries_
- Click `.xcodeproj` file you added before in the project navigator and go the _Build Settings_ tab. Make sure _All_ is toggled on (instead of _Basic_).
- Look for _Header Search Paths_ and make sure it contains both `$(SRCROOT)/../react-native/React` and `$(SRCROOT)/../../React`
- Mark both as recursive (should be OK by default).

Run your project (Cmd+R)

### Android

Android isn't supported - importing will simply return `AsyncStorage` so your app should continue to work.

