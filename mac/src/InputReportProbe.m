#import "InputReportProbe.h"

@implementation InputReportProbe {
    IOHIDDeviceRef _device;
    uint8_t _reportData[64];
}

static void HIDReportCallback(void *context, IOReturn result, void *sender, IOHIDReportType type, uint32_t reportID, uint8_t *reportData, CFIndex reportLength) {
    [(__bridge InputReportProbe *)context recordTime];
}

- (id)initWithLabel:(NSString *)label device:(IOHIDDeviceRef)device
{
    if (!(self = [super initWithLabel:label]))
        return nil;

    CFRetain(device);
    _device = device;
    IOHIDDeviceScheduleWithRunLoop(_device, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    IOHIDDeviceRegisterInputReportCallback(_device, _reportData, sizeof _reportData, HIDReportCallback, (__bridge void *)self);

    return self;
}

- (void)dealloc {
    if (_device) {
        IOHIDDeviceUnscheduleFromRunLoop(_device, CFRunLoopGetMain(), kCFRunLoopCommonModes);
        CFRelease(_device);
    }
}

@end
