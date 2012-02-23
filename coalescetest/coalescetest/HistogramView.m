#import "HistogramView.h"
#import "Histogram.h"

@implementation HistogramView

@synthesize histogram = _histogram;

- (BOOL)isOpaque {
    return YES;
}

static CGFloat const kXAxisHeight = 20;
static CGFloat const kXAxisPadding = 2;

- (CGFloat)xForSample:(double)sample {
    return kXAxisPadding + (self.bounds.size.width - 2 * kXAxisPadding) * (sample - _histogram.minimumSample) / (_histogram.maximumSample - _histogram.minimumSample);
}

- (void)drawXAxis {
    CGRect bounds = self.bounds;
    [NSColor.grayColor setFill];
    [[NSBezierPath bezierPathWithRect:CGRectMake(0, kXAxisHeight, bounds.size.width, -1)] fill];
    
    double minValue = _histogram.minimumSample;
    double maxValue = _histogram.maximumSample;
    double tickIncrement = pow(10, floor(log10(maxValue - minValue)));
    for (int i = ceil(minValue / tickIncrement); i * tickIncrement <= maxValue; ++i) {
        CGFloat x = [self xForSample:i * tickIncrement];
        [[NSBezierPath bezierPathWithRect:CGRectMake(x-.5, 0, 1, kXAxisHeight)] fill];
    }
    
    tickIncrement /= 10;
    for (int i = ceil(minValue / tickIncrement); i * tickIncrement <= maxValue; ++i) {
        if (i % 10 == 0)
            continue;
        CGFloat x = [self xForSample:i * tickIncrement];
        [[NSBezierPath bezierPathWithRect:CGRectMake(x-.5, kXAxisHeight / 2, 1, kXAxisHeight/2)] fill];
    }
}

- (void)drawCount:(HistogramBinValue)count forSample:(double)sample {
    if (count == 0)
        return;
    CGFloat x = [self xForSample:sample];
    CGFloat height = (self.bounds.size.height - kXAxisHeight) * count / _histogram.largestSampleCount;
    [[NSBezierPath bezierPathWithRect:CGRectMake(x-.5, kXAxisHeight, 1, height)] fill];
}

- (void)drawCounts {
    [NSColor.blackColor setFill];

    size_t binCount = _histogram.binCount;
    double binWidth = _histogram.binWidth;
    [self drawCount:_histogram.bins[0] forSample:_histogram.minimumSample - binWidth / 2];
    [self drawCount:_histogram.bins[binCount - 1] forSample:_histogram.maximumSample + binWidth / 2];
    for (size_t i = 0; i < binCount; ++i) {
        [self drawCount:_histogram.bins[i] forSample:[_histogram minimumSampleOfBinAtIndex:i] + binWidth / 2];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    [NSColor.whiteColor setFill];
    [NSBezierPath fillRect:dirtyRect];
    [self drawXAxis];
    [self drawCounts];
}

@end
