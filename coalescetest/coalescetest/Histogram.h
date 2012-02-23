#import <Foundation/Foundation.h>

typedef uint32_t HistogramBinValue;

@interface Histogram : NSObject

@property (readonly) double minimumSample;
@property (readonly) double maximumSample;
@property (readonly) double binWidth;
@property (readonly) size_t binCount;
@property (readonly) HistogramBinValue const *bins;

// Maximum of current values of all bins - not maximum possible `HistogramBinValue`
@property (readonly) HistogramBinValue largestSampleCount;

- (id)initWithMinimumSample:(double)minimumSample maximumSample:(double)maximumSample binWidth:(double)binWidth;

- (void)reset;

- (void)addSample:(double)sample;

- (double)minimumSampleOfBinAtIndex:(size_t)index;
- (double)maximumSampleOfBinAtIndex:(size_t)index;

@end
