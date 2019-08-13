//
//  PropertyEnumerationUtils.m
//  Property
//
//  Created by sebarina on 2019/8/9.
//  Copyright © 2019 Alibaba. All rights reserved.
//
#import <UIKit/UIKit.h>

#import "PropertyEnumerationUtils.h"
#import "RCRuntimeUtils.h"


NSString *const kPropertyAttributeTypeEncoding = @"T";
NSString *const kPropertyAttributeBackingIvar = @"V";
NSString *const kPropertyAttributeReadOnly = @"R";
NSString *const kPropertyAttributeCopy = @"C";
NSString *const kPropertyAttributeRetain = @"&";
NSString *const kPropertyAttributeNonAtomic = @"N";
NSString *const kPropertyAttributeCustomGetter = @"G";
NSString *const kPropertyAttributeCustomSetter = @"S";
NSString *const kPropertyAttributeDynamic = @"D";
NSString *const kPropertyAttributeWeak = @"W";
NSString *const kPropertyAttributeGarbageCollectable = @"P";
NSString *const kPropertyAttributeOldStyleTypeEncoding = @"t";

@implementation PropertyEnumerationUtils

+ (nullable NSDictionary *)jsonDictionaryOfObject:(id)obj
{
    Class cls = [obj class];
    if (!cls) {
        return nil;
    }
    NSMutableDictionary *dict = [@{} mutableCopy];
    unsigned int count = 0;
//    objc_property_t *properties = class_copyPropertyList(cls,&count);
//    for (unsigned int i = 0; i < count; i++) {
//        objc_property_t p = properties[i];
//        NSString *pName = @(property_getName(p));
//        id pValue = [self propertyValue:p ofObject:obj];
//        if (pValue) {
//            dict[pName] = pValue;
//        }
//    }
//    free(properties);
    
    Ivar *ivarList = class_copyIvarList(cls, &count);
    for (unsigned int i = 0; i < count; i++) {
        Ivar ivar = ivarList[i];
        const char *varName = ivar_getName(ivar);
        NSString *vName = varName? @(varName) : nil;
        if (vName.length > 0) {
            id value = [self ivarValue:ivar ofObject:obj];
            
            if ([vName hasPrefix:@"_"]) {
                if(class_getProperty(cls, [[vName substringFromIndex:1] UTF8String])) {
                    vName = [vName substringFromIndex:1];
                }
            }
            
            if (value) {
                dict[vName] = value;
            }
        }
    }
    return dict;
}

+ (NSArray*)getAllProperties:(Class)cls
{
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList(cls,&count);
    NSMutableArray *propertyList = [@[] mutableCopy];
    for (unsigned int i = 0; i < count; i++) {
        objc_property_t p = properties[i];
        [propertyList addObject:[self descriptionOfProperty:p]];
    }
    free(properties);
    return propertyList;
}

+ (NSArray*)getAllIVarList:(Class)cls
{
    unsigned int count = 0;
    NSMutableArray *ivarDescList = [@[] mutableCopy];
    Ivar *ivarList = class_copyIvarList(cls,&count);
    for (unsigned int i = 0; i < count; i++) {
        Ivar ivar = ivarList[i];
        NSString *varDesc = [self descriptionOfIvar:ivar];
        if (varDesc.length > 0) {
            [ivarDescList addObject:varDesc];
        }
    }
    free(ivarList);
    return ivarDescList;
}

+ (id)ivarValue:(Ivar)ivar ofObject:(id)obj
{
    // ivar 存在isa
    const char *typeEncoding = ivar_getTypeEncoding(ivar);
    const char *vName = ivar_getName(ivar);
    
    if (typeEncoding[0] == @encode(Class)[0] && strcmp(vName, "isa") == 0) {
        // isa not return for json
        return nil;
    } else if(typeEncoding[0] == '@' || typeEncoding[0] == @encode(Class)[0]) {
        // id & Class var
        return object_getIvar(obj, ivar);
    } else {
        // primitive types
        ptrdiff_t offset = ivar_getOffset(ivar);
        void *pointer = (__bridge void*)obj;
        pointer += offset;
        NSUInteger size = 0;
        NSGetSizeAndAlignment(typeEncoding, &size, NULL);
        void *mem = malloc(size);
        memcpy(mem, pointer, size);
        NSValue *value = [RCRuntimeUtils valueForPrimitivePointer:mem objCType:typeEncoding];
        free(mem);
        return value;
    }
}

