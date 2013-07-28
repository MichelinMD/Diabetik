//
//  UAReportsViewController.m
//  Diabetik
//
//  Created by Nial Giacomelli on 18/05/2013.
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

#import "UAReportsViewController.h"
#import "UAReportPreviewView.h"
#import "UAAccountController.h"
#import "UADateButton.h"

#import "UABloodGlucoseChartViewController.h"
#import "UAAvgBloodGlucoseChartViewController.h"
#import "UACarbsChartViewController.h"
#import "UAScatterChartViewController.h"

@interface UAReportsViewController ()
{
    NSArray *reports;
    NSArray *reportData;
    
    NSDateFormatter *dateFormatter;
    NSDate *toDate, *fromDate;
    
    UADateButton *fromDateButton, *toDateButton;
    UILabel *dateRangeLabel, *dateRangeToLabel;
    UIScrollView *scrollView;
    UIPageControl *pageControl;
}
@property (nonatomic, strong) NSManagedObjectContext *moc;

@end

@implementation UAReportsViewController
@synthesize moc = _moc;

#pragma mark - Setup
- (id)initWithMOC:(NSManagedObjectContext *)moc fromDate:(NSDate *)aFromDate toDate:(NSDate *)aToDate;
{
    self = [super initWithNibName:nil bundle:nil];
    if(self)
    {
        _moc = moc;
        
        fromDate = aFromDate;
        toDate = aToDate;
        reportData = nil;
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        
        [self fetchReportData];
    }
    
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    reports = @[
                @{@"title": NSLocalizedString(@"Blood Glucose Readings", nil), @"description": NSLocalizedString(@"A line chart showing your blood glucose and general trend over a given period", nil), @"class": [UABloodGlucoseChartViewController class]},
                @{@"title": NSLocalizedString(@"Carbohydrate in-take", nil), @"description": NSLocalizedString(@"A stacked bar chart (segmented by morning, afternoon and evening) showing total carbohydrate in-take per day", nil), @"class": [UACarbsChartViewController class]},
                @{@"title": NSLocalizedString(@"Healthy Glucose Tally", nil), @"description": NSLocalizedString(@"A pie chart showing the number of healthy glucose readings versus unhealthy over a given period", nil), @"class": [UAScatterChartViewController class]}
                ];
    
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.pagingEnabled = YES;
    scrollView.delegate = self;
    scrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:scrollView];
    
    pageControl = [[UIPageControl alloc] initWithFrame:CGRectZero];
    pageControl.numberOfPages = [reports count];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
    {
        pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:69.0f/255.0f green:77.0f/255.0f blue:74.0f/255.0f alpha:0.4];
        pageControl.pageIndicatorTintColor = [UIColor colorWithRed:69.0f/255.0f green:77.0f/255.0f blue:74.0f/255.0f alpha:0.12];
    }
    [self.view addSubview:pageControl];
    
    CGFloat y = 25.0f;
    
    dateRangeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, y, 300.0f, 18.0f)];
    dateRangeLabel.backgroundColor = [UIColor clearColor];
    dateRangeLabel.textColor = [UIColor colorWithRed:115.0f/255.0f green:127.0f/255.0f blue:123.0f/255.0f alpha:1.0f];
    dateRangeLabel.font = [UAFont standardDemiBoldFontWithSize:14.0f];
    dateRangeLabel.text = NSLocalizedString(@"Reporting events between", nil);
    [self.view addSubview:dateRangeLabel];
    
    dateRangeToLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, y, 300.0f, 18.0f)];
    dateRangeToLabel.backgroundColor = [UIColor clearColor];
    dateRangeToLabel.textColor = [UIColor colorWithRed:115.0f/255.0f green:127.0f/255.0f blue:123.0f/255.0f alpha:1.0f];
    dateRangeToLabel.font = [UAFont standardDemiBoldFontWithSize:14.0f];
    dateRangeToLabel.text = NSLocalizedString(@"and", nil);
    [self.view addSubview:dateRangeToLabel];
    
    fromDateButton = [[UADateButton alloc] initWithFrame:CGRectMake(10.0f, y-6.0f, 100.0f, 30.0f)];
    [fromDateButton setTitle:[dateFormatter stringFromDate:fromDate] forState:UIControlStateNormal];
    [fromDateButton addTarget:self action:@selector(setDateForReportRange:) forControlEvents:UIControlEventTouchUpInside];
    [fromDateButton setTag:0];
    [self.view addSubview:fromDateButton];
    
    toDateButton = [[UADateButton alloc] initWithFrame:CGRectMake(10.0f, y-6.0f, 100.0f, 30.0f)];
    [toDateButton setTitle:[dateFormatter stringFromDate:toDate] forState:UIControlStateNormal];
    [toDateButton addTarget:self action:@selector(setDateForReportRange:) forControlEvents:UIControlEventTouchUpInside];
    [toDateButton setTag:1];
    [self.view addSubview:toDateButton];
    
    for(NSInteger i = 0; i < [reports count]; i++)
    {
        NSDictionary *info = [reports objectAtIndex:i];
        
        UAReportPreviewView *reportPreview = [[UAReportPreviewView alloc] initWithFrame:CGRectZero andInfo:info];
        [reportPreview setTag:i];
        [reportPreview addTarget:self action:@selector(didSelectReport:) forControlEvents:UIControlEventTouchUpInside];
        [scrollView addSubview:reportPreview];
    }
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ReportsBackground.png"]];
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    CGFloat x = 0.0f;
    for(UIView *view in scrollView.subviews)
    {
        view.frame = CGRectMake(x + (self.view.bounds.size.width/2.0f - 304.0f/2.0f), self.view.bounds.size.height/2.0f - 154.0f/2.0f, 304.0f, 154.0f);
        
        x += self.view.bounds.size.width;
    }
    
    scrollView.contentSize = CGSizeMake(self.view.bounds.size.width*[reports count], self.view.bounds.size.height);
    pageControl.frame = CGRectMake(0.0f, self.view.bounds.size.height - 45.0f, self.view.bounds.size.width, 25.0f);
    
    NSInteger reportKey = [[NSUserDefaults standardUserDefaults] integerForKey:kReportsDefaultKey];
    if(reportKey < 0) reportKey = 0;
    if(reportKey > [reports count]-1) reportKey = [reports count]-1;
    
    [scrollView setContentOffset:CGPointMake(self.view.bounds.size.width*reportKey, 0.0f) animated:NO];
    [pageControl setCurrentPage:reportKey];
    
    NSDictionary *chartInfo = [reports objectAtIndex:reportKey];
    if(chartInfo)
    {
        Class chartClass = (Class)[chartInfo objectForKey:@"class"];
        UAChartViewController *chartVC = [(UAChartViewController *)[chartClass alloc] initWithData:reportData];
        chartVC.view.frame = self.view.bounds;
        
        for(UIView *subview in scrollView.subviews)
        {
            if(subview.tag == reportKey)
            {
                chartVC.initialRect = [scrollView convertRect:subview.frame toView:self.view];
                break;
            }
        }
        if([chartVC hasEnoughDataToShowChart])
        {
            [chartVC willMoveToParentViewController:self];
            [self addChildViewController:chartVC];
            chartVC.view.bounds = self.view.bounds;
            chartVC.chart.alpha = 1.0f;
            [self.view addSubview:chartVC.view];
            [chartVC didMoveToParentViewController:self];
        }
    }
}
- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    fromDateButton.frame = CGRectMake(fromDateButton.frame.origin.x, fromDateButton.frame.origin.y, [fromDateButton.titleLabel.text sizeWithFont:fromDateButton.titleLabel.font].width+20.0f, fromDateButton.frame.size.height);
    toDateButton.frame = CGRectMake(toDateButton.frame.origin.x, toDateButton.frame.origin.y, [toDateButton.titleLabel.text sizeWithFont:toDateButton.titleLabel.font].width+20.0f, toDateButton.frame.size.height);
    
    CGFloat width = [dateRangeLabel.text sizeWithFont:dateRangeLabel.font].width;
    width += 5.0f + fromDateButton.bounds.size.width;
    width += 5.0f + [dateRangeToLabel.text sizeWithFont:dateRangeToLabel.font].width;
    width += 5.0f + toDateButton.bounds.size.width;
    
    CGFloat x = self.view.bounds.size.width/2.0f - width/2.0f;
    dateRangeLabel.frame = CGRectMake(x, dateRangeLabel.frame.origin.y, [dateRangeLabel.text sizeWithFont:dateRangeLabel.font].width, dateRangeLabel.frame.size.height);
    
    x += dateRangeLabel.bounds.size.width + 5.0f;
    fromDateButton.frame = CGRectMake(x, fromDateButton.frame.origin.y, fromDateButton.frame.size.width, fromDateButton.frame.size.height);
    
    x += fromDateButton.bounds.size.width + 5.0f;
    dateRangeToLabel.frame = CGRectMake(x, dateRangeToLabel.frame.origin.y, [dateRangeToLabel.text sizeWithFont:dateRangeToLabel.font].width, dateRangeToLabel.frame.size.height);
    
    x += dateRangeToLabel.bounds.size.width + 5.0f;
    toDateButton.frame = CGRectMake(x, toDateButton.frame.origin.y, toDateButton.frame.size.width, toDateButton.frame.size.height);
}

