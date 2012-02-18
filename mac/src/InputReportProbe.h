#import "Probe.h"

@interface InputReportProbe : Probe

- (id)initWithLabel:(NSString *)label device:(IOHIDDeviceRef)device;

@end
