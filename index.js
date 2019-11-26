/**
 * @providesModule react-native-icloudstore
 */

import { AsyncStorage, NativeModules, Platform } from 'react-native';

const iCloudStorage = Platform.OS === 'ios' || Platform.isTVOS ? NativeModules.RNICloudStorage : AsyncStorage;

export default iCloudStorage;