#pragma mark - Logic
- (void)fetchReportData
{
    NSDate *fetchFromDate = [fromDate dateAtStartOfDay];
    NSDate *fetchToDate = [toDate dateAtEndOfDay];
    
    if(fetchFromDate)
    {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"UAEvent" inManagedObjectContext:self.moc];
        [fetchRequest setEntity:entity];
        [fetchRequest setFetchBatchSize:20];
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
        NSArray *sortDescriptors = @[sortDescriptor];
        [fetchRequest setSortDescriptors:sortDescriptors];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"timestamp >= %@ && timestamp <= %@ && account = %@", fetchFromDate, fetchToDate, [[UAAccountController sharedInstance] activeAccount]]];
        
        NSError *error = nil;
        reportData = [self.moc executeFetchRequest:fetchRequest error:&error];
        
        if(error)
        {
            reportData = nil;
        }
    }
}
- (void)didSelectReport:(UIButton *)previewButton
{
    [[VKRSAppSoundPlayer sharedInstance] playSound:@"tap-significant"];
    
    NSDictionary *chartInfo = [reports objectAtIndex:previewButton.tag];
    if(chartInfo)
    {
        CGRect initialRect = [scrollView convertRect:previewButton.frame toView:self.view];
        
        Class chartClass = (Class)[chartInfo objectForKey:@"class"];
        UAChartViewController *chartVC = [(UAChartViewController *)[chartClass alloc] initWithData:reportData];
        chartVC.view.frame = initialRect;
        chartVC.initialRect = initialRect;
        
        if([chartVC hasEnoughDataToShowChart])
        {
            [chartVC willMoveToParentViewController:self];
            [self addChildViewController:chartVC];
            chartVC.chart.alpha = 0.0f;        
            [self.view addSubview:chartVC.view];
            
            [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                chartVC.view.bounds = self.view.bounds;
                chartVC.chart.alpha = 1.0f;
            } completion:^(BOOL finished) {
                [chartVC didMoveToParentViewController:self];
            }];
            
            [[NSUserDefaults standardUserDefaults] setInteger:previewButton.tag forKey:kReportsDefaultKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        else
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Not enough data", nil) message:NSLocalizedString(@"You haven't collected enough data to display this report", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Okay", nil) otherButtonTitles:nil];
            [alertView show];
        }
    }
}
- (void)setDateForReportRange:(UIButton *)sender
{
    [[VKRSAppSoundPlayer sharedInstance] playSound:@"tap-significant"];
    
    UADatePickerController *datePicker = [[UADatePickerController alloc] initWithFrame:self.view.bounds andDate:(sender.tag == 0 ? fromDate : toDate)];
    datePicker.delegate = self;
    datePicker.tag = sender.tag;
    [datePicker present];
    [self.view addSubview:datePicker];
}

