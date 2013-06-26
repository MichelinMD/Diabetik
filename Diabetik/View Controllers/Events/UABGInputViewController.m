//
//  UABGInputViewController.m
//  Diabetik
//
//  Created by Nial Giacomelli on 05/12/2012.
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

#import "UABGInputViewController.h"

#define kDatePickerViewTag 1
#define kToolbarViewTag 2
#define kValueInputControlTag 3
#define kDateInputControlTag 4
#define kIconTag 5

@interface UABGInputViewController ()
{
    NSString *value;
    NSString *mgValue;
    NSString *mmoValue;
    
    NSNumberFormatter *valueFormatter;
    
    UAReading *reading;
}
@end

@implementation UABGInputViewController

#pragma mark - Setup
- (id)initWithMOC:(NSManagedObjectContext *)aMOC
{
    self = [super initWithMOC:aMOC];
    if (self) {
        self.title = NSLocalizedString(@"Add a Reading", @"Add blood glucose reading");
        value = @"";
        
        valueFormatter = [[NSNumberFormatter alloc] init];
        [valueFormatter setMaximumFractionDigits:1];
    }
    return self;
}
- (id)initWithEvent:(UAEvent *)aEvent andMOC:(NSManagedObjectContext *)aMOC
{
    self = [super initWithEvent:aEvent andMOC:aMOC];
    if(self)
    {
        self.title = NSLocalizedString(@"Edit Reading", @"Edit blood glucose reading");
        
        reading = (UAReading *)aEvent;
        
        valueFormatter = [[NSNumberFormatter alloc] init];
        [valueFormatter setMaximumFractionDigits:1];
        
        mmoValue = [valueFormatter stringFromNumber:reading.mmoValue];
        mgValue = [valueFormatter stringFromNumber:reading.mgValue];
        
        NSInteger unitSetting = [[NSUserDefaults standardUserDefaults] integerForKey:kBGTrackingUnitKey];
        if(unitSetting == BGTrackingUnitMG)
        {
            value = mgValue;
        }
        else
        {
            value = mmoValue;
        }
    }
    
    return self;
}

