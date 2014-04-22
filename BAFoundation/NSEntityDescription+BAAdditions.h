//
//  NSEntityDescription+BAAdditions.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 2014-04-21.
//  Copyright (c) 2014 Marketcircle Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSEntityDescription (BAAdditions)

- (NSString *)defaultSortKey;
- (NSArray *)defaultSortDescriptors;
- (NSFetchRequest *)defaultFetchRequest;

@end
