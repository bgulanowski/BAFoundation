//
//  NSEntityDescription+BAAdditions.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 2014-04-21.
//  Copyright (c) 2014 Bored Astronaut. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSEntityDescription (BAAdditions)

- (NSString *)defaultSortKey;
- (NSArray *)defaultSortDescriptors;
- (NSFetchRequest *)defaultFetchRequest;

@end
