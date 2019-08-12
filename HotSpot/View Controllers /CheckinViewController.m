//
//  CheckinViewController.m
//  HotSpot
//
//  Created by drealin on 8/5/19.
//  Copyright © 2019 aodemuyi. All rights reserved.
//

#import "CheckinViewController.h"

#import "Booking.h"
#import "CancelViewController.h"
#import "DataManager.h"

@interface CheckinViewController ()
@property (strong, nonatomic) Booking *booking;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *startTimeLabel;
@end

@implementation CheckinViewController
{
    NSNumber *pricePerHour;
    CGFloat duration;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [DataManager getNextBookingWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if(error) {
            NSLog(@"%@", error);
        }
        else {
            Booking *booking = object;
            self.booking = booking;
            [booking.listing fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                Listing *listing = object;
                pricePerHour = listing.price;
                CGFloat totalPrice = [pricePerHour floatValue] * duration / 60 / 60;
                self.totalPriceLabel.text = [NSString stringWithFormat:@"$%0.2f", totalPrice];
                [DataManager getAddressNameFromListing:listing withCompletion:^(NSString *name, NSError * _Nullable error){
                    if(error) {
                        NSLog(@"%@", error);
                    }
                    else {
                        self.addressLabel.text = name;
                    }
                }];
            }];
            NSDateFormatter *withDayFormatter = [[NSDateFormatter alloc] init];
            [withDayFormatter setDateFormat:@"M/dd/yyyy, h:mmaa"];
            NSDateFormatter *withoutDayFormatter = [[NSDateFormatter alloc] init];
            [withoutDayFormatter setDateFormat:@"h:mmaa"];
            [booking.timeInterval fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                TimeInterval *timeInterval = object;
                duration = [timeInterval.endTime timeIntervalSinceDate:timeInterval.startTime];
                self.startTimeLabel.text = [NSString stringWithFormat:@"%@ to %@", [withDayFormatter stringFromDate:booking.startTime], [withoutDayFormatter stringFromDate:timeInterval.endTime]];
                CGFloat totalPrice = [pricePerHour floatValue] * duration / 60 / 60;
                self.totalPriceLabel.text = [NSString stringWithFormat:@"$%0.2f", totalPrice];
            }];
            
        }
    }];
}
- (IBAction)checkinClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)closeClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"cancelSegue"]) {
        CancelViewController *cancelViewController = [segue destinationViewController];
        cancelViewController.booking = self.booking;
    }
}

@end
