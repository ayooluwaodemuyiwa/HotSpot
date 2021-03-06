
//
//  ParkingSearchViewController.m
//  HotSpot
//
//  Created by aodemuyi on 7/16/19.
//  Copyright © 2019 aodemuyi. All rights reserved.
//

#import "ParkingSearchViewController.h"
#import "MapKit/MapKit.h"
#import "SearchCell.h"
#import "SearchResult.h"
#import "MainContainerViewController.h"
#import "Listing.h"
#import "DataManager.h"
#import "DetailsViewController.h"
#import "LocationManagerSingleton.h"

@interface ParkingSearchViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSArray *numberArray;
@property (strong, nonatomic) LocationManagerSingleton *locationManager;

@end

@implementation ParkingSearchViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // initializing our table
    self.searchTableView.estimatedRowHeight = 85.0;
    self.searchTableView.rowHeight = UITableViewAutomaticDimension;
    self.searchTableView.delegate = self;
    self.searchTableView.dataSource = self;
    self.locationManager = [LocationManagerSingleton sharedSingleton];
    
    // this is replaced by the user location once it is called in map 
    self.initialLocation = [[CLLocation alloc] initWithLatitude:self.locationManager.locationManager.location.coordinate.latitude longitude:self.locationManager.locationManager.location.coordinate.longitude];
    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:self.initialLocation.coordinate.latitude longitude:self.initialLocation.coordinate.longitude]; // san francisco
    [DataManager getListingsNearLocation:geoPoint withCompletion:^(NSArray<Listing *> * _Nonnull listings, NSError * _Nonnull error) {
        if(error) {
            NSLog(@"%@ oops", error);
        }
        else{
            self.listings = listings;
            // in case the update is done on the wrong thread
            dispatch_async(dispatch_get_main_queue(), ^{
            [self.searchTableView reloadData];
            });
        }
    }];
    

}

# pragma mark - TableViewController methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (self.listings.count == 0){
        SearchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchCell"];
        if(cell == nil){
            cell = [[SearchCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SearchCell"];
        }
        cell.searchTableImage.image = [UIImage imageNamed:@"ourlogo"];
        cell.searchTablePrice.text = @"No Spots";
        cell.searchTableAddress.text = @" ";
        cell.searchTableMilesAway.text = @" please try a different location";
        return cell;
    }
    else{
    SearchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchCell"];
    if(cell == nil){
        cell = [[SearchCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SearchCell"];
    }
       
//    self.listings = [self sortListingArraybyAscending:self.listings];
    
    Listing *listing = self.listings[indexPath.row];
    [DataManager getAddressNameFromListing: listing withCompletion:^(NSString *name, NSError * _Nullable error){
        if(error) {
            NSLog(@"%@", error);
        }
        else {
            cell.searchTableAddress.text = name;
        }
    }];
    cell.searchTablePrice.text = [NSString stringWithFormat: @"$%@/hr", listing.price];
    
    CLLocationCoordinate2D spotLocation = CLLocationCoordinate2DMake(listing.address.latitude,
                                                                     listing.address.longitude);
    CGFloat distanceBetweenPoints = [DataManager getDistancebetweenAddressOne:spotLocation andAddressTwo:self.initialLocation.coordinate];
    cell.searchTableMilesAway.text = [NSMutableString stringWithFormat:@"%.02f mi",distanceBetweenPoints];
    
    PFFileObject *img = listing.picture;
    [img getDataInBackgroundWithBlock:^(NSData *imageData,NSError *error){
        UIImage *imageToLoad = [UIImage imageWithData:imageData];
        cell.searchTableImage.image = imageToLoad;
    }];
    // trying to resize text to work with Autolayout
    cell.searchTablePrice.adjustsFontSizeToFitWidth = YES;
    return cell;
    }
    
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(self.listings.count == 0){
        return 1;
    }
    return self.listings.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // perform segue
    if (self.listings.count >0){
    [self performSegueWithIdentifier:@"detailsSegue"
                              sender:self.listings[indexPath.row]];
    }
}
 

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"detailsSegue"]) {
        DetailsViewController *detailsViewController = [segue destinationViewController];
        detailsViewController.listing = sender;
    }
}

