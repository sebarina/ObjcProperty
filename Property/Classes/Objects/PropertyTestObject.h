//
//  PropertyTestObject.h
//  Property
//
//  Created by sebarina on 2019/8/13.
//  Copyright © 2019 Alibaba. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PropertyTestObject : NSObject
@property (nonatomic,strong) NSString *name;
@property (nonatomic,assign) BOOL isDisable;
@property (nonatomic,strong) NSArray *logoList;
@property (nonatomic,assign) UIEdgeInsets edgetInsets;
@property (nonatomic,assign) CGSize size;
@property (nonatomic,strong) UIColor *bgColor;
@property (nonatomic,strong,readonly) NSString *readProps;
@property (nonatomic,assign,getter=hasPromotion) BOOL promotion;

+ (void)test;
@end

NS_ASSUME_NONNULL_END
