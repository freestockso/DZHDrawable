//
//  DZHKLineDataSource.m
//  DZHDrawable
//
//  Created by Duanwwu on 14-6-30.
//  Copyright (c) 2014年 Duanwwu. All rights reserved.
//

#import "DZHKLineDataSource.h"
#import "UIColor+RGB.h"
#import "DZHKLineDrawing.h"
#import "DZHAxisYDrawing.h"
#import "DZHAxisXDrawing.h"
#import "DZHRectangleDrawing.h"
#import "DZHKLineValueFormatter.h"
#import "DZHKLineDateFormatter.h"
#import "DZHKLineContainer.h"
#import "DZHAxisEntity.h"
#import "DZHCandleEntity.h"

@implementation DZHKLineDataSource
{
    DZHKLineDateFormatter           *_dateFormatter;
    DZHKLineValueFormatter          *_valueFormatter;
    UIColor                         *_positiveColor;
    UIColor                         *_negativeColor;
    UIColor                         *crossColor;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.grouping                   = [NSMutableArray array];
        self.kLineWidth                 = 2.;
        self.kLinePadding               = 2.;
        self.minTickCount               = 4;
        self.maxTickCount               = 4;
        self.maxScale                   = 4.;
        self.minScale                   = .5;
        self.scale                      = 1.;
        _dateFormatter                  = [[DZHKLineDateFormatter alloc] init];
        _valueFormatter                 = [[DZHKLineValueFormatter alloc] init];
        _positiveColor                  = [UIColor colorFromRGB:0xf92a27];
        _negativeColor                  = [UIColor colorFromRGB:0x2b9826];
        crossColor                      = [UIColor grayColor];
    }
    return self;
}

- (void)dealloc
{
    [_dateFormatter release];
    [_valueFormatter release];
    
    [_positiveColor release];
    [_negativeColor release];
    [crossColor release];
    
    [_grouping release];
    [_klines release];
    [super dealloc];
}

- (void)setKlines:(NSArray *)klines
{
    if (_klines != klines)
    {
        [_klines release];
        _klines                             = [klines retain];
        
        [_grouping removeAllObjects];
        int idx                             = 0;
        
        DZHKLineEntity *lastEntity;
        for (DZHKLineEntity *entity in _klines)
        {
            if (idx != 0)
                [self decisionGroupIfNeedWithPreEntity:lastEntity curEntity:entity index:idx];
            
            lastEntity          = entity;
            idx ++;
        }
    }
}

- (void)setScale:(CGFloat)scale
{
    if (scale > _maxScale)
        _scale              = _maxScale;
    else if (scale < _minScale)
        _scale              = _minScale;
    else
        _scale              = scale;
}

- (CGFloat)_getKLineWidth
{
    return _kLineWidth * _scale;
}

- (CGFloat)_getKlinePadding
{
    return _kLinePadding * _scale;
}

#pragma mark - DZHDrawingDataSource

- (NSArray *)datasForDrawing:(id<DZHDrawing>)drawing
{
    if ([drawing isKindOfClass:[DZHAxisXDrawing class]])
    {
        return [self axisXDatasForDrawing:drawing];
    }
    else if ([drawing isKindOfClass:[DZHAxisYDrawing class]])
    {
        return [self axisYDatasForDrawing:drawing];
    }
    else if ([drawing isKindOfClass:[DZHKLineDrawing class]])
    {
        return [self kLineDatasForDrawing:drawing];
    }
    return nil;
}

@end

#pragma mark - abstract

@implementation DZHKLineDataSource (Base)

- (void)prepareWithKLineRect:(CGRect)rect
{
    [self needDrawKLinesInRect:rect startIndex:&_startIndex endIndex:&_endIndex];
    [self calculateMaxPrice:&_max minPrice:&_min fromIndex:_startIndex toIndex:_endIndex];
}

