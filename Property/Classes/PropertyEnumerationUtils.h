//
//  PropertyEnumerationUtils.h
//  Property
//
//  Created by sebarina on 2019/8/9.
//  Copyright © 2019 Alibaba. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
NS_ASSUME_NONNULL_BEGIN

@interface PropertyEnumerationUtils : NSObject

+ (NSArray*)getAllProperties:(Class)cls;
+ (nullable NSDictionary*)jsonDictionaryOfObject:(id)obj;
+ (id)ivarValue:(Ivar)ivar ofObject:(id)obj;
+ (void)setIvar:(Ivar)ivar value:(id)value onObject:(id)obj;
+ (id)propertyValue:(objc_property_t)property ofObject:(id)obj;
@end

NS_ASSUME_NONNULL_END
