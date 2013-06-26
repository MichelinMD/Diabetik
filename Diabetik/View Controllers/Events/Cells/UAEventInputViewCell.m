//
//  UAEventInputViewCell.m
//  Diabetik
//
//  Created by Nial Giacomelli on 20/02/2013.
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

#import "UAEventInputViewCell.h"

@implementation UAEventInputViewCell
@synthesize control = _control;
@synthesize label = _label;
@synthesize borderView = _borderView;

#pragma mark - Setup
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.backgroundView = [[UIView alloc] initWithFrame:self.frame];
        self.backgroundView.backgroundColor = [UIColor clearColor];
        
        _label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 75.0f, 44.0f)];
        _label.font = [UAFont standardMediumFontWithSize:16.0f];
        _label.textAlignment = NSTextAlignmentRight;
        _label.backgroundColor = [UIColor clearColor];
        _label.text = @" ";
        _label.textColor = [UIColor colorWithRed:163.0f/255.0f green:174.0f/255.0f blue:170.0f/255.0f alpha:1.0f];
        _label.adjustsFontSizeToFitWidth = YES;
        if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
        {
            _label.minimumScaleFactor = 0.5f;
        }
        else
        {
            _label.minimumFontSize = 8.0f;
        }
        [self.contentView addSubview:_label];
        
        _borderView = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height-1.0f, self.frame.size.width, 1.0f)];
        _borderView.backgroundColor = [UIColor colorWithRed:232.0f/255.0f green:234.0f/255.0f blue:235.0f/255.0f alpha:1.0f];
        _borderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [self.contentView addSubview:_borderView];
    }
    return self;
}

#pragma mark - Logic
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.borderView.frame = CGRectMake(0, self.frame.size.height-1.0f, self.frame.size.width, 1.0f);
    self.control.frame = CGRectMake(85.0f, 0.0f, self.frame.size.width-85.0f, self.frame.size.height);
}
- (void)setControl:(UIView *)aControl
{
    if(self.control)
    {
        [self.control removeFromSuperview];
        _control = nil;
    }
    
    _control = aControl;
    [self.contentView addSubview:self.control];
}
- (void)setDrawsBorder:(BOOL)border
{
    if(border)
    {
        self.borderView.backgroundColor = [UIColor colorWithRed:232.0f/255.0f green:234.0f/255.0f blue:235.0f/255.0f alpha:1.0f];
        self.borderView.hidden = NO;
    }
    else
    {
        self.borderView.hidden = YES;
    }
}

@end
