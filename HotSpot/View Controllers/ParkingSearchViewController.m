//
//  ParkingSearchViewController.m
//  HotSpot
//
//  Created by aodemuyi on 7/16/19.
//  Copyright © 2019 aodemuyi. All rights reserved.
//

#import "ParkingSearchViewController.h"

#import "MapKit/MapKit.h"
<<<<<<< HEAD:HotSpot/ParkingSearchViewController.m
#import "SpotCell.h"
=======
#import "SearchCell.h"
#import "Listing.h"
#import "DataManager.h"
#import "DetailsViewController.h"
>>>>>>> 21a65e1c7aae4143cc7069f1f42f2a5bf50da038:HotSpot/View Controllers/ParkingSearchViewController.m
#define METERS_PER_MILE 1609.344

@interface ParkingSearchViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *mapSearchBar;
/*
 the map isn't currently set to a specific location, but I will update
 this as soon as I merge with the datamanager.
 */
@property (weak, nonatomic) IBOutlet MKMapView *searchMap;
@property (weak, nonatomic) IBOutlet UISegmentedControl *modeSwitchButton;
@property (weak, nonatomic) IBOutlet UITableView *searchTableView;
@property (strong, nonatomic) NSArray<Listing *> *listings;

@end

@implementation ParkingSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.searchTableView.dataSource = self;
    self.searchTableView.delegate = self;
    self.searchTableView.rowHeight = 134 ;
    self.searchTableView.hidden = YES;
    // we will initialize the map to show the user's current location
    // self.searchMap.showsUserLocation = YES;
    
    // testing using a specific latitude
    CLLocation *initialLocation = [[CLLocation alloc] initWithLatitude:37.484928 longitude:-122.148201];
    MKCoordinateRegion initialRegion = MKCoordinateRegionMake(initialLocation.coordinate, MKCoordinateSpanMake(0.1, 0.1));
    [self.searchMap setRegion:initialRegion animated:YES];
    
    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLocation:initialLocation];
    
    [DataManager getListingsNearLocation:geoPoint withCompletion:^(NSArray<Listing *> * _Nonnull listings, NSError * _Nonnull error) {
        self.listings = listings;
        [self.searchTableView reloadData];
    }];
}

# pragma mark - TableViewController methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    /*
     This is where we are passing information into the cells.
     For now, I have placeholder information so that when we merge
     I can have data to load actual information into the tables.
     */
    
    SpotCell *parkingCell = [tableView dequeueReusableCellWithIdentifier:@"SpotCell"];
    if(parkingCell == nil){
        parkingCell = [[SpotCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SpotCell"];
    }
    
    Listing *listing = self.listings[indexPath.row];
    
    [DataManager getAddressNameFromPoint:listing.address withCompletion:^(NSString *name, NSError * _Nullable error){
        if(error) {
            NSLog(@"%@", error);
        }
        else {
            cell.searchTableAddress.text = name;
        }
    }];
    
    
    cell.searchTablePrice.text = [NSString stringWithFormat: @"$%@/hr", listing.price];
    
    //placehodlder information
<<<<<<< HEAD:HotSpot/ParkingSearchViewController.m
    parkingCell.spotTableAddress.text= @"100 West Lake";
    parkingCell.spotTableDetails.text = @"50 miles away";
    parkingCell.spotTablePrice.text= @"$5/hr";
    parkingCell.spotTableImage.image = [UIImage imageNamed:@"houseimageexample"];
=======
    cell.searchTableMilesAway.text = @"50 miles away";
    cell.searchTableImage.image = [UIImage imageNamed:@"houseimageexample"];
>>>>>>> 21a65e1c7aae4143cc7069f1f42f2a5bf50da038:HotSpot/View Controllers/ParkingSearchViewController.m
    
    // trying to resize text to work with Autolayout

    parkingCell.spotTablePrice.adjustsFontSizeToFitWidth = YES;
     
    
    return parkingCell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.listings.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // perform segue
    [self performSegueWithIdentifier:@"detailsSegue"
                              sender:self.listings[indexPath.row]];
    
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"detailsSegue"]) {
        DetailsViewController *detailsViewController = [segue destinationViewController];
        detailsViewController.listing = sender;
    }
}

#pragma mark - Action Items

- (IBAction)modeButtonPressed:(id)sender {
    if(!self.searchTableView.hidden){
        self.searchTableView.hidden = YES;
        self. searchMap.hidden = NO;
    }
    else{
    self.searchTableView.hidden = NO;
    self.searchMap.hidden = YES;
    }
    
}

#pragma mark - Helper methods


@end