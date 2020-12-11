//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Mar 22 2020 01:47:48).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//


@class MRCryptoPairingSession, NSData, NSError, NSString;

@protocol MRCryptoPairingSessionDelegate <NSObject>
- (void)pairingSession:(MRCryptoPairingSession *)arg1 didPrepareExchangeData:(NSData *)arg2;

@optional
- (void)pairingSession:(MRCryptoPairingSession *)arg1 didCompleteExchangeWithError:(NSError *)arg2;
- (void)pairingSession:(MRCryptoPairingSession *)arg1 promptForSetupCodeWithDelay:(double)arg2 completion:(void (^)(NSString *))arg3;
- (void)pairingSessionHideSetupCode:(MRCryptoPairingSession *)arg1;
- (void)pairingSession:(MRCryptoPairingSession *)arg1 showSetupCode:(NSString *)arg2;
@end