+ (void)setIvar:(Ivar)ivar value:(id)value onObject:(id)obj
{
    // ivar 存在isa
    const char *typeEncoding = ivar_getTypeEncoding(ivar);
    const char *vName = ivar_getName(ivar);
    
    if (typeEncoding[0] == @encode(Class)[0] && strcmp(vName, "isa")) {
        // isa not return for json
        return ;
    } else if(typeEncoding[0] == '@' || typeEncoding[0] == @encode(Class)[0]) {
        // id & Class var
        object_setIvar(obj, ivar, value);
    } else {
        if ([value isKindOfClass:[NSValue class]]) {
            // primitive types
            ptrdiff_t offset = ivar_getOffset(ivar);
            void *pointer = (__bridge void*)obj;
            pointer += offset;
            NSValue *temp = (NSValue*)value;
            NSUInteger size = 0;
            NSGetSizeAndAlignment([temp objCType], &size, NULL);
            void *buffer = calloc(size, 1);
            [temp getValue:buffer];
            memcpy(pointer, buffer, size);
            free(buffer);
        }
    }
}

+ (NSString*)descriptionOfIvar:(Ivar)ivar
{
    const char *name = ivar_getName(ivar);
    NSString *vName = name? @(name) : nil;
    const char *typeEncoding = ivar_getTypeEncoding(ivar);
    NSString *vType = [self readableTypeFromTypeEncoding:typeEncoding?@(typeEncoding):nil];
    if (vName.length > 0) {
        return [NSString stringWithFormat:@"%@ %@", vType?:@"", vName];
    } else {
        return nil;
    }
}

+ (id)propertyValue:(objc_property_t)property ofObject:(id)obj
{
    NSString *pName = @(property_getName(property));
    NSString *getterSelName = pName;
    char *custonGetterName = property_copyAttributeValue(property,"G");
    if (custonGetterName) {
        getterSelName = @(custonGetterName);
    }
    SEL getterSel = NSSelectorFromString(getterSelName);
    if ([obj respondsToSelector:getterSel]) {
        return [RCRuntimeUtils performSelector:getterSel onObject:obj withParams:nil];
    } else {
        return nil;
    }
    
}

+ (NSDictionary*)attributesDictOfProperty:(objc_property_t)property
{
    NSString *attrStr = @(property_getAttributes(property));
    NSArray *attrPairs = [attrStr componentsSeparatedByString:@","];
    NSMutableDictionary *attrDict = [@{} mutableCopy];
    for (NSString *attrP in attrPairs) {
        attrDict[[attrP substringToIndex:1]] = [attrP substringFromIndex:1];
    }
    return attrDict;
}

+ (NSString*)descriptionOfProperty:(objc_property_t)property
{
    NSString *pName = @(property_getName(property));
    NSString *attrStr = @(property_getAttributes(property));
    NSArray *attrPairs = [attrStr componentsSeparatedByString:@","];
    NSMutableDictionary *attrDict = [@{} mutableCopy];
    for (NSString *attrP in attrPairs) {
        attrDict[[attrP substringToIndex:1]] = [attrP substringFromIndex:1];
    }
    NSMutableArray *attrList = [@[] mutableCopy];
    if (attrDict[kPropertyAttributeNonAtomic]) {
        [attrList addObject:@"nonatomic"];
    }
    if (attrDict[kPropertyAttributeCopy]) {
        [attrList addObject:@"copy"];
    } else if (attrDict[kPropertyAttributeRetain]) {
        [attrList addObject:@"strong"];
    } else if (attrDict[kPropertyAttributeWeak]) {
        [attrList addObject:@"weak"];
    } else {
        [attrList addObject:@"assign"];
    }
    if (attrDict[kPropertyAttributeCustomGetter]) {
        [attrList addObject:[NSString stringWithFormat:@"getter=%@",attrDict[kPropertyAttributeCustomGetter]]];
    }
    if (attrDict[kPropertyAttributeCustomSetter]) {
        [attrList addObject:@"readonly"];
    }
    if (attrDict[kPropertyAttributeReadOnly]) {
        [attrList addObject:@"readonly"];
    }
    return [NSString stringWithFormat:@"@property (%@) %@ %@",[attrList componentsJoinedByString:@","],[self readableTypeFromTypeEncoding:attrDict[kPropertyAttributeTypeEncoding]], pName];;
}

