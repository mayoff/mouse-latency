#import <Cocoa/Cocoa.h>

@class Histogram;

@interface HistogramView : NSView

@property (nonatomic, weak) Histogram *histogram;

@end
