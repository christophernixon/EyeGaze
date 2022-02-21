//
//  LowPassFilter.h
//  SeeSo
//
//  Created by david on 2020/06/08.
//  Copyright © 2020 이다빈. All rights reserved.
//
#import <Foundation/Foundation.h>
@interface LowPassFilter : NSObject{

 double y;
 double a;
 double s;
 Boolean initialized;

}
@property (assign) double y;
@property (assign) double a;
@property (assign) double s;
@property (assign) Boolean initialized;
- (void)setAlpha:(double)alpha;
- (id)initWithAlpha:(double)alpha initval:(double)initval;
+ (id)lowPassFilterWithAlpha:(double)alpha
initval:(double)initval;
- (double)filterValue:(double)value;
- (double)filterValue:(double)value withAlpha:(double)alpha;
- (BOOL)hasLastRawValue;
- (double)lastRawValue;
@end
