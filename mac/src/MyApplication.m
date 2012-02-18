#import "MyApplication.h"
#import "MyNSEventProbe.h"

@implementation MyApplication

@synthesize eventProbe = _eventProbe;

- (void)sendEvent:(NSEvent *)theEvent {
    if (_eventProbe && theEvent.type == NSMouseMoved)
        [_eventProbe didReceiveMouseMoved];
    [super sendEvent:theEvent];
}

@end
