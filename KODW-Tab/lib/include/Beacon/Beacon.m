//
//  Beacon.m
//  Beacon
//
//  Copyright (c) 2014 Stone. All rights reserved.
//

#import "Beacon.h"

@interface Beacon ()

@property (nonatomic, strong) CLLocationManager *locationManager;

@end



@implementation Beacon

#pragma mark - Common
- (void)createLocationManager
{
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }
}

- (void)getBeacons:(NSString *)address
{
    NSURL *url = [NSURL URLWithString:address];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (!data) {
            NSLog(@"%s: sendAynchronousRequest error: %@", __FUNCTION__, connectionError);
            return;
        } else {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            if (statusCode != 200) {
                NSLog(@"%s: sendAsynchronousRequest status code != 200: response = %@", __FUNCTION__, response);
                return;
            }
        }
        
        NSError *parseError = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        if (!dictionary) {
            NSLog(@"%s: JSONObjectWithData error: %@; data = %@", __FUNCTION__, parseError, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            return;
        }
        
        // Start using dictionary
        [self createLocationManager];
        
        if (![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
            NSLog(@"Couldn't turn on region monitoring: Region monitoring is not available for CLBeaconRegion class.");
            return;
        }
        
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.locationManager requestAlwaysAuthorization];
        }
        
        NSArray *beaconArray = [dictionary objectForKey:@"beacons"];
        int count = 0;
        for (NSDictionary *object in beaconArray) {
            NSString *uuid = [object objectForKey:@"uuid"];
            NSString *major = [object objectForKey:@"major"];
            NSString *minor = [object objectForKey:@"minor"];
            
            NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:uuid];
            NSInteger kMajor = [major integerValue];
            NSInteger kMinor = [minor integerValue];
            
            NSLog(@"uuid -> %@ / major -> %@ / minor -> %@", uuid, major, minor);
            
            NSString *identifier = [NSString stringWithFormat:@"beacon-%d-%@-%@", count, major, minor];
            CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:kMajor minor:kMinor identifier:identifier];
            beaconRegion.notifyEntryStateOnDisplay = YES;
            beaconRegion.notifyOnEntry = YES;
            beaconRegion.notifyOnExit = YES;
            
            [self.locationManager startRangingBeaconsInRegion:beaconRegion];
            [self.locationManager startMonitoringForRegion:beaconRegion];
            
            NSArray *actions = [object objectForKey:@"actions"];
            for (NSDictionary *action in actions) {
                NSString *url = [action objectForKey:@"url"];
                // REMOVE ME //
                url = @"http://www.reque.st/";
                // REMOVE ME //
                [[NSUserDefaults standardUserDefaults] setObject:url forKey:@"url"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            count++;
        }
        
        // REMOVE ME //
        NSString *uuid = @"B9407F30-F5F8-466E-AFF9-25556B57FE6D";
        NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:uuid];
        CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:1000 minor:2000 identifier:@"beacon"];
        beaconRegion.notifyEntryStateOnDisplay = YES;
        beaconRegion.notifyOnEntry = YES;
        beaconRegion.notifyOnExit = YES;
        
        [self.locationManager startRangingBeaconsInRegion:beaconRegion];
        [self.locationManager startMonitoringForRegion:beaconRegion];
        // REMOVE ME //

    }];
}

#pragma mark - Location manager delegate methods
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (![CLLocationManager locationServicesEnabled]) {
        NSLog(@"Couldn't turn on monitoring: Location services are not enabled.");
        return;
    }
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
        NSLog(@"Couldn't turn on monitoring: Location services not authorised.");
    }
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways) {
        NSLog(@"Couldn't turn on monitoring: Location services (Always) not authorised.");
        return;
    }
    
}

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region {
    
    NSLog(@"%s Range region: %@ with beacons %@",__PRETTY_FUNCTION__ ,region , beacons);
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLBeaconRegion *)region
{
    NSLog(@"Entered region: %@", region);
    
    if (self.delegate) {
        [self.delegate NotifyWhenEntryBeacon:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLBeaconRegion *)region
{
    NSLog(@"Exited region: %@", region);
    
    if (self.delegate) {
        [self.delegate NotifyWhenExitBeacon:region];
    }
    
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    NSString *stateString = nil;
    switch (state) {
        case CLRegionStateInside:
            stateString = @"inside";
            break;
        case CLRegionStateOutside:
            stateString = @"outside";
            break;
        case CLRegionStateUnknown:
            stateString = @"unknown";
            break;
    }
    NSLog(@"State changed to %@ for region %@.", stateString, region);
    
    
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSString *message = [NSString stringWithFormat:@"error: %@ / region: %@", [error description], region.minor];
    NSLog(@"%@", message);
}

@end
