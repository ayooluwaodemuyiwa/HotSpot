//
//  DataManager.m
//  HotSpot
//
//  Created by drealin on 7/16/19.
//  Copyright © 2019 aodemuyi. All rights reserved.
//

#import "DataManager.h"

#import "Parse/Parse.h"
#import "Listing.h"

@implementation DataManager

# pragma mark - Class Methods

+ (void)configureParse {
    
    ParseClientConfiguration *config = [ParseClientConfiguration   configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {
        
        configuration.applicationId = @"myAppId";
        configuration.server = @"http://hotspot2017.herokuapp.com/parse";
    }];
    
    [Parse initializeWithConfiguration:config];
    
}

+ (void)getListingsNearLocation:(PFGeoPoint *)point
                   withCompletion:(void(^)(NSArray<Listing *> *listings, NSError *error))completion{
    
    PFQuery *query = [Listing query];
    [query whereKey:@"address" nearGeoPoint:point withinKilometers:2]; // number of kilometers empirically set, for now
    
    // fetch data for home timeline posts asynchronously
    [query findObjectsInBackgroundWithBlock:completion];
}

@end
