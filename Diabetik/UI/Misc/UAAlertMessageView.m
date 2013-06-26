//
//  UAAlertMessageView.m
//  Diabetik
//
//  Created by Nial Giacomelli on 05/04/2013.
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

#import "UAAlertMessageView.h"

@implementation UAAlertMessageView

#pragma mark - Setup
- (id)initWithFrame:(CGRect)frame andTitle:(NSString *)title andMessage:(NSString *)message 
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.title = title;
        self.message = message;
        
        [self setNeedsLayout];
    }
    return self;
}

#pragma mark - Rendering
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGFloat height = 23.0f + 14.0f + 13.0f;
    CGFloat textHeight = floorf([self.message sizeWithFont:[UAFont standardDemiBoldFontWithSize:14.0f]
                                         constrainedToSize:CGSizeMake(self.frame.size.width-90.0f, CGFLOAT_MAX)
                                             lineBreakMode:NSLineBreakByWordWrapping].height);
    height += textHeight + 23.0f;
    
    CGRect f = CGRectMake(25.0f, floorf(self.frame.size.height/2-height/2), floorf(self.frame.size.width-50.0f), height);
    
    UIImage *background = [[UIImage imageNamed:@"EmptyStateBackground.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(6, 6, 6, 6)];
    [background drawInRect:CGRectMake(f.origin.x, f.origin.y, f.size.width, f.size.height)];
    
    [[UIColor colorWithRed:102.0f/255.0f green:102.0f/255.0f blue:102.0f/255.0f alpha:1.0f] setFill];
    [self.title drawInRect:CGRectMake(f.origin.x+20.0f, f.origin.y + 23.0f, f.size.width-40.0f, 14.0f) withFont:[UAFont standardDemiBoldFontWithSize:16.0f] lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentCenter];

    [[UIColor colorWithRed:163.0f/255.0f green:163.0f/255.0f blue:163.0f/255.0f alpha:1.0f] setFill];
    [self.message drawInRect:CGRectMake(f.origin.x+20.0f, f.origin.y + 23.0f + 14.0f + 13.0f, f.size.width-45.0f, textHeight) withFont:[UAFont standardMediumFontWithSize:14.0f] lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentCenter];
}

@end