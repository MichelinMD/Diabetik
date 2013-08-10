//
//  UASideMenuCell.h
//  Diabetik
//
//  Created by Nial Giacomelli on 27/12/2012.
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

#import <UIKit/UIKit.h>

@interface UASideMenuCell : UITableViewCell
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIImageView *accessoryIcon;
@property (nonatomic, strong) UIImageView *rightAccessoryIcon;

// Logic
- (void)showBottomBorder:(BOOL)state;

@end
