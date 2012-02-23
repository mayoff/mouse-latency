#import <Cocoa/Cocoa.h>
#import "FirstResponderAcceptingView.h"

@class HistogramView;

extern uint64_t volatile latestDisplayLinkTime;

@interface AppDelegate : NSObject <NSApplicationDelegate, MouseMovedDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSButton *checkbox_enableMouseCoalescing;
@property (weak) IBOutlet HistogramView *histogramView;

@end
