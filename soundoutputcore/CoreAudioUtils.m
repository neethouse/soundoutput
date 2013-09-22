//
//  CoreAudioUtils.m
//  togglesound
//
//  Created by mtmta on 2013/09/13.
//  Copyright (c) 2013年 Neet House. All rights reserved.
//

#import "CoreAudioUtils.h"

static AudioObjectPropertyScope ScopeFromDirection(IODirection ioDir) {
    return (ioDir == kIODirectionInput) ? kAudioObjectPropertyScopeInput : kAudioObjectPropertyScopeOutput;
}

static AudioObjectPropertySelector DefaultDeviceSelectorFromDirection(IODirection ioDir) {
    return (ioDir == kIODirectionInput) ? kAudioHardwarePropertyDefaultInputDevice : kAudioHardwarePropertyDefaultOutputDevice;
}

@implementation CoreAudioUtils

#pragma mark - Device List

+ (NSArray *)getAllDevicesWithDirection:(IODirection)dir {
    NSMutableArray *devices = [NSMutableArray array];
    
    for (NSNumber *nsDevID in [self getAllDeviceIDsWithDirection:dir]) {
        AudioDeviceID devID = [nsDevID unsignedIntValue];
        NSDictionary *device = [self getDeviceWithID:devID direction:dir];
        [devices addObject:device];
    }
    
    return devices;
}

+ (NSArray *)getAllDeviceIDsWithDirection:(IODirection)dir {
    AudioObjectPropertyAddress address = {
        kAudioHardwarePropertyDevices,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster,
    };
    
    UInt32 devIDs[128];
    UInt32 size = sizeof(devIDs);
    
    AudioObjectGetPropertyData(kAudioObjectSystemObject, &address, 0, NULL, &size, &devIDs);
    
    int nDevices = size / sizeof(UInt32);
    NSMutableArray *nsDevIDs = [NSMutableArray array];
    for (int i = 0; i < nDevices; i++) {
        AudioDeviceID devID = devIDs[i];
        
        int nStreams = [self getNumberOfStreamsWithDeviceID:devID direction:dir];
        if (0 < nStreams) {
            [nsDevIDs addObject:@(devID)];
        }
    }
    
    return nsDevIDs;
}


#pragma mark - Device

+ (NSDictionary *)getDeviceWithID:(AudioDeviceID)devID direction:(IODirection)dir {
    NSMutableDictionary *device = [NSMutableDictionary dictionary];
    
    device[@"id"] = @(devID);
    
    NSString *name = [self getDeviceNameWithID:devID];
    if (name) {
        device[@"name"] = name;
    }
    
    NSArray *dss = [self getDataSourcesWithDeviceID:devID ioDirection:dir];
    if (dss) {
        device[@"dataSources"] = dss;
        device[@"dataSourceName"] = [[dss valueForKey:@"name"] componentsJoinedByString:@"/"];
    }

    return device;
};

+ (NSString *)getDeviceNameWithID:(UInt32)devID {
    AudioObjectPropertyAddress address = {
        kAudioObjectPropertyName,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster,
    };
    
    CFStringRef deviceName = NULL;
    UInt32 size = sizeof(deviceName);
    
    AudioObjectGetPropertyData(devID, &address, 0, NULL, &size, &deviceName);
    
    if (deviceName) {
        NSString *nsDeviceName = (__bridge NSString *)deviceName;
        CFRelease(deviceName), deviceName = NULL;
        
        return nsDeviceName;
    }
    return nil;
}


#pragma mark - Default Device

+ (NSDictionary *)getDefaultDeviceWithDirection:(IODirection)dir {
    AudioDeviceID devID = [self getDefaultDeviceIDWithDirection:dir];
    if (devID != 0) {
        return [self getDeviceWithID:devID direction:dir];
    }
    return nil;
}

+ (AudioDeviceID)getDefaultDeviceIDWithDirection:(IODirection)dir {
    AudioObjectPropertyAddress address = {
        DefaultDeviceSelectorFromDirection(dir),
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };
    
    AudioDeviceID devID = 0;
    UInt32 size = sizeof(devID);
    
    AudioObjectGetPropertyData(kAudioObjectSystemObject, &address, 0, NULL, &size, &devID);
    
    return devID;
}

+ (BOOL)setDefaultDeviceWithID:(AudioDeviceID)devID direction:(IODirection)dir {
    AudioObjectPropertyAddress address = {
        DefaultDeviceSelectorFromDirection(dir),
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster,
    };
    
    UInt32 size = sizeof(devID);
    
    OSStatus result = AudioObjectSetPropertyData(kAudioObjectSystemObject, &address, 0, NULL, size, &devID);
    return (result == noErr);
}


#pragma mark - Data Source

+ (NSArray *)getDataSourcesWithDeviceID:(UInt32)devID ioDirection:(IODirection)dir {
    NSMutableArray *dss = [NSMutableArray array];
    
    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyDataSources,
        ScopeFromDirection(dir),
        kAudioObjectPropertyElementMaster,
    };
    
    UInt32 dsIDs[128];
    UInt32 size = sizeof(dsIDs);
    
    AudioObjectGetPropertyData(devID, &address, 0, NULL, &size, dsIDs);
    
    int nSources = size / sizeof(UInt32);
    for (int i = 0; i < nSources; i++) {
        UInt32 dsID = dsIDs[i];
        
        NSMutableDictionary *ds = [NSMutableDictionary dictionary];
        ds[@"id"] = @(dsID);

        AudioObjectPropertyAddress address = {
            kAudioDevicePropertyDataSourceNameForIDCFString,
            ScopeFromDirection(dir),
            kAudioObjectPropertyElementMaster,
        };
        
        CFStringRef dsName = NULL;
        AudioValueTranslation translation = { &dsID, sizeof(UInt32), &dsName, sizeof(CFStringRef) };
        UInt32 size = sizeof(translation);
        
        AudioObjectGetPropertyData(devID, &address, 0, NULL, &size, &translation);

        if (dsName) {
            ds[@"name"] = (__bridge NSString *)dsName;
            CFRelease(dsName), dsName = NULL;
        }
        
        [dss addObject:ds];
    }
    
    return dss;
}


#pragma mark - Stream

+ (int)getNumberOfStreamsWithDeviceID:(UInt32)devID direction:(IODirection)dir {
    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyStreams,
        ScopeFromDirection(dir),
        kAudioObjectPropertyElementMaster,
    };
    
    UInt32 size = 0;
    
    AudioObjectGetPropertyDataSize(devID, &address, 0, NULL, &size);
    
    return (size / sizeof(UInt32));
}

@end
