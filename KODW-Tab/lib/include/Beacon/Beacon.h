//
//  Beacon.h
//  Beacon
//
//  Copyright (c) 2014 Stone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@import CoreLocation;
@import CoreBluetooth;

static NSString * const kUUID_Estimote = @"B9407F30-F5F8-466E-AFF9-25556B57FE6D";


static NSString * const kIdentifier = @"SomeIdentifier";


@protocol BeaconNotificationDelegate <NSObject>

- (void)NotifyWhenEntryBeacon:(CLBeaconRegion*)beaconRegion;
- (void)NotifyWhenExitBeacon:(CLBeaconRegion*)beaconRegion;

@end


@interface Beacon : NSObject<CLLocationManagerDelegate>

@property (nonatomic,assign) id<BeaconNotificationDelegate> delegate;

- (void)getBeacons:(NSString *)address;

@end
