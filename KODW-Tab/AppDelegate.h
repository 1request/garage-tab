//
//  AppDelegate.h
//  KODW-Tab
//
//  Created by Harry Ng on 11/6/14.
//  Copyright (c) 2014 Request. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Beacon.h"

static NSString * const mobileAddress = @"http://www.homesmartly.com";
static NSString * const apiAddress = @"http://api.homesmartly.com";
static NSString * const appKey = @"ff4d7e089391392c14547f2d";

@interface AppDelegate : UIResponder <UIApplicationDelegate, BeaconNotificationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) Beacon *beacon;

@end