#pragma mark - Action Items

#pragma mark - Helper Methods

+ (NSArray*)sortListingArraybyAscending:(NSArray<Listing*>*)unsortedArray withLocation:(CLLocation*)location{
    NSArray *sortedArray;
    sortedArray = [unsortedArray sortedArrayUsingComparator:^NSComparisonResult(Listing* a,Listing* b) {
        CLLocationCoordinate2D addressOne = CLLocationCoordinate2DMake(a.address.latitude, a.address.longitude);
        CLLocationCoordinate2D addressTwo = CLLocationCoordinate2DMake(b.address.latitude, b.address.longitude);
        NSNumber *distance1 = [NSNumber numberWithDouble:[DataManager getDistancebetweenAddressOne:addressOne andAddressTwo:location.coordinate]];
        NSNumber *distance2 = [NSNumber numberWithDouble:[DataManager getDistancebetweenAddressOne:addressTwo andAddressTwo:location.coordinate]];
        if ([distance1 doubleValue] == [distance2 doubleValue]){
            return NSOrderedSame;
        }
        else if ([distance1 doubleValue] > [distance2 doubleValue]){
            return NSOrderedDescending;
        }
        return NSOrderedAscending;
        
    }];
    return sortedArray;
}

+ (NSArray*)sortListingArraybyDescending:(NSArray<Listing*>*)unsortedArray withLocation:(CLLocation*)location{
    NSArray *sortedArray;
    sortedArray = [unsortedArray sortedArrayUsingComparator:^NSComparisonResult(Listing* a,Listing* b) {
        CLLocationCoordinate2D addressOne = CLLocationCoordinate2DMake(a.address.latitude, a.address.longitude);
        CLLocationCoordinate2D addressTwo = CLLocationCoordinate2DMake(b.address.latitude, b.address.longitude);
        NSNumber *distance1 = [NSNumber numberWithDouble:[DataManager getDistancebetweenAddressOne:addressOne andAddressTwo:location.coordinate]];
        NSNumber *distance2 = [NSNumber numberWithDouble:[DataManager getDistancebetweenAddressOne:addressTwo andAddressTwo:location.coordinate]];
        if ([distance1 doubleValue] == [distance2 doubleValue]){
            return NSOrderedSame;
        }
        else if ([distance1 doubleValue] > [distance2 doubleValue]){
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
        
    }];
    return sortedArray;
}

+ (NSArray*)sortListingArraybyPriceADescending:(NSArray<Listing*>*)unsortedArray{
    NSArray *sortedArray;
    sortedArray = [unsortedArray sortedArrayUsingComparator:^NSComparisonResult(Listing* a,Listing* b) {
        NSNumber *price1 = a.price;
        NSNumber *price2 = b.price;
        if ([price1 intValue] == [price2 intValue]){
            return NSOrderedSame;
        }
        else if ([price1 intValue] > [price2 intValue]){
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
        
    }];
    return sortedArray;
}

+ (NSArray*)sortListingArraybyPriceAscending:(NSArray<Listing*>*)unsortedArray{
    NSArray *sortedArray;
    sortedArray = [unsortedArray sortedArrayUsingComparator:^NSComparisonResult(Listing* a,Listing* b) {
        NSNumber *price1 = a.price;
        NSNumber *price2 = b.price;
        if ([price1 intValue] == [price2 intValue]){
            return NSOrderedSame;
        }
        else if ([price1 intValue] > [price2 intValue]){
            return NSOrderedDescending;
        }
        return NSOrderedAscending;
        
    }];
    return sortedArray;
}




    
@end