#pragma mark - Logic
- (NSError *)validationError
{
    if(value && [value length])
    {
        if([self.date compare:[NSDate date]] == NSOrderedAscending)
        {
            UAAccount *activeAccount = [[UAAccountController sharedInstance] activeAccount];
            if(!activeAccount)
            {
                NSMutableDictionary *errorInfo = [NSMutableDictionary dictionary];
                [errorInfo setValue:NSLocalizedString(@"We were unable to save your reading", @"Error message for blood glucose reading") forKey:NSLocalizedDescriptionKey];
                return [NSError errorWithDomain:kErrorDomain code:0 userInfo:errorInfo];
            }
        }
        else
        {
            NSMutableDictionary *errorInfo = [NSMutableDictionary dictionary];
            [errorInfo setValue:NSLocalizedString(@"You cannot enter an event in the future", nil) forKey:NSLocalizedDescriptionKey];
            return [NSError errorWithDomain:kErrorDomain code:0 userInfo:errorInfo];
        }
    }
    else
    {
        NSMutableDictionary *errorInfo = [NSMutableDictionary dictionary];
        [errorInfo setValue:NSLocalizedString(@"Please complete all required fields", nil) forKey:NSLocalizedDescriptionKey];
        return [NSError errorWithDomain:kErrorDomain code:0 userInfo:errorInfo];
    }
    
    return nil;
}
- (UAEvent *)saveEvent:(NSError **)error
{
    [self.view endEditing:YES];

    // Convert our input into the right units
    NSInteger unitSetting = [[NSUserDefaults standardUserDefaults] integerForKey:kBGTrackingUnitKey];
    if(unitSetting == BGTrackingUnitMG)
    {
        mgValue = value;
        
        double convertedValue = [[valueFormatter numberFromString:mgValue] doubleValue] * 0.0555;
        mmoValue = [NSString stringWithFormat:@"%f", convertedValue];
    }
    else
    {
        mmoValue = value;
        
        double convertedValue = round([[valueFormatter numberFromString:mmoValue] doubleValue] * 18.0182);
        mgValue = [NSString stringWithFormat:@"%f", convertedValue];
    }
    
    UAAccount *activeAccount = [[UAAccountController sharedInstance] activeAccount];
    if(activeAccount)
    {
        if(!reading)
        {
            NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"UAReading" inManagedObjectContext:self.moc];
            reading = (UAReading *)[[UAManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:self.moc];
            reading.filterType = [NSNumber numberWithInteger:ReadingFilterType];
            reading.account = activeAccount;
            reading.name = NSLocalizedString(@"Blood glucose level", nil);
        }
        reading.mmoValue = [NSNumber numberWithDouble:[[valueFormatter numberFromString:mmoValue] doubleValue]];
        reading.mgValue = [NSNumber numberWithDouble:[[valueFormatter numberFromString:mgValue] doubleValue]];
        reading.timestamp = self.date;
        
        if(!notes.length) notes = nil;
        reading.notes = notes;
        
        // Save our geotag data
        if(![self.lat isEqual:reading.lat] || ![self.lon isEqual:reading.lon])
        {
            reading.lat = self.lat;
            reading.lon = self.lon;
        }
        
        // Save our photo
        if(!self.currentPhotoPath || ![self.currentPhotoPath isEqualToString:reading.photoPath])
        {
            // If a photo already exists for this entry remove it now
            if(reading.photoPath)
            {
                [[UAMediaController sharedInstance] deleteImageWithFilename:reading.photoPath success:nil failure:nil];
            }
            
            reading.photoPath = self.currentPhotoPath;
        }
        
        NSArray *tags = [[UATagController sharedInstance] fetchTagsInString:notes];
        [[UATagController sharedInstance] assignTags:tags toEvent:reading];
        
        [self.moc save:&*error];
        return reading;
    }
    
    return nil;
}

// UI
- (void)changeDate:(id)sender
{
    self.date = [sender date];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    
    UAEventInputViewCell *cell = (UAEventInputViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    if(cell)
    {
        UITextField *textField = (UITextField *)cell.control;
        [textField setText:[dateFormatter stringFromDate:self.date]];
    }
}
- (void)configureAppearanceForTableViewCell:(UAEventInputViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [cell setDrawsBorder:YES];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if(indexPath.row == 0)
    {
        NSString *placeholder = [NSString stringWithFormat:@"%@ (mg/dL)", NSLocalizedString(@"BG level", @"Blood glucose level")];
        NSInteger units = [[NSUserDefaults standardUserDefaults] integerForKey:kBGTrackingUnitKey];
        if(units != BGTrackingUnitMG)
        {
            placeholder = [NSString stringWithFormat:@"%@ (mmoI/L)", NSLocalizedString(@"BG level", @"Blood glucose level")];
        }
        
        UITextField *textField = (UITextField *)cell.control;
        textField.placeholder = placeholder;
        textField.text = value;
        textField.keyboardType = UIKeyboardTypeDecimalPad;
        textField.delegate = self;
        textField.inputView = nil;
        
        [(UILabel *)[cell label] setText:NSLocalizedString(@"Value", nil)];
    }
    else if(indexPath.row == 1)
    {
        UITextField *textField = (UITextField *)cell.control;
        textField.placeholder = NSLocalizedString(@"Date", nil);
        textField.text = [dateFormatter stringFromDate:self.date];
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.keyboardType = UIKeyboardTypeAlphabet;
        textField.clearButtonMode = UITextFieldViewModeNever;
        textField.delegate = self;
        
        UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height+44, 320, 216)];
        [datePicker setDate:self.date];
        [datePicker setDatePickerMode:UIDatePickerModeDateAndTime];
        [datePicker addTarget:self action:@selector(changeDate:) forControlEvents:UIControlEventValueChanged];
        textField.inputView = datePicker;
        textField.inputAccessoryView = nil;
        
        [(UILabel *)[cell label] setText:NSLocalizedString(@"Date", nil)];
    }
    else if(indexPath.row == 2)
    {
        UANotesTextView *textView = (UANotesTextView *)cell.control;
        textView.text = notes;
        textView.delegate = self;
        textViewHeight = textView.contentSize.height;
        
        UAKeyboardAccessoryView *accessoryView = [[UAKeyboardAccessoryView alloc] initWithBackingView:parentVC.keyboardBackingView];
        self.autocompleteTagBar.frame = CGRectMake(0.0f, 0.0f, accessoryView.frame.size.width - parentVC.keyboardBackingView.controlContainer.frame.size.width, accessoryView.frame.size.height);
        [accessoryView.contentView addSubview:self.autocompleteTagBar];
        textView.inputAccessoryView = accessoryView;
        
        [(UILabel *)[cell label] setText:NSLocalizedString(@"Notes", nil)];
        [cell setDrawsBorder:NO];
    }
    
    cell.control.tag = indexPath.row;
}