- (void)needDrawKLinesInRect:(CGRect)rect startIndex:(NSInteger *)startIndex endIndex:(NSInteger *)endIndex
{
    CGFloat kWidth              = [self _getKLineWidth];    //k线实体宽度
    CGFloat kPadding            = [self _getKlinePadding];  //k线间距
    CGFloat space               = kWidth + kPadding;
    *startIndex                 = MAX((rect.origin.x - kPadding - _kLineOffset)/space , 0);
    *endIndex                   = MIN((CGRectGetMaxX(rect) - kPadding - _kLineOffset)/space , [_klines count] - 1);
}

- (void)calculateMaxPrice:(NSInteger *)maxPrice minPrice:(NSInteger *)minPrice fromIndex:(NSInteger)from toIndex:(NSInteger)to
{
    NSInteger max                     = NSIntegerMin;
    NSInteger min                     = NSIntegerMax;
    
    for (NSInteger i = from; i <= to; i++)
    {
        DZHKLineEntity *entity  = [_klines objectAtIndex:i];
        
        if (entity.high > max)
            max        = entity.high;
        
        if (entity.low < min)
            min        = entity.low;
    }
    
    *minPrice                           = min;
    *maxPrice                           = max;
}

- (CGFloat)totalKLineWidth
{
    CGFloat kLineWidth          = [self _getKLineWidth];
    CGFloat kLinePadding        = [self _getKlinePadding];
    return [self.klines count] * (kLineWidth + kLinePadding) + kLinePadding;
}

- (CGFloat)kLineLocationForIndex:(NSUInteger)index
{
    CGFloat kWidth              = [self _getKLineWidth];    //k线实体宽度
    CGFloat kPadding            = [self _getKlinePadding];  //k线间距
    CGFloat space               = kWidth + kPadding;
    return _kLineOffset + kPadding + index * space;
}

- (CGFloat)kLineCenterLocationForIndex:(NSUInteger)index
{
    CGFloat kWidth              = [self _getKLineWidth];    //k线实体宽度
    CGFloat kPadding            = [self _getKlinePadding];  //k线间距
    CGFloat space               = kWidth + kPadding;
    return _kLineOffset + kPadding + index * space + kWidth * .5;
}

- (NSUInteger)indexForLocation:(CGFloat)position
{
    CGFloat kWidth              = [self _getKLineWidth];    //k线实体宽度
    CGFloat kPadding            = [self _getKlinePadding];  //k线间距
    CGFloat space               = kWidth + kPadding;
    CGFloat v                   = (position - kPadding - _kLineOffset) / space ;
    int mode                    = ((int)(v * 100)) %100;
    int scale                   = kWidth / space * 100;
    return mode > scale ? NSUIntegerMax : v;
}

- (NSUInteger)nearIndexForLocation:(CGFloat)position
{
    CGFloat kWidth              = [self _getKLineWidth];    //k线实体宽度
    CGFloat kPadding            = [self _getKlinePadding];  //k线间距
    CGFloat space               = kWidth + kPadding;
    CGFloat index               = (position - kPadding - _kLineOffset) / space;
    return MIN(index, [_klines count] - 1);
}

@end

@implementation DZHKLineDataSource (AxisX)

- (NSArray *)axisXDatasForDrawing:(id<DZHDrawing>)drawing
{
    int interval                = MAX(1, roundf(1.4f / self.scale));
    return [self groupsFromIndex:_startIndex toIndex:_endIndex monthInterval:interval];
}

- (void)decisionGroupIfNeedWithPreEntity:(DZHKLineEntity *)preEntity curEntity:(DZHKLineEntity *)curEntity index:(int)index
{
    int preMonth        = [_dateFormatter yearMonthOfDate:preEntity.date];
    int curMonth        = [_dateFormatter yearMonthOfDate:curEntity.date];
    
    if (preMonth != curMonth)//如果当前数据跟上一个数据不在一个月，则进行分组
    {
        [self.grouping addObject:[NSString stringWithFormat:@"%d%d",curEntity.date,index]];
    }
}

