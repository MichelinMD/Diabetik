//
//  UAPDFDocument.m
//  Diabetik
//
//  Created by Nial Giacomelli on 13/04/2013.
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

#import "UAPDFDocument.h"

#define kTableCellPadding 5.0f

@implementation UAPDFDocument
@synthesize contentFrame = _contentFrame;

#pragma mark - Setup
- (id)init
{
    self = [super init];
    if(self)
    {
        self.pageFrame = CGRectMake(0, 0, 612, 792);
        self.contentFrame = CGRectMake(45, 39, 512, 714);
        
        self.pageCount = 1;
        self.data = [[NSMutableData alloc] init];
        
        UIGraphicsBeginPDFContextToData(self.data, CGRectZero, nil);
        [self createNewPage];
    }
    
    return self;
}

#pragma mark - Logic
- (void)close
{
    UIGraphicsEndPDFContext();
}
- (void)createNewPage
{
    UIGraphicsBeginPDFPageWithInfo(self.pageFrame, nil);
    
    [[NSString stringWithFormat:@"%d", self.pageCount] drawInRect:CGRectMake(self.pageFrame.origin.x, self.pageFrame.origin.y + self.pageFrame.size.height - 32.0f, self.pageFrame.size.width, 32.0f)
                                                         withFont:[UAFont standardDemiBoldFontWithSize:10.0f]
                                                    lineBreakMode:NSLineBreakByClipping
                                                        alignment:NSTextAlignmentCenter];
    
    self.pageCount ++;
}

#pragma mark - Rendering
- (void)drawImage:(UIImage *)image
       atPosition:(CGPoint)position
{
    [image drawAtPoint:position];
    
    self.currentY = position.y + image.size.height;
}
- (void)drawTableWithRows:(NSArray *)rows
               andColumns:(NSArray *)columns
               atPosition:(CGPoint)position
                    width:(CGFloat)tableWidth
               identifier:(NSString *)identifier
{
    CGFloat x = position.x, y = position.y;
    
    NSMutableArray *headerTitles = [NSMutableArray array];
    for(NSDictionary *column in columns)
    {
        [headerTitles addObject:[column objectForKey:@"title"]];
    }
    
    UIFont *headerFont = [self.delegate fontForPDFTableInDocument:self withIdentifier:identifier forRow:0];
    CGFloat headerHeight = [self maximumHeightForRow:headerTitles andColumns:columns atPosition:position width:tableWidth withFont:headerFont];
    
    // Make sure our header won't push us onto a new page
    if((y + headerHeight) > CGRectGetMaxY(self.contentFrame))
    {
        [self createNewPage];
        y = self.contentFrame.origin.y;
    }
    
    for(NSDictionary *column in columns)
    {
        double columnWidthPercentage = [[column objectForKey:@"width"] doubleValue];
        double columnSize = (tableWidth/100)*columnWidthPercentage;
        
        NSString *headerTitle = [column objectForKey:@"title"];
        
        [self.delegate drawPDFTableHeaderInDocument:self
                                     withIdentifier:identifier
                                            content:headerTitle
                                        contentRect:CGRectMake(x+kTableCellPadding, y+kTableCellPadding, columnSize-(kTableCellPadding*2), headerHeight-(kTableCellPadding*2))
                                           cellRect:CGRectMake(x, y, columnSize, headerHeight)];
        
        x += columnSize;
    }
    y += headerHeight;
    
    NSInteger columnIndex = 0, rowIndex = 1;
    for(NSArray *row in rows)
    {
        UIFont *rowFont = [self.delegate fontForPDFTableInDocument:self withIdentifier:identifier forRow:rowIndex];
        CGFloat rowHeight = [self maximumHeightForRow:row andColumns:columns atPosition:CGPointMake(position.x, y) width:tableWidth withFont:rowFont];
        
        x = position.x;
        
        // Make sure our header won't push us onto a new page
        if((y + rowHeight) > CGRectGetMaxY(self.contentFrame))
        {
            [self createNewPage];
            y = self.contentFrame.origin.y;
        }
        
        for(NSDictionary *column in columns)
        {
            double columnWidthPercentage = [[column objectForKey:@"width"] doubleValue];
            double columnSize = (tableWidth/100)*columnWidthPercentage;
            
            NSString *data = [row objectAtIndex:columnIndex];
            [self.delegate drawPDFTableCellInDocument:self
                                       withIdentifier:identifier
                                              content:data
                                          contentRect:CGRectMake(x+kTableCellPadding, y+kTableCellPadding, columnSize-(kTableCellPadding*2), rowHeight-(kTableCellPadding*2))
                                             cellRect:CGRectMake(x, y, columnSize, rowHeight)
                                         cellPosition:CGPointMake(columnIndex, rowIndex-1)];
            
            x += columnSize;
            columnIndex ++;
        }
        y += rowHeight;
        columnIndex = 0;
        rowIndex ++;
    }
}
- (CGFloat)maximumHeightForRow:(NSArray *)row andColumns:(NSArray *)columns atPosition:(CGPoint)position width:(CGFloat)tableWidth withFont:(UIFont *)font
{
    CGFloat height = 0.0f;
    for(NSDictionary *column in columns)
    {
        double columnWidthPercentage = [[column objectForKey:@"width"] doubleValue];
        double columnSize = (tableWidth/100)*columnWidthPercentage;
        
        for(NSString *data in row)
        {
            CGSize cellSize = [data sizeWithFont:font constrainedToSize:CGSizeMake(columnSize-kTableCellPadding*2, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
            if(cellSize.height > height) height = cellSize.height+kTableCellPadding*2;
        }
    }
    
    return height;
}
- (void)drawText:(NSString *)string
      atPosition:(CGPoint)position
        withFont:(UIFont *)font
{
    CGSize textSize = [string sizeWithFont:font constrainedToSize:CGSizeMake(CGRectGetMaxX(self.contentFrame) - position.x, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    CGRect textFrame = CGRectMake(position.x, position.y, textSize.width, textSize.height);
    
    [self drawText:string inRect:textFrame withFont:font alignment:NSTextAlignmentLeft lineBreakMode:NSLineBreakByWordWrapping];
}
- (void)drawText:(NSString *)string
          inRect:(CGRect)rect
        withFont:(UIFont *)font
       alignment:(NSTextAlignment)alignment
   lineBreakMode:(UILineBreakMode)lineBreakMode
{
    // Will this spill over onto a new page?
    if(CGRectGetMaxY(rect) > CGRectGetMaxY(self.contentFrame))
    {
        [self createNewPage];
        
        rect.origin.y = self.currentY = self.contentFrame.origin.y;
    }
    else
    {
        self.currentY = rect.origin.y;
    }
    
    // Render our text
    [string drawInRect:rect withFont:font lineBreakMode:lineBreakMode alignment:alignment];
    
    self.currentY += rect.size.height;
}

#pragma mark - Accessors
- (void)setContentFrame:(CGRect)newFrame
{
    _contentFrame = newFrame;
    
    self.currentY = CGRectGetMinY(_contentFrame);
}

@end
