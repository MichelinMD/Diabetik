//
//  UARemindersTooltipView.m
//  Diabetik
//
//  Created by Nial Giacomelli on 06/04/2013.
//  Copyright 2013 Nial Giacomelli
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "UARemindersTooltipView.h"

@implementation UARemindersTooltipView

#pragma mark - Logic
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        CGFloat contentHeight = 200.0f, headerHeight = 30.0f;
        
        UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, floorf(self.frame.size.height/2 - ((contentHeight+headerHeight)/2)), self.frame.size.width, contentHeight+headerHeight)];
        UIView *border = [[UIView alloc] initWithFrame:CGRectMake(floorf(self.frame.size.width/2 - 20), headerHeight+10, 40, 2)];
        border.backgroundColor = [UIColor colorWithRed:234.0f/255.0f green:237.0f/255.0f blue:236.0f/255.0f alpha:1.0f];
        [containerView addSubview:border];
        
        UILabel *header = [[UILabel alloc] initWithFrame:CGRectMake(floorf(self.frame.size.width/2 - 225/2), 0, 225, headerHeight)];
        header.backgroundColor = [UIColor clearColor];
        header.textColor = [UIColor colorWithRed:18.0f/255.0f green:185.0f/255.0f blue:139.0f/255.0f alpha:1.0f];
        header.numberOfLines = 1;
        header.textAlignment = NSTextAlignmentCenter;
        header.font = [UAFont standardBoldFontWithSize:26.0f];
        header.text = NSLocalizedString(@"Reminders", nil);
        header.adjustsFontSizeToFitWidth = YES;
        header.minimumScaleFactor = 0.5f;
        [containerView addSubview:header];
        
        UILabel *content = [[UILabel alloc] initWithFrame:CGRectMake(floorf(self.frame.size.width/2 - 225/2), headerHeight+20, 225, contentHeight)];
        content.backgroundColor = [UIColor clearColor];
        content.textColor = [UIColor colorWithRed:115.0f/255.0f green:128.0f/255.0f blue:123.0f/255.0f alpha:1.0f];
        content.numberOfLines = 0;
        content.textAlignment = NSTextAlignmentCenter;
        content.font = [UAFont standardRegularFontWithSize:16.0f];
        content.text = NSLocalizedString(@"Reminders are a great way to keep on top of things.\n\nAlong with one-time and repeat reminders you can also setup location-based reminders to alert you when you leave or arrive at a particular location.", nil);
        [containerView addSubview:content];
        [self addSubview:containerView];
        
    }
    return self;
}

@end
