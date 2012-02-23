#import "FirstResponderAcceptingView.h"
#import "AppDelegate.h"

@implementation FirstResponderAcceptingView

@synthesize mouseMovedDelegate = _mouseMovedDelegate;

- (BOOL)acceptsFirstResponder {
    // Necessary to get NSMouseMoved events.
    return YES;
}

- (void)mouseMoved:(NSEvent *)theEvent {
    [_mouseMovedDelegate mouseMoved:theEvent];
}

@end
