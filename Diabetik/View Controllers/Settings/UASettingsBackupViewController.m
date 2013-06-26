//
//  UASettingsBackupViewController.m
//  Diabetik
//
//  Created by Nial Giacomelli on 23/05/2013.
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

#import <Dropbox/Dropbox.h>
#import "UASettingsBackupViewController.h"
#import "UABackupController.h"
#import "MBProgressHUD.h"

@interface UASettingsBackupViewController ()
{
    UABackupController *backupController;
}

@end

@implementation UASettingsBackupViewController
@synthesize moc = _moc;

#pragma mark - Setup
- (id)initWithMOC:(NSManagedObjectContext *)aMOC
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self)
    {
        self.title = NSLocalizedString(@"Backup/Restore", nil);
        
        _moc = aMOC;
        backupController = [[UABackupController alloc] initWithMOC:self.moc];
    }
    return self;
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UILabel *warningLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width-20.0f, 0.0f)];
    warningLabel.numberOfLines = 0;
    warningLabel.textAlignment = NSTextAlignmentCenter;
    warningLabel.backgroundColor = [UIColor clearColor];
    warningLabel.font = [UAFont standardDemiBoldFontWithSize:14.0f];
    warningLabel.textColor = [UIColor colorWithRed:153.0f/255.0f green:153.0f/255.0f blue:153.0f/255.0f alpha:1.0f];
    warningLabel.text = NSLocalizedString(@"Restoring from backup will never delete existing data. If identical records are found the existing version will be overwritten. We advise backup restoration only be used when absolutely necessary.", nil);
    warningLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
    warningLabel.shadowColor = [UIColor colorWithWhite:1.0f alpha:0.6f];
    [warningLabel sizeToFit];
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, warningLabel.frame.size.height)];
    warningLabel.frame = CGRectMake(floorf(self.view.frame.size.width/2.0f - warningLabel.frame.size.width/2), 0.0f, warningLabel.frame.size.width, warningLabel.frame.size.height);
    [footerView addSubview:warningLabel];
    
    self.tableView.tableFooterView = footerView;
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
    return 2;
}
- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}
- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section
{
    if(section == 0)
    {
        return NSLocalizedString(@"Manual backup", nil);
    }
    else if(section == 1)
    {
        return NSLocalizedString(@"Restore", nil);
    }
    
    return @"";
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40.0f;
}
- (UIView *)tableView:(UITableView *)aTableView viewForHeaderInSection:(NSInteger)section
{
    UAGenericTableHeaderView *header = [[UAGenericTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, aTableView.frame.size.width, 40.0f)];
    [header setText:[self tableView:aTableView titleForHeaderInSection:section]];
    return header;
}
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UAGenericTableViewCell *cell = (UAGenericTableViewCell *)[aTableView dequeueReusableCellWithIdentifier:@"UASettingCell"];
    if (cell == nil)
    {
        cell = [[UAGenericTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"UASettingCell"];
    }
    [cell setCellStyleWithIndexPath:indexPath andTotalRows:[aTableView numberOfRowsInSection:indexPath.section]];
    
    if(indexPath.section == 0 && indexPath.row == 0)
    {
        cell.textLabel.text = NSLocalizedString(@"Perform manual backup", nil);
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.detailTextLabel.text = nil;
    }
    else if(indexPath.section == 1 && indexPath.row == 0)
    {
        cell.textLabel.text = NSLocalizedString(@"Restore from backup", nil);
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.detailTextLabel.text = nil;
    }
    
    return cell;
}

#pragma mar - UITableViewDelegate methods
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:aTableView didSelectRowAtIndexPath:indexPath];
    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(indexPath.section == 0 && indexPath.row == 0)
    {
        DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
        if(!account)
        {
            [[DBAccountManager sharedManager] linkFromController:self];
        }
        else
        {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [backupController backupToDropbox:^(NSError *error) {
    
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                
                if(error)
                {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Uh oh!", nil)
                                                                        message:[NSString stringWithFormat:NSLocalizedString(@"It wasn't possible to export your backup to Dropbox. The following error occurred: %@", nil), [error localizedDescription]]
                                                                       delegate:nil
                                                              cancelButtonTitle:NSLocalizedString(@"Okay", nil)
                                                              otherButtonTitles:nil];
                    [alertView show];
                }
                else
                {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Export successful", nil)
                                                                        message:[NSString stringWithFormat:NSLocalizedString(@"Your backup has been exported successfully", nil), [error localizedDescription]]
                                                                       delegate:nil
                                                              cancelButtonTitle:NSLocalizedString(@"Okay", nil)
                                                              otherButtonTitles:nil];
                    [alertView show];
                }
            }];
        }
    }
    else if(indexPath.section == 1 && indexPath.row == 0)
    {
        DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
        if(!account)
        {
            [[DBAccountManager sharedManager] linkFromController:self];
        }
        else
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Restore from backup", nil)
                                                                message:NSLocalizedString(@"Are you sure you'd like to restore from a previous backup? This cannot be undone.", nil)
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                      otherButtonTitles:NSLocalizedString(@"Restore", nil), nil];
            [alertView show];
        }
    }
}

#pragma mark - UIAlertViewDelegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1)
    {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [backupController restoreFromBackup:^(NSError *error) {
            
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            
            if(!error)
            {
                // Post a notification to let everyone know we've updated the accounts list
                [[NSNotificationCenter defaultCenter] postNotificationName:kAccountsUpdatedNotification object:nil];
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Restore successful", nil)
                                                                    message:[NSString stringWithFormat:NSLocalizedString(@"Your backup was restored successfully", nil), [error localizedDescription]]
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"Okay", nil)
                                                          otherButtonTitles:nil];
                [alertView show];
            }
            else
            {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Uh oh!", nil)
                                                                    message:NSLocalizedString(@"It wasn't possible to restore your backup from Dropbox. The following error occurred: %@", nil)
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"Okay", nil)
                                                          otherButtonTitles:nil];
                [alertView show];
            }
        }];
    }
}
@end
