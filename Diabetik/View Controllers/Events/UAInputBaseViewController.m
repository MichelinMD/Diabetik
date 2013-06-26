//
//  UAInputBaseViewController.m
//  Diabetik
//
//  Created by Nial Giacomelli on 21/04/2013.
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

#import "UAInputBaseViewController.h"
#import "UALocationController.h"
#import "UAEventMapViewController.h"
#import "UAImageViewController.h"

@implementation UAInputBaseViewController
@synthesize event = _event;
@synthesize moc = _moc;

#pragma mark - Setup
- (id)initWithMOC:(NSManagedObjectContext *)aMOC
{
    self = [super init];
    if (self)
    {
        _moc = aMOC;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasShown:)
                                                     name:UIKeyboardDidShowNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillBeShown:)
                                                     name:UIKeyboardWillShowNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillBeHidden:)
                                                     name:UIKeyboardWillHideNotification object:nil];
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
        usingSmartInput = NO;
        self.currentPhotoPath = nil;
        self.lat = nil, self.lon = nil;
        self.date = [NSDate date];
        
        self.autocompleteBar = [[UAAutocompleteBar alloc] initWithFrame:CGRectMake(0, 0, 235, 44)];
        self.autocompleteBar.showTagButton = NO;
        self.autocompleteBar.delegate = self;
        self.autocompleteTagBar = [[UAAutocompleteBar alloc] initWithFrame:CGRectMake(0, 0, 235, 44)];
        self.autocompleteTagBar.showTagButton = YES;
        self.autocompleteTagBar.delegate = self;
    }
    return self;
}
- (id)initWithEvent:(UAEvent *)aEvent andMOC:(NSManagedObjectContext *)aMOC
{
    _event = aEvent;
    _moc = aMOC;
    
    self = [self initWithMOC:aMOC];
    if(self)
    {
        self.date = self.event.timestamp;
        notes = self.event.notes;
        self.currentPhotoPath = self.event.photoPath;
        self.lat = self.event.lat;
        self.lon = self.event.lon;
    }
    
    return self;
}
- (void)loadView
{
    UIView *baseView = [[UIView alloc] initWithFrame:CGRectZero];
    baseView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.tableView = [[UITableView alloc] initWithFrame:baseView.frame style:tableStyle];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = nil;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = [UIColor colorWithRed:189.0f/255.0f green:189.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, kAccessoryViewHeight, 0);
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 48.0f, 0);
    [baseView addSubview:self.tableView];
    
    self.view = baseView;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor clearColor]; //[UIColor colorWithRed:247.0f/255.0f green:250.0f/255.0f blue:249.0f/255.0f alpha:1.0f];
    self.view.backgroundColor = [UIColor colorWithRed:247.0f/255.0f green:250.0f/255.0f blue:249.0f/255.0f alpha:1.0f];
    self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    
    [self.tableView reloadData];
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    BOOL editMode = self.event ? NO : YES;
    if(!isFirstLoad)
    {
        editMode = NO;
    }
    
    [self didBecomeActive:editMode];
}

