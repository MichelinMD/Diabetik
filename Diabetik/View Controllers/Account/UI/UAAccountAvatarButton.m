//
//  UAAccountAvatarButton.m
//  Diabetik
//
//  Created by Nial Giacomelli on 05/03/2013.
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

#import "UAAccountAvatarButton.h"

@implementation UAAccountAvatarButton

#pragma mark - Setup
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.imageView.frame = CGRectMake(5.0f, 4.0f, self.frame.size.width-10.0f, self.frame.size.height-10.0f);
}
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    UIImage *background = [UIImage imageNamed:@"AccountAvatarDefault.png"];
    [background drawAtPoint:CGPointMake(0.0f, 0.0f)];
}

@end
