#import "Probe.h"

@implementation Probe

@synthesize label = _label;
@synthesize timePointer = _timePointer;

- (id)initWithLabel:(NSString *)label
{
    if (!(self = [super init]))
        return nil;

    self.label = label;

    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p %@>", self.className, self, self.label];
}

- (void)recordTime {
    *_timePointer = mach_absolute_time();
}

@end
