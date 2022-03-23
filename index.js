/**
 * @providesModule react-native-icloudstore
 */

import { NativeModules, Platform } from 'react-native';
import AsyncStorage from "@react-native-async-storage/async-storage";

const iCloudStorage = Platform.OS === 'ios' || Platform.isTVOS ? NativeModules.RNICloudStorage : AsyncStorage;

export default iCloudStorage;

