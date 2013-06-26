//
//  UAAutocompleteBar.m
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

#import "UAHelper.h"
#import "UAAutocompleteBar.h"
#import "UAAutocompleteBarButton.h"

@interface UAAutocompleteBar ()
- (void)buttonPressed:(UIButton *)sender;
@end

@implementation UAAutocompleteBar
@synthesize showTagButton = _showTagButton;

#pragma mark - Setup
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width - 12.0f, frame.size.height)];
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.alwaysBounceHorizontal = YES;
        scrollView.directionalLockEnabled = YES;
        [self addSubview:scrollView];
        
        self.backgroundColor = [UIColor clearColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
        self.suggestions = nil;
        
        tagButton = [[UAAutocompleteBarButton alloc] initWithFrame:CGRectMake(10.0f, 10.0f, 40.0f, 29.0f)];
        [tagButton setImage:[UIImage imageNamed:@"AccessoryViewIconTag.png"] forState:UIControlStateNormal];
        [tagButton addTarget:self action:@selector(addTag:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:tagButton];
        
        buttons = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Logic
- (void)showSuggestionsForInput:(NSString *)input
{
    if(input || !self.showTagButton)
    {
        tagButton.hidden = YES;
    }
    else
    {
        tagButton.hidden = NO;
    }
    
    // Lazy-load from our datasource if necessary
    if(input && !self.suggestions)
    {
        [self fetchSuggestions];
    }
    
    // Remove previous suggestions
    if([buttons count])
    {
        for(UIView *view in scrollView.subviews)
        {
            [view removeFromSuperview];
        }
        [buttons removeAllObjects];
    }
    
    // Don't bother re-populating our options if we're not searching for anything
    if(!input) return;
    
    // Generate new suggestions
    if(input && [input length])
    {
        NSString *lowercaseInput = [input lowercaseString];

        // Generate new suggestions
        CGFloat x = 10.0f;
        CGFloat margin = 5.0f;
        for(NSString *suggestion in self.suggestions)
        {
            // Determine whether this word is valid for the input'd text
            NSString *lowercaseSuggestions = [suggestion lowercaseString];
            if([lowercaseSuggestions hasPrefix:lowercaseInput] && ![lowercaseSuggestions isEqualToString:lowercaseInput])
            {
                UAAutocompleteBarButton *button = [[UAAutocompleteBarButton alloc] initWithFrame:CGRectMake(x, 10.0f, 0.0f, 29.0f)];
                [button setTitle:suggestion forState:UIControlStateNormal];
                [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
                
                [scrollView addSubview:button];
                [buttons addObject:button];
                
                x += button.frame.size.width + margin;
            }
        }
        
        scrollView.contentOffset = CGPointMake(0.0f, 0.0f);
        scrollView.contentSize = CGSizeMake(x, 45.0f);
    }
}
- (void)fetchSuggestions
{
    self.suggestions = [self.delegate suggestionsForAutocompleteBar:self];
}
- (void)setShowTagButton:(BOOL)state
{
    _showTagButton = state;
    
    [tagButton setHidden:!_showTagButton];
}
- (void)addTag:(UIButton *)sender
{
    [self.delegate addTagCaret];
    [self showSuggestionsForInput:@""];
}
- (void)buttonPressed:(UIButton *)sender
{
    if([self.delegate respondsToSelector:@selector(didSelectAutocompleteSuggestion:)])
    {
        NSString *suggestion = [sender titleForState:UIControlStateNormal];
        [self.delegate performSelector:@selector(didSelectAutocompleteSuggestion:) withObject:suggestion];
        
        [self showSuggestionsForInput:@""];
    }
}

@end