#pragma mark - Logic
- (NSError *)validationError
{
    return nil;
}
- (UAEvent *)saveEvent:(NSError **)error
{
    return nil;
}
- (void)discardChanges
{
    // Remove any existing photo (provided it's not our original photo)
    if(self.currentPhotoPath && (!self.event || (self.event && ![self.event.photoPath isEqualToString:self.currentPhotoPath])))
    {
        [[UAMediaController sharedInstance] deleteImageWithFilename:self.currentPhotoPath success:nil failure:nil];
    }
}
- (void)triggerDeleteEvent:(id)sender
{
    [self.view endEditing:YES];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Entry", nil)
                                                        message:NSLocalizedString(@"Are you sure you'd like to permanently delete this entry?", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"No", nil)
                                              otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];
    alertView.tag = kDeleteAlertViewTag;
    [alertView show];
}
- (void)deleteEvent
{
    NSError *error = nil;
    if(self.event)
    {
        [self.moc deleteObject:self.event];
        [self.moc save:&error];
    }
    
    if(!error)
    {
        [self discardChanges];
    
        [[VKRSAppSoundPlayer sharedInstance] playSound:@"success"];
        if([parentVC.viewControllers count] == 1)
        {
            [self handleBack:self withSound:NO];
        }
        else
        {
            [parentVC removeVC:self];
        }
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Uh oh!", nil)
                                                            message:[NSString stringWithFormat:NSLocalizedString(@"There was an error while trying to delete this event: %@", nil), [error localizedDescription]]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Okay", nil)
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

#pragma mark - UI
- (void)didBecomeActive:(BOOL)editing
{
    [parentVC updateKeyboardButtons];
    UAEventInputViewCell *cell = (UAEventInputViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    // Select our first input field
    if(editing)
    {
        [cell.control becomeFirstResponder];
    }

    self.previouslyActiveControlIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
}
- (void)willBecomeInactive
{
    isFirstLoad = NO;
    [self finishEditing:self];
}
- (void)finishEditing:(id)sender
{
    [self.view endEditing:YES];
}
- (void)nextField:(UITextField *)sender
{
    UAEventInputViewCell *cell = (UAEventInputViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:sender.tag+1 inSection:0]];
    [cell.control becomeFirstResponder];
}

#pragma mark - Social helpers
- (NSString *)facebookSocialMessageText
{
    return NSLocalizedString(@"I love Diabetik! It's a great way to track my diabetes.", nil);
}
- (NSString *)twitterSocialMessageText
{
    return NSLocalizedString(@"I love @diabetikapp! It's a great way to track my diabetes.", nil);
}

#pragma mark - UITableViewDelegate methods
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UAEventInputViewCell *cell = (UAEventInputViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    if([cell respondsToSelector:@selector(control)])
    {
        [cell.control becomeFirstResponder];
    }
}

#pragma mark - UITextViewDelegate
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.activeControlIndexPath = [NSIndexPath indexPathForRow:textView.tag inSection:0];
    
    //NSIndexPath *indexPath = [self.tableView indexPathForCell:(UAEventInputViewCell *)[[textView superview] superview]];
    //[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
}
- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.activeControlIndexPath = nil;
    self.previouslyActiveControlIndexPath = [NSIndexPath indexPathForRow:textView.tag inSection:0];
}
- (void)textViewDidChange:(UITextView *)textView
{
    // Determine whether we're current in tag 'edit mode'
    NSUInteger caretLocation = [textView offsetFromPosition:textView.beginningOfDocument toPosition:textView.selectedTextRange.start];
    NSRange range = [[UATagController sharedInstance] rangeOfTagInString:textView.text withCaretLocation:caretLocation];
    if(range.location != NSNotFound)
    {
        NSString *currentTag = [textView.text substringWithRange:range];
        currentTag = [currentTag substringFromIndex:1];
        [self.autocompleteTagBar showSuggestionsForInput:currentTag];
    }
    else
    {
        [self.autocompleteTagBar showSuggestionsForInput:nil];
    }
    
    // Update values
    textViewHeight = textView.contentSize.height;
    notes = textView.text;
    
    // Finally, update our tableview
    [UIView setAnimationsEnabled:NO];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    [UIView setAnimationsEnabled:YES];
    
    //NSIndexPath *indexPath = [self.tableView indexPathForCell:(UAEventInputViewCell *)[[textView superview] superview]];
    //[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    //[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:textView.tag inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeControlIndexPath = [NSIndexPath indexPathForRow:textField.tag inSection:0];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:textField.tag inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.previouslyActiveControlIndexPath = [NSIndexPath indexPathForRow:textField.tag inSection:0];
    self.activeControlIndexPath = nil;
}

