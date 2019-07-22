//
//  ProfileViewController.m
//  HotSpot
//
//  Created by aaronm17 on 7/18/19.
//  Copyright © 2019 aodemuyi. All rights reserved.
//

#import "ProfileViewController.h"
#import "Parse/Parse.h"
#import "CarCell.h"
#import "Car.h"

@interface ProfileViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *phone;
@property (weak, nonatomic) IBOutlet UILabel *email;
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UIImageView *carImage;
@property (weak, nonatomic) IBOutlet UILabel *carColor;
@property (weak, nonatomic) IBOutlet UILabel *licensePlate;
@property (strong, nonatomic) NSArray *cars;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.profileImage.layer.cornerRadius = self.profileImage.frame.size.width / 2;
    self.profileImage.clipsToBounds = YES;
    
    PFUser *currentUser = [PFUser currentUser];
    self.profileImage.image = currentUser[@"profilePicture"];
    self.name.text = currentUser[@"name"];
    self.phone.text = currentUser[@"phone"];
    self.email.text = currentUser[@"email"];
    self.username.text = currentUser.username;
    
    [self fetchCars];
    if (currentUser[@"cars"] == nil) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"New User: Add a car"
                                                                       message:@"Please add a car before proceeding" preferredStyle:UIAlertControllerStyleAlert];
        
        // create an OK action
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             nil;
                                                         }];
        // add the OK action to the alert controller
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:^{
            [self performSegueWithIdentifier:(@"carSegue") sender:(nil)];
        }];
        self.licensePlate.text = @"TBD";
        self.carColor.text = @"TBD";
    } else {
        for (Car *car in self.cars) {
            if (car[@"isDefault"]) {
                currentUser[@"defaultCar"] = car;
                self.licensePlate.text = car[@"license"];
                self.carColor.text = car[@"Color"];
            }
        }
    }
}

- (IBAction)didTapCarCell:(UITapGestureRecognizer *)sender {
    [self performSegueWithIdentifier:(@"carSegue") sender:(nil)];
}

- (void)fetchCars {
    PFRelation *relation = [[PFUser currentUser] relationForKey:@"cars"];
    PFQuery *query = relation.query;
    [query orderByDescending:@"createdAt"];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *cars, NSError *error) {
        if (cars != nil) {
            self.cars = [[NSMutableArray alloc] initWithArray:cars];
        }
    }];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
