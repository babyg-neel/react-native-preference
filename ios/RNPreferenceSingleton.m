//
//  RNPreferenceSingleton.m
//  RNPreferenceManager
//
//  Created by teason23 on 2020/12/30.
//  Copyright © 2020 shimo. All rights reserved.
//

#import "RNPreferenceSingleton.h"
#import "RNPreferenceManager.h"
#import <React/RCTConvert.h>

NSString *const kSHMPreferenceKey = @"RNPreferenceKey";
NSString *const kSHMPreferenceChangedNotification = @"SHMPreference_WhiteList_Notification";
NSString *const kSHMPreferenceClearNotification = @"SHMPreference_Clear_Notification";

@implementation RNPreferenceSingleton
static RNPreferenceSingleton *_instance = nil;
+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [RNPreferenceSingleton new];
        NSDictionary *dic = RCTJSONParse([RNPreferenceSingleton getAllPreferences], nil);
        _instance.singlePerference = dic ? [dic mutableCopy] : [@{} mutableCopy];
    });
    return _instance;
}

+ (NSString *)getAllPreferences {
    NSString *preferences = [[NSUserDefaults standardUserDefaults] stringForKey:kSHMPreferenceKey];
    return preferences ? preferences : @"{}";
}

- (NSString *)getPreferenceValueForKey:(NSString *)key {
    return self.singlePerference[key];
}

- (void)setPreferenceValue:(NSString *)value
                    forKey:(NSString *)key {
    NSMutableDictionary *dic = [self.singlePerference mutableCopy];
    [dic setObject:value forKey:key];
    
    [self setPreferenceData:RCTJSONStringify(dic, nil)];
    [self.singlePerference setObject:value forKey:key];
}

- (void)setPreferenceData:(NSString *)data {
    id obj = RCTJSONParse(data, nil);
    if (![obj isKindOfClass:[NSDictionary class]]) {
        NSLog(@"err: setPreferenceData - wrong data type!");
        return;
    }
    
    if (![RNPreferenceSingleton shareInstance].whiteList.count) NSLog(@"RNPreference - white list is nil !");
    
    // Diff
    NSDictionary *dicNew = obj;
    NSDictionary *dicOld = [RNPreferenceSingleton shareInstance].singlePerference;
    // 1. perfernce整体是否相等
    if (![dicNew isEqualToDictionary:dicOld]) {

        // 2. 取whitelist
        [self.whiteList enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *strNew = dicNew[key];
            NSString *strOld = dicOld[key];
            if (!strNew) return;
            
            if (![strNew isEqualToString:strOld]) {
                //3. data变化, 通知js
                NSDictionary *item = @{key: strNew};
                NSLog(@"RNPreference (key) %@ , Changed : %@",key,item);
                [[NSNotificationCenter defaultCenter] postNotificationName:kSHMPreferenceChangedNotification object:@{key: strNew}];
            }
        }];
    }
    
    // set Singleton , set UD
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:kSHMPreferenceKey];
}

- (void)clear {
    [[NSNotificationCenter defaultCenter] postNotificationName:kSHMPreferenceClearNotification object:nil];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHMPreferenceKey];
    self.singlePerference = [@{} mutableCopy];
}

@end
