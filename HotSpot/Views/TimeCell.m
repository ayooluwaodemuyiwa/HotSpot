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

@end
@implementation TimeCell
- (void)setTime:(TimeSlot *)timeSlot{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"hh:mmaa"];
    self.timeLabel.text = [formatter stringFromDate:timeSlot.date];
}
@end