+ (NSString*)readableTypeFromTypeEncoding:(NSString*)typeEncoding
{
    if (!typeEncoding) {
        return nil;
    }
    
    // See https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
    // class-dump has a much nicer and much more complete implementation for this task, but it is distributed under GPLv2 :/
    // See https://github.com/nygard/class-dump/blob/master/Source/CDType.m
    // Warning: this method uses multiple middle returns and macros to cut down on boilerplate.
    // The use of macros here was inspired by https://www.mikeash.com/pyblog/friday-qa-2013-02-08-lets-build-key-value-coding.html
    const char *encodingCString = [typeEncoding UTF8String];
    
    // Objects
    if (encodingCString[0] == '@') {
        NSString *class = [typeEncoding substringFromIndex:1];
        class = [class stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        if ([class length] == 0 || [class isEqual:@"?"]) {
            class = @"id";
        } else {
            class = [class stringByAppendingString:@" *"];
        }
        return class;
    }
    
    
    // C Types
#define TRANSLATE(ctype) \
if (strcmp(encodingCString, @encode(ctype)) == 0) { \
return (NSString *)CFSTR(#ctype); \
}
    
    // Order matters here since some of the cocoa types are typedefed to c types.
    // We can't recover the exact mapping, but we choose to prefer the cocoa types.
    // This is not an exhaustive list, but it covers the most common types
    TRANSLATE(CGRect);
    TRANSLATE(CGPoint);
    TRANSLATE(CGSize);
    TRANSLATE(UIEdgeInsets);
    TRANSLATE(UIOffset);
    TRANSLATE(NSRange);
    TRANSLATE(CGAffineTransform);
    TRANSLATE(CATransform3D);
    TRANSLATE(CGColorRef);
    TRANSLATE(CGPathRef);
    TRANSLATE(CGContextRef);
    TRANSLATE(NSInteger);
    TRANSLATE(NSUInteger);
    TRANSLATE(CGFloat);
    TRANSLATE(BOOL);
    TRANSLATE(int);
    TRANSLATE(short);
    TRANSLATE(long);
    TRANSLATE(long long);
    TRANSLATE(unsigned char);
    TRANSLATE(unsigned int);
    TRANSLATE(unsigned short);
    TRANSLATE(unsigned long);
    TRANSLATE(unsigned long long);
    TRANSLATE(float);
    TRANSLATE(double);
    TRANSLATE(long double);
    TRANSLATE(char *);
    TRANSLATE(Class);
    TRANSLATE(objc_property_t);
    TRANSLATE(Ivar);
    TRANSLATE(Method);
    TRANSLATE(Category);
    TRANSLATE(NSZone *);
    TRANSLATE(SEL);
    TRANSLATE(void);
    
#undef TRANSLATE
    
    // Qualifier Prefixes
    // Do this after the checks above since some of the direct translations (i.e. Method) contain a prefix.
#define RECURSIVE_TRANSLATE(prefix, formatString) \
if (encodingCString[0] == prefix) { \
NSString *recursiveType = [self readableTypeFromTypeEncoding:[typeEncoding substringFromIndex:1]]; \
return [NSString stringWithFormat:formatString, recursiveType]; \
}
    
    // If there's a qualifier prefix on the encoding, translate it and then
    // recursively call this method with the rest of the encoding string.
    RECURSIVE_TRANSLATE('^', @"%@ *");
    RECURSIVE_TRANSLATE('r', @"const %@");
    RECURSIVE_TRANSLATE('n', @"in %@");
    RECURSIVE_TRANSLATE('N', @"inout %@");
    RECURSIVE_TRANSLATE('o', @"out %@");
    RECURSIVE_TRANSLATE('O', @"bycopy %@");
    RECURSIVE_TRANSLATE('R', @"byref %@");
    RECURSIVE_TRANSLATE('V', @"oneway %@");
    RECURSIVE_TRANSLATE('b', @"bitfield(%@)");
    
#undef RECURSIVE_TRANSLATE
    
    // If we couldn't translate, just return the original encoding string
    return typeEncoding;
}



@end
