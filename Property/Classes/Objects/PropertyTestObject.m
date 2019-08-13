//
//  PropertyTestObject.m
//  Property
//
//  Created by sebarina on 2019/8/13.
//  Copyright © 2019 Alibaba. All rights reserved.
//

#import "PropertyTestObject.h"
#import "PropertyEnumerationUtils.h"
#import "NSObject+RCProperty.h"

@interface PropertyTestObject ()
{
    NSString *stringInstance;
    BOOL boolInstance;
}
@property (nonatomic,copy) NSString *strPropcpy;
@end

@implementation PropertyTestObject


+ (void)test
{
    NSArray *props = [PropertyEnumerationUtils getAllProperties:[self class]];
    
    NSLog(@"%@",[props componentsJoinedByString:@"\n"]);
    
    
    PropertyTestObject *testObj = [[PropertyTestObject alloc] init];
    [testObj rc_setValue:@"hello testing" forKey:@"name"];
    [testObj rc_setValue:@YES forKey:@"isDisable"];
    [testObj rc_setValue:@[@"hello",@"world"] forKey:@"logoList"];
    [testObj rc_setValue:[NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(10, 2, 10, 2)] forKey:@"edgetInsets"];
    
    [testObj rc_setValue:[NSValue valueWithCGSize:CGSizeMake(20, 20)] forKey:@"size"];
    [testObj rc_setValue:[UIColor redColor] forKey:@"bgColor"];
    [testObj rc_setValue:@"readonly" forKey:@"readProps"];
    [testObj rc_setValue:@YES forKey:@"promotion"];
    [testObj rc_setValue:@"instance string" forKey:@"stringInstance"];
    [testObj rc_setValue:@YES forKey:@"boolInstance"];
    [testObj rc_setValue:@"test test" forKey:@"strPropcpy"];
    
    
    NSDictionary *dict = [PropertyEnumerationUtils jsonDictionaryOfObject:testObj];
    NSLog(@"%@",dict);
    
    
    
    PropertyTestObject *anotherObj = [testObj copy];
    NSDictionary *dict3 = [PropertyEnumerationUtils jsonDictionaryOfObject:anotherObj];
    
    NSLog(@"%@",dict3);
    
    NSLog(@"{%@,%@}", @(anotherObj.size.width),@(anotherObj.size.height));
}

@end
