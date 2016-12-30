/**
 * @providesModule react-native-icloudstore
 */

import { AsyncStorage, NativeModules, Platform } from 'react-native';

const iCloudStorage = Platform.OS === 'ios' ? NativeModules.RNICloudStorage : AsyncStorage;

export default iCloudStorage;

