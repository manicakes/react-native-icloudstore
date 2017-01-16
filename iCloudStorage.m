//
//  iCloudStorage.m
//  iCloudStorage
//
//  Created by Mani Ghasemlou on 12/18/16.
//  Copyright © 2016 Mani Ghasemlou. All rights reserved.
//

#import "iCloudStorage.h"
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>

static NSString* const ICLOUDSTORAGE_PREFIX = @"@com.manicakes.iCloudStorage/";
static NSString* const ICLOUD_STORE_CHANGED = @"ICLOUD_STORE_CHANGED";
static NSString* const kStoreChangedEvent = @"iCloudStoreDidChangeRemotely";
static NSString* const kChangedKeys = @"changedKeys";

@implementation iCloudStorage

+ (NSString*)appendPrefixToKey:(NSString*)key {
  return [NSString stringWithFormat:@"%@%@", ICLOUDSTORAGE_PREFIX, key];
}

+ (NSString*)removePrefixFromKey:(NSString*)key {
  if (![key hasPrefix:ICLOUDSTORAGE_PREFIX]) {
    return nil;
  }
  return [key substringFromIndex:[ICLOUDSTORAGE_PREFIX length]];
}

+ (NSDictionary*)storeDictionary {
  NSUbiquitousKeyValueStore* store = [NSUbiquitousKeyValueStore defaultStore];
  return [store dictionaryRepresentation];
}

+ (NSArray*)allKeysInStore {
  return [[iCloudStorage storeDictionary] allKeys];
}

+ (id) getObjectForKey:(NSString*)key {
  return [[NSUbiquitousKeyValueStore defaultStore] objectForKey:[iCloudStorage appendPrefixToKey:key]];
}

+ (void) setValue:(NSString*)value forKey:(NSString*)key {
  [[NSUbiquitousKeyValueStore defaultStore] setObject:value forKey:[iCloudStorage appendPrefixToKey:key]];
  [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

+ (void) removeKey:(NSString*)key {
  [[NSUbiquitousKeyValueStore defaultStore] removeObjectForKey:[iCloudStorage appendPrefixToKey:key]];
  [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

+ (NSString*) getMergedItemWithKey:(NSString*)key value:(NSString*)value rejecter:(RCTPromiseRejectBlock)reject {
  NSDictionary* storedItem = @{};
  NSDictionary* newItem = @{};
  NSString* storedString = [iCloudStorage getObjectForKey:key];
  
  if (storedString != nil) {
    NSError* error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:[storedString dataUsingEncoding:NSUTF8StringEncoding]
                                                options:0
                                                  error:&error];
    if (error != nil) {
      reject(@"json_decode_err", @"Error parsing stored value as JSON string.", error);
      return nil;
    }
    
    if (![object isKindOfClass:[NSDictionary class]]) {
      reject(@"json_not_object_err", @"The stored JSON string does not parse into an object.", nil);
      return nil;
    }
    
    if (value != nil) {
      id newObject = [NSJSONSerialization JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding]
                                                     options:0
                                                       error:&error];
      if (error != nil) {
        reject(@"json_decode_err", @"The provided value is not valid JSON.", error);
        return nil;
      }
      
      if (![newItem isKindOfClass:[NSDictionary class]]) {
        reject(@"json_not_object_err", @"The provided JSON string does not parse into an object.", nil);
        return nil;
      }
      
      newItem = newObject;
    }
    
    storedItem = object;
  }
  
  NSMutableDictionary* mergedItem = [NSMutableDictionary dictionaryWithDictionary:storedItem];
  [mergedItem addEntriesFromDictionary:newItem];
  
  NSError* error = nil;
  NSData* data = [NSJSONSerialization dataWithJSONObject:mergedItem options:0 error:&error];
  if (error != nil) {
    reject(@"json_encode_err", @"Error encoding the merged JSON data to string.", error);
    return nil;
  }
  
  return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (instancetype)init {
  self = [super init];
  
  if (self) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ubiquitousStoreUpdated:)
                                                 name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                               object:nil];
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
  }
  
  return self;
}

- (NSArray<NSString *> *)supportedEvents {
  return @[ kStoreChangedEvent ];
}

