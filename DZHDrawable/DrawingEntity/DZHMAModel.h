//
//  DZHMAModel.h
//  DZHDrawable
//
//  Created by Duanwwu on 14-7-4.
//  Copyright (c) 2014年 Duanwwu. All rights reserved.
//

#import "DZHDrawingItems.h"

@interface DZHMAModel : NSObject

@property (nonatomic) int cycle;

@property (nonatomic, retain) UIColor *color;

@property (nonatomic) CGPoint *points;

@property (nonatomic) NSInteger count;

@property (nonatomic) BOOL notBezier;

- (instancetype)initWithMACycle:(int)cyle;

- (void)setPoints:(CGPoint *)points withCount:(NSInteger)count;

@end