#pragma mark - UAAutocompleteBarDelegate methods
- (NSArray *)suggestionsForAutocompleteBar:(UAAutocompleteBar *)autocompleteBar
{
    return nil;
}
- (void)didSelectAutocompleteSuggestion:(NSString *)suggestion
{
    [self.tableView scrollToRowAtIndexPath:self.activeControlIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    
    UAEventInputViewCell *cell = (UAEventInputViewCell *)[self.tableView cellForRowAtIndexPath:self.activeControlIndexPath];
    if([cell.control isKindOfClass:[UITextField class]])
    {
        UITextField *activeTextField = (UITextField *)cell.control;
        activeTextField.text = suggestion;
    }
    else if([cell.control isKindOfClass:[UITextView class]])
    {
        UITextView *textView = (UITextView *)cell.control;
        
        NSUInteger caretLocation = [textView offsetFromPosition:textView.beginningOfDocument toPosition:textView.selectedTextRange.start];
        NSRange range = [[UATagController sharedInstance] rangeOfTagInString:textView.text withCaretLocation:caretLocation];
        if(range.location != NSNotFound)
        {
            // Only pad our new tag with a space if it's not the end of our note and there isn't already a space following it
            if(range.location + range.length >= textView.text.length || [[textView.text substringWithRange:NSMakeRange(range.location+range.length, 1)] isEqualToString:@" "])
            {
                textView.text = [textView.text stringByReplacingCharactersInRange:NSMakeRange(range.location+1, range.length-1) withString:suggestion];
            }
            else
            {
                textView.text = [textView.text stringByReplacingCharactersInRange:NSMakeRange(range.location+1, range.length-1) withString:[NSString stringWithFormat:@"%@ ", suggestion]];
            }
            
            textViewHeight = textView.contentSize.height;
            notes = textView.text;
            
            //[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}
- (void)addTagCaret
{
    UAEventInputViewCell *cell = (UAEventInputViewCell *)[self.tableView cellForRowAtIndexPath:self.activeControlIndexPath];
    
    if(!cell)
    {
        [self.tableView scrollToRowAtIndexPath:self.activeControlIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    }
    cell = (UAEventInputViewCell *)[self.tableView cellForRowAtIndexPath:self.activeControlIndexPath];
    
    UITextField *activeTextField = (UITextField *)cell.control;
    activeTextField.text = [activeTextField.text stringByAppendingString:@"#"];
}

#pragma mark - Metadata management
- (void)requestCurrentLocation
{    
    parentVC.locationButton.titleLabel.alpha = 0.0f;
    parentVC.locationButton.imageView.alpha = 0.0f;
    [parentVC.locationButton.activityIndicatorView startAnimating];
    
    [[UALocationController sharedInstance] fetchUserLocationWithSuccess:^(CLLocation *location) {
        self.lat = [NSNumber numberWithDouble:location.coordinate.latitude];
        self.lon = [NSNumber numberWithDouble:location.coordinate.longitude];
        
        [parentVC updateKeyboardButtons];
        [parentVC.locationButton.activityIndicatorView stopAnimating];
        parentVC.locationButton.titleLabel.alpha = 1.0f;
        parentVC.locationButton.imageView.alpha = 1.0f;
        
    } failure:^(NSError *error) {
        [parentVC.locationButton.activityIndicatorView stopAnimating];
        parentVC.locationButton.titleLabel.alpha = 1.0f;
        parentVC.locationButton.imageView.alpha = 1.0f;
    }];
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];
    self.lat = [NSNumber numberWithDouble:location.coordinate.latitude];
    self.lon = [NSNumber numberWithDouble:location.coordinate.longitude];
    
    [manager stopUpdatingLocation];
    [parentVC updateKeyboardButtons];
}
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [manager stopUpdatingLocation];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == kDeleteAlertViewTag && buttonIndex == 1)
    {
        [self deleteEvent];
    }
    else if(alertView.tag == kGeoTagAlertViewTag && buttonIndex == 1)
    {
        [self requestCurrentLocation];
    }
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(actionSheet.tag == kGeotagActionSheetTag)
    {
        if(buttonIndex == actionSheet.destructiveButtonIndex)
        {
            self.lat = nil, self.lon = nil;
            self.event.lat = nil, self.event.lon = nil;
            
            [parentVC updateKeyboardButtons];
        }
        else if(buttonIndex == 1)
        {
            CLLocation *location = [[CLLocation alloc] initWithLatitude:[self.lat doubleValue] longitude:[self.lon doubleValue]];
            UAEventMapViewController *vc = [[UAEventMapViewController alloc] initWithLocation:location];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else if(buttonIndex == 2)
        {
            [self requestCurrentLocation];
        }
    }
    else
    {
        if(!imagePickerController)
        {
            imagePickerController = [[UIImagePickerController alloc] init];
            imagePickerController.delegate = self;
        }
        
        if(actionSheet.tag == kExistingImageActionSheetTag)
        {
            if(buttonIndex == actionSheet.destructiveButtonIndex)
            {
                self.event.photoPath = nil, self.currentPhotoPath = nil;
                
                [parentVC updateKeyboardButtons];
            }
            else if(buttonIndex == 1)
            {
                UIImage *image = [[UAMediaController sharedInstance] imageWithFilename:self.currentPhotoPath];
                if(image)
                {
                    /*UAImageViewController *vc = [[UAImageViewController alloc] initWithImage:image];
                    vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
                    vc.modalPresentationStyle = UIModalPresentationFormSheet;
                    [self.parentViewController.parentViewController presentViewController:vc animated:YES completion:^{
                        // STUB
                    }];*/
                    
                    CGRect originalButtonFrame = [(UAInputParentViewController *)self.parentViewController photoButton].frame;
                    CGRect photoButtonFrame = [[(UAInputParentViewController *)self.parentViewController keyboardBackingView] convertRect:originalButtonFrame toView:self.parentViewController.parentViewController.view];
                    UAImageViewController *vc = [[UAImageViewController alloc] initWithImage:image];
                    [self.parentViewController.parentViewController addChildViewController:vc];
                    [self.parentViewController.parentViewController.view addSubview:vc.view];
                    [vc presentFromRect:photoButtonFrame];
                    
                    [vc didMoveToParentViewController:self.parentViewController.parentViewController];
                }
            }
            else if(buttonIndex == 2)
            {
                imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
            }
            else if(buttonIndex == 3)
            {
                imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            }
            
            if(buttonIndex == 2 || buttonIndex == 3)
            {
                [self.navigationController presentViewController:imagePickerController animated:YES completion:^{
                    // STUB
                }];
            }
        }
        else
        {
            if(buttonIndex == 0)
            {
                imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
            }
            else if(buttonIndex == 1)
            {
                imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            }
            
            if(buttonIndex != actionSheet.cancelButtonIndex)
            {
                [self.navigationController presentViewController:imagePickerController animated:YES completion:^{
                    // STUB
                }];
            }
        }
    }
}

#pragma mark - UINavigationControllerDelegate
- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    
    if ([navigationController isKindOfClass:[UIImagePickerController class]] &&
        ((UIImagePickerController *)navigationController).sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
        //[[UIApplication sharedApplication] setStatusBarHidden:NO];
        //[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
    }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if(!image)
    {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    if(!image)
    {
        image = [info objectForKey:UIImagePickerControllerCropRect];
    }
    
    if(image)
    {
        NSTimeInterval timestamp = [NSDate timeIntervalSinceReferenceDate];
        NSString *filename = [NSString stringWithFormat:@"%d", (NSInteger)timestamp];
        
        __weak typeof(self) weakSelf = self;
        [[UAMediaController sharedInstance] saveImage:image withFilename:filename success:^{
            
            // Remove any existing photo (provided it's not our original photo)
            if(weakSelf.currentPhotoPath && (!weakSelf.event || (weakSelf.event && ![weakSelf.event.photoPath isEqualToString:weakSelf.currentPhotoPath])))
            {
                [[UAMediaController sharedInstance] deleteImageWithFilename:weakSelf.currentPhotoPath success:nil failure:nil];
            }
            
            weakSelf.currentPhotoPath = filename;
            
            [parentVC updateKeyboardButtons];
            
        } failure:^(NSError *error) {
            NSLog(@"Image failed with filename: %@. Error: %@", filename, error);
        }];
    }
}

#pragma mark - Notifications
- (void)keyboardWasShown:(NSNotification*)aNotification
{
}
- (void)keyboardWillBeShown:(NSNotification *)aNotification
{
    [parentVC.keyboardBackingView setKeyboardState:kKeyboardShown];
}
- (void)keyboardWillBeHidden:(NSNotification *)aNotification
{    
    [parentVC.keyboardBackingView setKeyboardState:kKeyboardHidden];
}


#pragma mark - UINavigationController
- (void)didMoveToParentViewController:(UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
    
    parentVC = (UAInputParentViewController *)parent;
}

@end
