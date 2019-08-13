//
//  NSObject+RCProperty.h
//  Property
//
//  Created by sebarina on 2019/8/12.
//  Copyright © 2019 Alibaba. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (RCProperty) <NSCopying>
- (id)rc_valueForKey:(NSString*)key;
- (void)rc_setValue:(id)value forKey:(NSString*)key;
@end

NS_ASSUME_NONNULL_END