- (void) ubiquitousStoreUpdated:(NSNotification*)notification {
  // if this notification comes in before bridge has initialized,
  // don't try to send the event (app crashes if you do).
  if (!self.bridge) {
    return;
  }
  
  NSArray* changedKeys = [[notification userInfo] objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
  NSMutableArray* reportedChangedKeys = [NSMutableArray array];
  for (NSString* key in changedKeys) {
    NSString* reportedKey = [iCloudStorage removePrefixFromKey:key];
    if (reportedKey) {
      [reportedChangedKeys addObject:reportedKey];
    }
  }
  
  if ([reportedChangedKeys count]) {
    NSDictionary* body = @{ kChangedKeys : reportedChangedKeys };
    [self sendEventWithName:kStoreChangedEvent body:body];
  }
}

RCT_EXPORT_MODULE(RNICloudStorage)


RCT_EXPORT_METHOD(getItem: (NSString*)key resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  resolve([iCloudStorage getObjectForKey:key]);
}

RCT_EXPORT_METHOD(setItem: (NSString*)key value: (NSString*)value resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  [iCloudStorage setValue:value forKey:key];
  resolve(@{});
}

RCT_EXPORT_METHOD(removeItem: (NSString*)key resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  [iCloudStorage removeKey:key];
  resolve(@{});
}

RCT_EXPORT_METHOD(mergeItem: (NSString*)key value: (NSString*)value resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  NSString* newValue = [iCloudStorage getMergedItemWithKey:key value:value rejecter:reject];
  if (newValue == nil) {
    // we failed and reject block was called.
    return;
  }
  
  [iCloudStorage setValue:newValue forKey:key];
  
  resolve(@{});
}

RCT_REMAP_METHOD(clear, clearResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
  for (NSString* key in [iCloudStorage allKeysInStore]) {
    if ([key hasPrefix:ICLOUDSTORAGE_PREFIX]) {
      [[NSUbiquitousKeyValueStore defaultStore] removeObjectForKey:key];
    }
  }
  
  resolve(@{});
}

RCT_REMAP_METHOD(getAllKeys, getAllKeysResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
  NSMutableArray* allKeys = [NSMutableArray array];
  
  for (NSString* storeKey in [iCloudStorage allKeysInStore]) {
    NSString* key = [iCloudStorage removePrefixFromKey:storeKey];
    if (key != nil) {
      [allKeys addObject:key];
    }
  }
  
  resolve(allKeys);
}

RCT_EXPORT_METHOD(multiGet: (NSArray*)keys resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  NSMutableArray *result = [NSMutableArray arrayWithCapacity:[keys count]];
  for (NSString* key in keys) {
    NSObject* object = [iCloudStorage getObjectForKey:key];
    if (object != nil) {
      [result addObject:object];
    }
  }
  
  resolve(result);
}

RCT_EXPORT_METHOD(multiSet: (NSDictionary*)keyValuePairs resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  for (NSString* key in [keyValuePairs allKeys]) {
    [iCloudStorage setValue:[keyValuePairs objectForKey:key] forKey:key];
  }
  resolve(@{});
}

RCT_EXPORT_METHOD(multiRemove: (NSArray*)keys resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  for (NSString* key in keys) {
    [iCloudStorage removeKey:key];
  }
  
  resolve(@{});
}

RCT_EXPORT_METHOD(multiMerge: (NSDictionary*)keyValuePairs resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  NSMutableDictionary* result = [NSMutableDictionary dictionaryWithCapacity:[keyValuePairs count]];
  BOOL failed = NO;
  for (NSString* key in [keyValuePairs allKeys]) {
    NSString* newValue = [iCloudStorage getMergedItemWithKey:key value:[keyValuePairs objectForKey:key] rejecter:reject];
    if (newValue == nil) {
      break;
    }
  }

  if (failed) {
    return;
  }

  for (NSString* key in [result allKeys]) {
    [iCloudStorage setValue:[result objectForKey:key] forKey:key];
  }
  
  resolve(@{});
}

- (NSDictionary<NSString *,id> *)constantsToExport {
  return @{ ICLOUD_STORE_CHANGED : kStoreChangedEvent };
}

@end
