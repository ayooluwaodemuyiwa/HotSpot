//
//  TimeCell.m
//  HotSpot
//
//  Created by drealin on 7/23/19.
//  Copyright © 2019 aodemuyi. All rights reserved.
//

#import "TimeCell.h"
#import "TimeSlot.h"

@interface TimeCell()
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end
@implementation TimeCell
- (void)setTime:(TimeSlot *)timeSlot{
    self.timeLabel.text = [NSString stringWithFormat:@"%d:%d", timeSlot.hour, timeSlot.minute];
}
@end