#pragma mark - Social helpers
- (NSString *)facebookSocialMessageText
{
    if(value && [value length])
    {
        return [NSString stringWithFormat:NSLocalizedString(@"I just recorded a blood glucose reading of %@ with Diabetik", nil), value];
    }
    
    return [super twitterSocialMessageText];
}
- (NSString *)twitterSocialMessageText
{
    if(value && [value length])
    {
        return [NSString stringWithFormat:NSLocalizedString(@"I just recorded a blood glucose reading of %@ with @diabetikapp", nil), value];
    }
    
    return [super twitterSocialMessageText];
}

#pragma mark - UITableViewDatasource methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UAEventInputViewCell *cell = nil;
    if(indexPath.row == 2)
    {
        cell = (UAEventInputTextViewViewCell *)[aTableView dequeueReusableCellWithIdentifier:@"UAEventInputTextViewViewCell"];
        if (!cell)
        {
            cell = [[UAEventInputTextViewViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UAEventInputTextViewViewCell"];
        }
    }
    else
    {
        cell = (UAEventInputTextFieldViewCell *)[aTableView dequeueReusableCellWithIdentifier:@"UAEventTextFieldViewCell"];
        if (!cell)
        {
            cell = [[UAEventInputTextFieldViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UAEventTextFieldViewCell"];
        }
    }
    
    [self configureAppearanceForTableViewCell:cell atIndexPath:indexPath];
        
    return cell;
}
- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    float height = 0.0;
    if(indexPath.row == 2)
    {
        CGSize size = [notes sizeWithFont:[UAFont standardDemiBoldFontWithSize:16.0f] constrainedToSize:CGSizeMake(self.view.frame.size.width-85.0f, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
        height = textViewHeight > 0 ? textViewHeight : size.height + 80.0f;
    }
    else if(indexPath.row == 3)
    {
        height = 170.0f;
    }
    
    if(height < 44.0f) height = 44.0f;
    return height;
}

#pragma mark - UAAutocompleteBarDelegate methods
- (NSArray *)suggestionsForAutocompleteBar:(UAAutocompleteBar *)theAutocompleteBar
{
    if([theAutocompleteBar isEqual:self.autocompleteBar])
    {
        return [[UAEventController sharedInstance] fetchKey:@"name" forEventsWithFilterType:ReadingFilterType];
    }
    else
    {
        return [[UATagController sharedInstance] fetchAllTagsForAccount:[[UAAccountController sharedInstance] activeAccount]];
    }
    
    return nil;
}

#pragma mark - UITextFieldDelegate methods
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [super textFieldDidEndEditing:textField];
    
    if(textField.tag == 0)
    {
        value = textField.text;
    }
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if(textField.tag == 1)
    {
        return NO;
    }
    
    return YES;
}

@end
