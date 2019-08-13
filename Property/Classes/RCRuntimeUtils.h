//
//  RCRuntimeUtils.h
//  Property
//
//  Created by sebarina on 2019/8/12.
//  Copyright © 2019 Alibaba. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCRuntimeUtils : NSObject
+ (NSValue *)valueForPrimitivePointer:(void *)pointer objCType:(const char *)type;
+ (id)performSelector:(SEL)sel onObject:(id)object withParams:(nullable NSArray*)params;
@end

NS_ASSUME_NONNULL_END
