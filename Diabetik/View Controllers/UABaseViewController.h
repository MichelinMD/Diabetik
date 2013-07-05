//
//  UABaseViewController.h
//  Diabetik
//
//  Created by Nial Giacomelli on 11/12/2012.
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
#import "UAUI.h"
#import "UAHelper.h"
#import "JASidePanelController.h"
#import "UIViewController+JASidePanel.h"

@interface UABaseViewController : UIViewController
{
    BOOL isVisible;
    BOOL isFirstLoad;
    
    id accountSwitchNotifier;
}
@property (nonatomic, retain) NSManagedObjectContext *moc;
@property (nonatomic, retain) UIView *activeField;

@property (nonatomic, strong) NSIndexPath *activeControlIndexPath;
@property (nonatomic, strong) NSIndexPath *previouslyActiveControlIndexPath;

// Logic
- (void)handleBack:(id)sender withSound:(BOOL)playSound;
- (void)handleBack:(id)sender;
- (BOOL)isPresentedModally;
- (void)didSwitchUserAccount;

// Helpers
- (UIView *)dismissableView;

@end

@interface UABaseTableViewController : UABaseViewController <UITableViewDataSource, UITableViewDelegate>
{
    UITableViewStyle tableStyle;
}
@property (nonatomic, strong) UITableView *tableView;

// Setup
- (id)initWithStyle:(UITableViewStyle)style;

// Logic
- (void)keyboardWillBeShown:(NSNotification*)aNotification;
- (void)keyboardWasShown:(NSNotification*)aNotification;
- (void)keyboardWillBeHidden:(NSNotification*)aNotification;

@end