- (NSArray *)groupsFromIndex:(NSInteger)from toIndex:(NSInteger)to monthInterval:(int)interval
{
    NSParameterAssert(interval >= 1);
    
    NSMutableArray *datas           = [NSMutableArray array];
    
    NSInteger count                 = [self.grouping count];
    int mode                        = count % interval;
    int startIndex                  = mode == 0 ? 0 : mode + 1;
    
    for (int i = startIndex; i <count; i += interval)
    {
        NSString *str               = [_grouping objectAtIndex:i];
        int index                   = [[str substringFromIndex:8] intValue];
        
        if (index >= from && index <= to)
        {
            CGFloat x               = [self kLineCenterLocationForIndex:index];
            int date                = [[str substringToIndex:8] intValue];
            
            DZHAxisEntity *entity   = [[DZHAxisEntity alloc] init];
            entity.location         = CGPointMake(x, 0.);
            entity.labelText        = [_dateFormatter stringForObjectValue:@(date)];
            [datas addObject:entity];
            [entity release];
        }
        
        if (index > to)
            break;
        
    }
    return datas;
}

@end

@implementation DZHKLineDataSource (AxisY)

- (NSArray *)axisYDatasForDrawing:(id<DZHDrawing>)drawing
{
    NSInteger tickCount,strip;
    
    [self adjustMaxIfNeed:&tickCount strip:&strip];
    
    NSMutableArray *datas       = [NSMutableArray array];
    
    for (int i = 0; i <= tickCount; i++)
    {
        NSInteger value             = self.min + strip * i;
        CGFloat y                   = [drawing coordYWithValue:value max:_max min:_min];
        
        DZHAxisEntity *entity   = [[DZHAxisEntity alloc] init];
        entity.location         = CGPointMake(.0, y);
        entity.labelText        = [_valueFormatter stringForObjectValue:@(value)];
        [datas addObject:entity];
        [entity release];
    }
    return datas;
}

- (void)adjustMaxIfNeed:(NSInteger *)tickCount strip:(NSInteger *)strip
{
    NSInteger maxValue    = self.max;
    NSInteger min         = self.min;
    
    NSInteger count = [self tickCountWithMax:maxValue min:min strip:strip];
    
    while (count == NSIntegerMax)
    {
        maxValue ++;
        count       = [self tickCountWithMax:maxValue min:min strip:strip];
    }
    
    *tickCount      = count;
    self.max        = maxValue;
}

- (NSInteger)tickCountWithMax:(NSInteger)max min:(NSInteger)min strip:(NSInteger *)strip
{
    NSInteger v               = max - min;
    for (NSInteger i = _maxTickCount - 1; i >= _minTickCount - 1; i--)
    {
        if (v % i == 0)
        {
            *strip      = v / i;
            return i;
        }
    }
    return NSIntegerMax;
}

@end

@implementation DZHKLineDataSource (KLine)

- (NSArray *)kLineDatasForDrawing:(id<DZHDrawing>)drawing
{
    NSInteger max               = self.max;
    NSInteger min               = self.min;
    NSUInteger startIndex       = self.startIndex;   //绘制起始点
    NSUInteger endIndex         = self.endIndex;     //绘制结束点
    CGFloat kWidth              = [self _getKLineWidth];
    NSArray *klines             = self.klines;
    NSMutableArray *datas       = [NSMutableArray array];
    
    CGFloat open,close,high,low,x,center;
    CGRect fillRect;
    DZHKLineEntity *entity;
    DZHCandleEntity *candle;
    
    for (NSUInteger i = startIndex; i <= endIndex; i++)
    {
        entity                  = [klines objectAtIndex:i];
        
        open                    = [drawing coordYWithValue:entity.open max:max min:min];
        close                   = [drawing coordYWithValue:entity.close max:max min:min];
        high                    = [drawing coordYWithValue:entity.high max:max min:min];
        low                     = [drawing coordYWithValue:entity.low max:max min:min];
        
        x                       = [self kLineLocationForIndex:i];
        fillRect                = CGRectMake(x, MIN(open, close), kWidth, MAX(ABS(open - close), 1.));
        center                  = CGRectGetMidX(fillRect);
        
        candle                  = [[DZHCandleEntity alloc] init];
        candle.fillRect         = fillRect;
        candle.high             = CGPointMake(center, high);
        candle.low              = CGPointMake(center, low);
        candle.kLineType        = entity.type;
        [datas addObject:candle];
        [candle release];
    }
    return datas;
}

@end
