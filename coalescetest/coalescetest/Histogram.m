#import "Histogram.h"

@implementation Histogram {
    HistogramBinValue *_mutableBins;
}

@synthesize minimumSample = _minimumSample;
@synthesize maximumSample = _maximumSample;
@synthesize binWidth = _binWidth;
@synthesize binCount = _binCount;
@synthesize bins = _bins;
@synthesize largestSampleCount = _largestSampleCount;

- (id)initWithMinimumSample:(double)minimumSample maximumSample:(double)maximumSample binWidth:(double)binWidth
{
    if (!(self = [super init]))
        return nil;

    _minimumSample = minimumSample;
    _maximumSample = maximumSample;
    _binWidth = binWidth;
    _binCount = ceil(maximumSample - minimumSample) / _binWidth + 2;
    _mutableBins = calloc(_binCount, sizeof *_mutableBins);
    _bins = _mutableBins;

    return self;
}

- (double)minimumSampleOfBinAtIndex:(size_t)index {
    if (index == 0)
        return -INFINITY;
    else if (index == _binCount - 1)
        return _maximumSample;
    else
        return _minimumSample + (index - 1) * _binWidth;
}

- (double)maximumSampleOfBinAtIndex:(size_t)index {
    if (index == 0)
        return _minimumSample;
    else if (index == _binCount - 1)
        return INFINITY;
    else
        return _minimumSample + index * _binWidth;
}

- (void)addSample:(double)sample {
    size_t index =
        (sample < _minimumSample) ? 0
        : (sample >= _maximumSample) ? _binCount - 1
        : 1 + (int)((sample - _minimumSample) / _binWidth);
    ++_mutableBins[index];
    if (_mutableBins[index] > _largestSampleCount)
        _largestSampleCount = _mutableBins[index];
}

- (void)reset {
    memset(_mutableBins, 0, sizeof *_mutableBins * _binCount);
    _largestSampleCount = 0;
}

@end
