#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <stdio.h>

#import "MediaRemote.h"
#import "AVSystemController.h"

// 1 / 16
#define kVolumeStep      0.0625
#define kAVMediaCategory @"Audio/Video"


void mediaRemoteCommand(MRCommand command) {
    MRMediaRemoteSendCommand(command, nil);
    [NSThread sleepForTimeInterval:0.01f];
}

void setVolume(float volume) {
    if (volume < 0) {
        volume = 0;
    } else if (volume > 1) {
        volume = 1;
    }

    [[AVSystemController sharedAVSystemController] setVolumeTo:volume forCategory:kAVMediaCategory];
}

void help(const char *path) {
    printf("\nUsage: %s action\n\n"
            "Available actions:\n"
            "Note: Not all apps support all actions!\n"
            " playpause, toggle   play if paused/pause if playing\n"
            " play                play\n"
            " pause               pause\n"
            " previous, prev      go back to previous track\n"
            " next                go forward to next track\n"
            " back15              rewind 15 seconds\n"
            " forward15, fwd15    forward 15 seconds\n"
            " voldown, vol-       lower volume by one step\n"
            " volup, vol+         increase volume by one step\n"
            " vol{step}           set volume to step 0 to 16\n"
            "\n"
            "Getting information:\n"
            " nowplaying, np      show now playing information\n"
            " artworkuri, awuri   get the artwork as a data URI\n"
            "Help:\n"
            " help, -h, --help    show this message\n\n"
            , path);
}

int volMatch(NSString *action) {
    NSUInteger length = [action length];
    if ((length == 4 || length == 5) && [action hasPrefix:@"vol"]) {
        NSString *stringNumber = [action substringFromIndex:3];

        NSNumberFormatter *formatter = [NSNumberFormatter new];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_GB"];
        formatter.allowsFloats = NO;
        formatter.minimum = @0;
        formatter.maximum = @16;

        NSNumber *number = [formatter numberFromString:stringNumber];

        if (number) {
            return [number intValue];
        } else {
            fprintf(stderr, "\nInvalid volume step: %s\n", [stringNumber UTF8String]);
            return -1;
        }
    } else {
        return -2;
    }
}

void nowPlayingInformation(MRMediaRemoteGetNowPlayingInfoCompletion completion) {
    __block CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef information) {
        if (information != NULL) {
            completion(information);

        } else {
            printf("\nNothing is playing right now :(\n\n");
        }
        CFRunLoopStop(runLoop);
    });
    CFRunLoopRun();
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        switch (argc) {
            case 2: {
                NSString *command = [NSString stringWithUTF8String:argv[1]];
                int volumeStep = -1;

                if ([@"playpause" isEqualToString:command] || [@"toggle" isEqualToString:command]) {
                    mediaRemoteCommand(kMRTogglePlayPause);
                }
                else if ([@"play" isEqualToString:command]) {
                    mediaRemoteCommand(kMRPlay);
                }
                else if ([@"pause" isEqualToString:command]) {
                    mediaRemoteCommand(kMRPause);
                }
                else if ([@"stop" isEqualToString:command]) {
                    mediaRemoteCommand(kMRPause);
                }
                else if ([@"previous" isEqualToString:command] || [@"prev" isEqualToString:command]) {
                    mediaRemoteCommand(kMRPreviousTrack);
                }
                else if ([@"next" isEqualToString:command]) {
                    mediaRemoteCommand(kMRNextTrack);
                }
                else if ([@"back15" isEqualToString:command]) {
                    mediaRemoteCommand(kMRGoBackFifteenSeconds);
                }
                else if ([@"forward15" isEqualToString:command] || [@"fwd15" isEqualToString:command]) {
                    mediaRemoteCommand(kMRSkipFifteenSeconds);
                }
                else if ([@"voldown" isEqualToString:command] || [@"vol-" isEqualToString:command]) {
                    float currentVolume;
                    [[AVSystemController sharedAVSystemController] getVolume:&currentVolume forCategory:kAVMediaCategory];

                    setVolume(currentVolume - kVolumeStep);
                }
                else if ([@"volup" isEqualToString:command] || [@"vol+" isEqualToString:command]) {
                    float currentVolume;
                    [[AVSystemController sharedAVSystemController] getVolume:&currentVolume forCategory:kAVMediaCategory];

                    setVolume(currentVolume + kVolumeStep);
                }
                // vol0 - vol16
                else if ((volumeStep = volMatch(command)) != -2) {
                    if (volumeStep == -1) {
                        help(argv[0]);
                    } else {
                        setVolume(volumeStep * kVolumeStep);
                    }
                }

                else if ([@"nowplaying" isEqualToString:command] || [@"np" isEqualToString:command]) {
                    nowPlayingInformation(^(CFDictionaryRef information) {
                        NSString *title = @"(unknown)";
                        NSString *artist = @"(unknown)";

                        if (CFDictionaryContainsKey(information, kMRMediaRemoteNowPlayingInfoTitle)) {
                            title = CFDictionaryGetValue(information, kMRMediaRemoteNowPlayingInfoTitle);
                        }
                        if (CFDictionaryContainsKey(information, kMRMediaRemoteNowPlayingInfoArtist)) {
                            artist = CFDictionaryGetValue(information, kMRMediaRemoteNowPlayingInfoArtist);
                        }

                        printf("\nTitle:  %s\nArtist: %s\n", [title UTF8String], [artist UTF8String]);

                        if (CFDictionaryContainsKey(information, kMRMediaRemoteNowPlayingInfoAlbum)) {
                            NSString *album = CFDictionaryGetValue(information, kMRMediaRemoteNowPlayingInfoAlbum);
                            printf("\nAlbum:  %s\n", [album UTF8String]);
                        }

                        if (CFDictionaryContainsKey(information, kMRMediaRemoteNowPlayingInfoGenre)) {
                            NSString *genre = CFDictionaryGetValue(information, kMRMediaRemoteNowPlayingInfoGenre);
                            printf("\nGenre:  %s\n", [genre UTF8String]);
                        }

                        printf("\n");
                    });

                }
                else if ([@"artworkuri" isEqualToString:command] || [@"awuri" isEqualToString:command]) {
                    nowPlayingInformation(^(CFDictionaryRef information) {
                        if (CFDictionaryContainsKey(information, kMRMediaRemoteNowPlayingInfoArtworkData)
                            && CFDictionaryContainsKey(information, kMRMediaRemoteNowPlayingInfoArtworkMIMEType)) {

                            NSString *mime = CFDictionaryGetValue(information, kMRMediaRemoteNowPlayingInfoArtworkMIMEType);
                            NSData *data = CFDictionaryGetValue(information, kMRMediaRemoteNowPlayingInfoArtworkData);

                            NSString *uri = [NSString stringWithFormat:@"data:%@;base64,%@", mime, [data base64EncodedStringWithOptions:0]];

                            printf("%s\n", [uri UTF8String]);
                        }
                        else {
                            printf("\nNo artwork available right now :(\n\n");
                        }
                    });
                }

                else if ([@"help" isEqualToString:command] || [@"-h" isEqualToString:command] || [@"--help" isEqualToString:command]) {
                    help(argv[0]);
                }
                else {
                    fprintf(stderr, "\nUnknown command: %s\n", argv[1]);
                    help(argv[0]);
                    return EXIT_FAILURE;
                }

                break;
            }
            default: {
                fprintf(stderr, "\nInvalid number of arguments: %d\n", argc - 1);
                help(argv[0]);
                return EXIT_FAILURE;
            }
        }

        return EXIT_SUCCESS;
    }
}
