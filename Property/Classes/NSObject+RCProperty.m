//
//  NSObject+RCProperty.m
//  Property
//
//  Created by sebarina on 2019/8/12.
//  Copyright © 2019 Alibaba. All rights reserved.
//

#import <objc/runtime.h>
#import "NSObject+RCProperty.h"
#import "RCRuntimeUtils.h"
#import "PropertyEnumerationUtils.h"

@implementation NSObject (RCProperty)




- (id)rc_valueForKey:(NSString*)key
{
    // type encoding https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
    if (key.length <= 0) {
        return nil;
    }
    objc_property_t property = class_getProperty([self class], [key UTF8String]);
    id value = [PropertyEnumerationUtils propertyValue:property ofObject:self];
    if (value) {
        return value;
    } else {
        Ivar ivar = class_getInstanceVariable([self class], [key UTF8String]);
        if (ivar) {
            value = [PropertyEnumerationUtils ivarValue:ivar ofObject:self];
        } else {
            Ivar ivar2 = class_getInstanceVariable([self class], strcat("_", [key UTF8String]));
            if (ivar2) {
                value = [PropertyEnumerationUtils ivarValue:ivar2 ofObject:self];
            }
            
        }
        return value;
    }
}

- (void)rc_setValue:(id)value forKey:(NSString*)key
{
    if (key.length <= 0) {
        return;
    }
    NSArray *params = nil;
    if (value) {
        params = @[value];
    }
    
    NSString *setterSelName = [[[@"set" stringByAppendingString:[[key substringToIndex:1] uppercaseString]] stringByAppendingString:[key substringFromIndex:1]] stringByAppendingString:@":"];
    
    if ([self respondsToSelector:NSSelectorFromString(setterSelName)]) {
        [RCRuntimeUtils performSelector:NSSelectorFromString(setterSelName) onObject:self withParams:params];
    } else {
        Ivar ivar = class_getInstanceVariable([self class], [key UTF8String]);
        if (ivar) {
            [PropertyEnumerationUtils setIvar:ivar value:value onObject:self];
        } else {
            Ivar ivar2 = class_getInstanceVariable([self class], [[@"_" stringByAppendingString:key] UTF8String]);
            if (ivar2) {
                [PropertyEnumerationUtils setIvar:ivar2 value:value onObject:self];
            }
        }
        
        
    }
    
}


- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    id obj = [[self class] allocWithZone:zone];
    
    // 所有的var copy
    unsigned int count = 0;
    Ivar *varList = class_copyIvarList([self class], &count);
    for (unsigned int i = 0; i < count; i++) {
        Ivar ivar = varList[i];
        const char *vName = ivar_getName(ivar);
        const char *typeEncoding = ivar_getTypeEncoding(ivar);
        if (typeEncoding[0] == @encode(Class)[0] && strcmp(vName, "isa") == 0) {
            // isa
            continue;
        } else {
            id ivarValue = [PropertyEnumerationUtils ivarValue:ivar ofObject:self];
            [PropertyEnumerationUtils setIvar:ivar value:ivarValue onObject:obj];
        }
    }
    return obj;
}

@end
