#import "AppDelegate.h"
#import "Histogram.h"
#import "HistogramView.h"

uint64_t volatile latestDisplayLinkTime;

static uint64_t volatile movesSinceLastDisplayLink;

static dispatch_queue_t displayLinkQueue;

static CVReturn displayLinkOutputCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *inNow,  const CVTimeStamp *inOutputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext) {
    dispatch_sync(displayLinkQueue, ^{
        if (movesSinceLastDisplayLink > 1)
            NSLog(@"moves since last display link = %llu", movesSinceLastDisplayLink);
        latestDisplayLinkTime = inNow->hostTime;
        movesSinceLastDisplayLink = 0;
    });
    return kCVReturnSuccess;
}

@implementation AppDelegate {
    CVDisplayLinkRef _displayLink;
    Histogram *_histogram;
    NSTimer *_timer;
}

@synthesize window = _window;
@synthesize checkbox_enableMouseCoalescing = _checkbox_enableMouseCoalescing;
@synthesize histogramView = _histogramView;

- (void)awakeFromNib {
    _histogram = [[Histogram alloc] initWithMinimumSample:-.020 maximumSample:.020 binWidth:.00025];
    _histogramView.histogram = _histogram;

    self.window.acceptsMouseMovedEvents = YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self.window makeKeyAndOrderFront:self];
    
    displayLinkQueue = dispatch_queue_create("com.dqd.coalescetest.displayLinkSerialization", 0);
    CVDisplayLinkCreateWithCGDisplay(CGMainDisplayID(), &_displayLink);
    CVDisplayLinkSetOutputCallback(_displayLink, displayLinkOutputCallback, NULL);
    CVDisplayLinkStart(_displayLink);
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerDidFire:) userInfo:nil repeats:YES];
}

- (void)dealloc {
    CVDisplayLinkStop(_displayLink);
    CVDisplayLinkRelease(_displayLink);
    dispatch_release(displayLinkQueue);
}

- (IBAction)updateMouseCoalescing:(id)sender {
    [NSEvent setMouseCoalescingEnabled:self.checkbox_enableMouseCoalescing.state == NSOnState];
}

- (void)mouseMoved:(NSEvent *)theEvent {
    dispatch_sync(displayLinkQueue, ^{
        ++movesSinceLastDisplayLink;
        int64_t latency = CGEventGetTimestamp(theEvent.CGEvent) - latestDisplayLinkTime;
        [_histogram addSample:(double)latency / NSEC_PER_SEC];
    });
}

- (void)timerDidFire:(NSTimer *)timer {
    [self.histogramView setNeedsDisplay:YES];
}

- (IBAction)reset:(id)sender {
    dispatch_sync(displayLinkQueue, ^{
        [_histogram reset];
    });
    [self.histogramView setNeedsDisplay:YES];
}

@end
