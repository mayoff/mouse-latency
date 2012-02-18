#import "Probe.h"

@interface EventTapProbe : Probe

- (id)initWithLabel:(NSString *)label location:(CGEventTapLocation)location options:(CGEventTapOptions)options;

@end
