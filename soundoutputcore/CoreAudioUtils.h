//
//  CoreAudioUtils.h
//  togglesound
//
//  Created by mtmta on 2013/09/13.
//  Copyright (c) 2013年 Neet House. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudio.h>

typedef NS_ENUM(int, IODirection) {
    kIODirectionInput,
    kIODirectionOutput,
};

@interface CoreAudioUtils : NSObject

#pragma mark - Device List

+ (NSArray *)getAllDevicesWithDirection:(IODirection)dir;

+ (NSArray *)getAllDeviceIDsWithDirection:(IODirection)dir;

#pragma mark - Device

+ (NSDictionary *)getDeviceWithID:(AudioDeviceID)devID direction:(IODirection)dir;

+ (NSString *)getDeviceNameWithID:(UInt32)devID;

#pragma mark - Default Device

+ (NSDictionary *)getDefaultDeviceWithDirection:(IODirection)dir;

+ (AudioDeviceID)getDefaultDeviceIDWithDirection:(IODirection)dir;

+ (BOOL)setDefaultDeviceWithID:(AudioDeviceID)devID direction:(IODirection)dir;

#pragma mark - Data Source

+ (NSArray *)getDataSourcesWithDeviceID:(UInt32)devID ioDirection:(IODirection)dir;

#pragma mark - Stream

+ (int)getNumberOfStreamsWithDeviceID:(UInt32)devID direction:(IODirection)dir;

@end
