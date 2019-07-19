//
//  SignUpViewController.m
//  HotSpot
//
//  Created by aaronm17 on 7/16/19.
//  Copyright © 2019 aodemuyi. All rights reserved.
//

#import "SignUpViewController.h"
#import "Parse/Parse.h"

@interface SignUpViewController ()

@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UITextField *fullName;
@property (weak, nonatomic) IBOutlet UITextField *phoneNumber;
@property (weak, nonatomic) IBOutlet UITextField *email;

@end

@implementation SignUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

//registers a user, throws up an alert with an "empty" error message if one of the fields is empty.
//if there's a different error, it throws up an alert with the specific error description
- (void)registerUser {
    PFUser *newUser = [PFUser user];
    
    newUser.username = self.username.text;
    newUser.password = self.password.text;
    newUser[@"name"] = self.fullName.text;
    newUser[@"phone"] = self.phoneNumber.text;
    newUser[@"email"] = self.email.text;
    
    //creates UIAlertController
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sign Up Error"
                                                                   message:@"" preferredStyle:UIAlertControllerStyleAlert];

    // create an OK action
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
                                                         nil;
                                                     }];
    // add the OK action to the alert controller
    [alert addAction:okAction];
    
    //checks if any of the fields are empty and throws up an alert
    //if they are
    if (self.username.text.length == 0 || self.password.text.length == 0 || self.fullName.text.length == 0 || self.phoneNumber.text.length == 0 || self.email.text.length == 0) {
        alert.message = @"One or more of your fields is empty";
        [self presentViewController:alert animated:YES completion:^{
        }];
    } else {
        [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
            if (error != nil) {
                //if there's an error, throw up an alert with the specific error as the message
                alert.message = [NSString stringWithFormat:@"%@", error.localizedDescription];
                [self presentViewController:alert animated:YES completion:^{
                }];
            }
        }];
        [PFUser logInWithUsernameInBackground:self.username.text password:self.password.text block:^(PFUser *user, NSError *error) {
            if (error != nil) {
                alert.message = [NSString stringWithFormat:@"%@", error.localizedDescription];
                [self presentViewController:alert animated:YES completion:^{
                }];
            } else {
                [self performSegueWithIdentifier:@"signUpSegue" sender:nil];
            }
        }];
    }
}

//when the user taps the view, to dismiss the keyboard
- (IBAction)onViewTap:(UITapGestureRecognizer *)sender {
    [self.view endEditing:(YES)];
}

//dismisses the sign in view controller if the user already has an account
- (IBAction)didTapSignIn:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)didTapCreateAccount:(UIButton *)sender {
    [self registerUser];
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
