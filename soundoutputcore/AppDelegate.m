//
//  AppDelegate.m
//  soundoutput
//
//  Created by mtmta on 2013/09/20.
//  Copyright (c) 2013年 Neet House. All rights reserved.
//

#import "AppDelegate.h"
#import "soundoutput.h"
#import "CoreAudioUtils.h"

#pragma mark Utils

static int fprintNSString(FILE *fp, NSString *format, ...) {
    va_list ap;
    va_start(ap, format);
    
    NSString *str = [[NSString alloc] initWithFormat:format arguments:ap];
    int result = fprintf(fp, "%s", [str cStringUsingEncoding:NSUTF8StringEncoding]);
    
    va_end(ap);
    
    return result;
}

static int printNSString(NSString *format, ...) {
    va_list ap;
    va_start(ap, format);
    
    NSString *str = [[NSString alloc] initWithFormat:format arguments:ap];
    int result = printf("%s", [str cStringUsingEncoding:NSUTF8StringEncoding]);
    
    va_end(ap);
    
    return result;
}

static NSArray *sortByID(NSArray *dicts) {
    //return dicts;
    return [dicts sortedArrayUsingDescriptors:
            @[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ]];
}

static NSString *normalizeName(NSString *name) {
    return (0 < name.length) ? name : @"-";
}


#pragma mark -

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSArray *args = [NSProcessInfo processInfo].arguments;

    int result = [self main:args];
    
    exit(result);
}

- (int)main:(NSArray *)args {
    if (2 <= args.count && ([args[1] isEqualToString:@"-l"] || [args[1] isEqualToString:@"--list"])) {
        return [self showOutputDevicesList];
        
    } else if (2 <= args.count && ([args[1] isEqualToString:@"-h"] || [args[1] isEqualToString:@"--help"])) {
        return [self showHelp];
        
    } else if (2 <= args.count && ([args[1] isEqualToString:@"-v"] || [args[1] isEqualToString:@"--version"])) {
        return [self showVersion];
        
    } else if (2 <= args.count && 0 < [args[1] intValue]) {
        return [self setDefaultOutputDevice:[args[1] intValue]];
        
    } else {
        return [self showDefaultOutputDevice];
    }
    
    return [self showHelp];
}


/**
 * 現在の出力デバイスを表示する.
 */
- (int)showDefaultOutputDevice {
    NSDictionary *device = [CoreAudioUtils getDefaultDeviceWithDirection:kIODirectionOutput];
    
    if (device) {
        printNSString(@"%@\t%@\n",
                      normalizeName(device[@"dataSourceName"]),
                      normalizeName(device[@"name"]));
        
    } else {
        return 1;
    }
    
    return 0;
}

/**
 * 出力デバイス一覧を表示する.
 */
- (int)showOutputDevicesList {
    NSArray *devices = sortByID([CoreAudioUtils getAllDevicesWithDirection:kIODirectionOutput]);
    int devIndex = 1;
    
    AudioDeviceID currentDevID = [CoreAudioUtils getDefaultDeviceIDWithDirection:kIODirectionOutput];
    
    for (NSDictionary *device in devices) {
        AudioObjectID devID = [device[@"id"] unsignedIntValue];
        
        if (devID == currentDevID) {
            printNSString(@"\x1b[7;0;1m");
        }
        
        printNSString(@"%d\t%@\t%@",
                      devIndex,
                      normalizeName(device[@"dataSourceName"]),
                      normalizeName(device[@"name"]));
        
        if (devID == currentDevID) {
            printNSString(@"\t*\x1b[m");
        }
        
        printNSString(@"\n");
        
        devIndex++;
    }
    
    return 0;
}

/**
 * ヘルプを表示する.
 */
- (int)showHelp {
    printNSString(@"usage: %1$@\n"
                  @"       Display current sound output device\n"
                  @"\n"
                  @"   or: %1$@ <device-index>\n"
                  @"       Set sound output device\n"
                  @"\n"
                  @"   or: %1$@ [-l|--list] [-h|--help] [-v|--version]\n"
                  @"\n"
                  @"Options\n"
                  @"    -l, --list\tList all sound output devices\n"
                  @"    -h, --help\tDisplay this help\n"
                  @"\n"
                  @"Documentation can be found at https://github.com/neethouse/soundoutput#readme\n",
                  CMD_NAME);
    return 0;
}

/**
 * バージョンを表示する.
 */
- (int)showVersion {
    printNSString(@"%1$@ version %2$@ (c) 2013 neethouse.org\n", CMD_NAME, SOUNDOUTPUT_VERSION);
    return 0;
}

/**
 * 出力デバイスを設定する.
 */
- (int)setDefaultOutputDevice:(int)targetDevIndex {
    NSArray *devices = sortByID([CoreAudioUtils getAllDevicesWithDirection:kIODirectionOutput]);
    
    if (targetDevIndex <= 0) {
        fprintNSString(stderr, @"invalid device index\n");
        return -1;
    }
    
    int devIndex = 1;
    
    for (NSDictionary *device in devices) {
        if (0 < targetDevIndex && devIndex == targetDevIndex) {
            AudioObjectID devID = [device[@"id"] unsignedIntValue];
            
            if ([CoreAudioUtils setDefaultDeviceWithID:devID direction:kIODirectionOutput]) {
                return 0;
            }
            fprintNSString(stderr, @"failed\n");
            return 1;
        }
        
        devIndex++;
    }
    
    fprintNSString(stderr, @"no such device\n");
    return -1;
}

@end
