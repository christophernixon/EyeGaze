//
//  OneEuroFilter.h
//  SeeSo
//
//  Created by david on 2020/06/08.
//  Copyright © 2020 이다빈. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface OneEuroFilter : NSObject{
    
    double freq;
    double mincutoff;
    double beta;
    double dcutoff;
    long lasttime;
    
}
@property (assign) double freq;
@property (assign) double mincutoff;
@property (assign) double beta;
@property (assign) double dcutoff;
@property (assign) long lasttime;
- (double)alpha:(double)cutoff;
- (void)setFrequency:(double)f;
- (void)setMinCutoff:(double)mc;
- (void)setDerivativeCutoff:(double)dc;
- (id)initWithFrequency:(double)f mincutoff:(double)m beta:(double)b dcutoff:(double)d;
+ (id)oneEuroFilterWithFrequency:(double)f mincutoff:(double)m beta:(double)b dcutoff:(double)d;
- (double) filterValue:(double)value inTimestamp:(long)timestamp;
@end
