//
//  LocationManagerSingleton.h
//  HotSpot
//
//  Created by aodemuyi on 8/7/19.
//  Copyright © 2019 aodemuyi. All rights reserved.
//

#import <MapKit/MapKit.h>
NS_ASSUME_NONNULL_BEGIN


@interface LocationManagerSingleton : NSObject <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager* locationManager;

+ (LocationManagerSingleton*)sharedSingleton;

@end

NS_ASSUME_NONNULL_END