#pragma mark - UADatePickerDelegate methods
- (void)datePicker:(UADatePickerController *)controller didSelectDate:(NSDate *)date
{
    [[VKRSAppSoundPlayer sharedInstance] playSound:@"success"];
    
    if(controller.tag == 0)
    {
        fromDate = date;
        [fromDateButton setTitle:[dateFormatter stringFromDate:fromDate] forState:UIControlStateNormal];
    }
    else
    {
        toDate = date;
        [toDateButton setTitle:[dateFormatter stringFromDate:toDate] forState:UIControlStateNormal];
    }
    
    [self.view setNeedsLayout];
    [self fetchReportData];
}

#pragma mark - UIScrollViewDelegate methods
- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView
{
    NSInteger page = aScrollView.contentOffset.x/self.view.bounds.size.width;
    if(page < 0) page = 0;
    if(page > [reports count]) page = [reports count];
    
    pageControl.currentPage = page;
}

#pragma mark - Autorotation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}
- (BOOL)shouldAutorotate
{
    return YES;
}
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if(UIInterfaceOrientationIsPortrait(toInterfaceOrientation))
    {
        if([self.delegate shouldDismissReportsOnRotation:self])
        {
            [self dismissViewControllerAnimated:NO completion:^{
                [self.delegate didDismissReportsController:self];
            }];
        }
    }
}

@end
