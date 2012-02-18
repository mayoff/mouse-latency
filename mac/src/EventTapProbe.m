#import "EventTapProbe.h"

@implementation EventTapProbe {
    CFMachPortRef _port;
    CFRunLoopSourceRef _source;
}

static CGEventRef eventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *userInfo) {
    [(__bridge EventTapProbe *)userInfo recordTime];
    return event;
}

- (id)initWithLabel:(NSString *)label location:(CGEventTapLocation)location options:(CGEventTapOptions)options
{
    if (!(self = [super initWithLabel:label]))
        return nil;

    _port = CGEventTapCreate(location, kCGTailAppendEventTap, options, CGEventMaskBit(kCGEventMouseMoved), eventTapCallback, (__bridge void *)self);
    _source = CFMachPortCreateRunLoopSource(NULL, _port, 0);
    CFRunLoopAddSource(CFRunLoopGetMain(), _source, kCFRunLoopCommonModes);

    return self;
}

- (void)dealloc {
    if (_source) {
        CFRunLoopRemoveSource(CFRunLoopGetMain(), _source, kCFRunLoopCommonModes);
        CFRelease(_source);
    }
    if (_port) {
        // It seems that I must invalidate the event tap to make WindowServer truly destroy it.  Otherwise, repeated runs eventually produce a spinning beachball of death.  The CGEventTapEnable is just for good measure.  I don't know if it helps.
        CGEventTapEnable(_port, false);
        CFMachPortInvalidate(_port);
        CFRelease(_port);
    }
}

@end
