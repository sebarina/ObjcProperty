//
//  RCRuntimeUtils.m
//  Property
//
//  Created by sebarina on 2019/8/12.
//  Copyright © 2019 Alibaba. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "RCRuntimeUtils.h"

#define kRCRuntimeParameterStartIndex 2

@implementation RCRuntimeUtils

+ (id)performSelector:(SEL)sel onObject:(id)object withParams:(nullable NSArray*)params
{
    NSMethodSignature *signature = [object methodSignatureForSelector:sel];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:object];
    [invocation setSelector:sel];
    [invocation retainArguments];
    
    NSInteger count = [signature numberOfArguments];
    for (NSInteger index = kRCRuntimeParameterStartIndex; index < count; index++) {
        if (params.count <= index - kRCRuntimeParameterStartIndex) {
            break;
        }
        
        id paramObj = params[index-kRCRuntimeParameterStartIndex];
        if ([paramObj isKindOfClass:[NSNull class]]) {
            continue;
        }
        const char *typeEncoding = [signature getArgumentTypeAtIndex:index];
        if (typeEncoding[0] == '@' || typeEncoding[0] == @encode(Class)[0] || [self isTollFreeBridgedValue:paramObj forCFType:typeEncoding]) {
            [invocation setArgument:&paramObj atIndex:index];
        } else {
            // primitive type
            if (typeEncoding[0] == @encode(CGColorRef)[0] && [paramObj isKindOfClass:[UIColor class]]) {
                UIColor *color = (UIColor*)paramObj;
                CGColorRef colorRef = [color CGColor];
                [invocation setArgument:&colorRef atIndex:index];
            }
            if (typeEncoding[0] == @encode(BOOL)[0]) {
                // bool
                BOOL bValue = [paramObj boolValue];
                [invocation setArgument:&bValue atIndex:index];
            } else if([paramObj isKindOfClass:[NSValue class]]) {
                // NSNumber , NSValue
                NSValue *nValue = (NSValue*)paramObj;
                
                if (strcmp(typeEncoding, [nValue objCType]) != 0) {
                    // not same type
                    continue;
                }
                
                NSUInteger size = 0;
                NSGetSizeAndAlignment(typeEncoding, &size, NULL);
                
                if (size > 0) {
                    void *buffer = calloc(size, 1);
                    [nValue getValue:buffer];
                    [invocation setArgument:buffer atIndex:index];
                    free(buffer);
                }
                
            }
            
        }
        
    }
    
    BOOL successfullyInvoked = NO;
    @try {
        [invocation invoke];
        successfullyInvoked = YES;
    } @catch (NSException *exception) {
        
    }
    id returnObject = nil;
    if (successfullyInvoked) {
        const char *returnTypeEncoding = [signature methodReturnType];
        if (returnTypeEncoding[0] == '@' || returnTypeEncoding[0] == @encode(Class)[0]) {
            // id & Class
            __unsafe_unretained id objectReturnedFromMethod = nil;
            [invocation getReturnValue:&objectReturnedFromMethod];
            returnObject = objectReturnedFromMethod;
            
        } else if (returnTypeEncoding[0] != @encode(void)[0]) {
            // not return void
            NSUInteger len = [signature methodReturnLength];
            void *buffer = malloc(len);
            if (buffer) {
                [invocation getReturnValue:buffer];
                returnObject = [self valueForPrimitivePointer:buffer objCType:returnTypeEncoding];
                free(buffer);
            }
            
            
        }
        
    }
    return returnObject;

}

+ (BOOL)isTollFreeBridgedValue:(id)value forCFType:(const char *)typeEncoding
{
    // See https://developer.apple.com/library/ios/documentation/general/conceptual/CocoaEncyclopedia/Toll-FreeBridgin/Toll-FreeBridgin.html
#define CASE(cftype, foundationClass) \
if(strcmp(typeEncoding, @encode(cftype)) == 0) { \
return [value isKindOfClass:[foundationClass class]]; \
}
    
    CASE(CFArrayRef, NSArray);
    CASE(CFAttributedStringRef, NSAttributedString);
    CASE(CFCalendarRef, NSCalendar);
    CASE(CFCharacterSetRef, NSCharacterSet);
    CASE(CFDataRef, NSData);
    CASE(CFDateRef, NSDate);
    CASE(CFDictionaryRef, NSDictionary);
    CASE(CFErrorRef, NSError);
    CASE(CFLocaleRef, NSLocale);
    CASE(CFMutableArrayRef, NSMutableArray);
    CASE(CFMutableAttributedStringRef, NSMutableAttributedString);
    CASE(CFMutableCharacterSetRef, NSMutableCharacterSet);
    CASE(CFMutableDataRef, NSMutableData);
    CASE(CFMutableDictionaryRef, NSMutableDictionary);
    CASE(CFMutableSetRef, NSMutableSet);
    CASE(CFMutableStringRef, NSMutableString);
    CASE(CFNumberRef, NSNumber);
    CASE(CFReadStreamRef, NSInputStream);
    CASE(CFRunLoopTimerRef, NSTimer);
    CASE(CFSetRef, NSSet);
    CASE(CFStringRef, NSString);
    CASE(CFTimeZoneRef, NSTimeZone);
    CASE(CFURLRef, NSURL);
    CASE(CFWriteStreamRef, NSOutputStream);
    
#undef CASE
    
    return NO;
}

+ (NSValue *)valueForPrimitivePointer:(void *)pointer objCType:(const char *)type
{
    // CASE macro inspired by https://www.mikeash.com/pyblog/friday-qa-2013-02-08-lets-build-key-value-coding.html
#define CASE(ctype, selectorpart) \
if(strcmp(type, @encode(ctype)) == 0) { \
return [NSNumber numberWith ## selectorpart: *(ctype *)pointer]; \
}
    
    CASE(BOOL, Bool);
    CASE(unsigned char, UnsignedChar);
    CASE(short, Short);
    CASE(unsigned short, UnsignedShort);
    CASE(int, Int);
    CASE(unsigned int, UnsignedInt);
    CASE(long, Long);
    CASE(unsigned long, UnsignedLong);
    CASE(long long, LongLong);
    CASE(unsigned long long, UnsignedLongLong);
    CASE(float, Float);
    CASE(double, Double);
    
#undef CASE
    
    NSValue *value = nil;
    @try {
        value = [NSValue valueWithBytes:pointer objCType:type];
    } @catch (NSException *exception) {
        // Certain type encodings are not supported by valueWithBytes:objCType:. Just fail silently if an exception is thrown.
    }
    
    return value;
}

@end
