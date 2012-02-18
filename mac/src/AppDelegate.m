#import "AppDelegate.h"
#import "InputReportProbe.h"
#import "EventTapProbe.h"
#import "MyNSEventProbe.h"

#define toCF (__bridge void *)
#define fromCF (__bridge id)

static void release(CFTypeRef ref) {
    if (ref)
        CFRelease(ref);
}

@implementation AppDelegate {
    IOHIDManagerRef _manager;
    IOHIDDeviceRef _device;
    NSMutableArray *_probes;
    NSTimer *_timer;
    NSMutableData *_probeTimeData;
    uint64_t *_probeTimePointer;
    unsigned int _ticksTotal;
    unsigned int _ticksExecuted;
}

@synthesize window = _window;
@synthesize logView = _logView;
@synthesize checkbox_IOHIDDeviceRegisterInputReportCallback = _checkbox_IOHIDDeviceRegisterInputReportCallback;
@synthesize checkbox_kCGHIDEventTap = _checkbox_kCGHIDEventTap;
@synthesize checkbox_kCGSessionEventTap = _checkbox_kCGSessionEventTap;
@synthesize checkbox_kCGAnnotatedSessionEventTap = _checkbox_kCGAnnotatedSessionEventTap;
@synthesize checkbox_sendEvent = _checkbox_sendEvent;
@synthesize checkbox_kCGHIDEventTap_ListenOnly = _checkbox_kCGHIDEventTap_ListenOnly;
@synthesize checkbox_kCGSessionEventTap_ListenOnly = _checkbox_kCGSessionEventTap_ListenOnly;
@synthesize checkbox_kCGAnnotatedSessionEventTap_ListenOnly = _checkbox_kCGAnnotatedSessionEventTap_ListenOnly;
@synthesize runButton = _runButton;

- (BOOL)initDevice {
    _manager = IOHIDManagerCreate(NULL, kIOHIDOptionsTypeNone);
    NSDictionary *matchingDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                        @"Rob Mayoff", @kIOHIDManufacturerKey,
                                        @"Mouse Imposter", @kIOHIDProductKey,
                                        nil];
    IOHIDManagerSetDeviceMatching(_manager, toCF matchingDictionary);
    IOReturn rc = IOHIDManagerOpen(_manager, kIOHIDOptionsTypeNone);
    NSCAssert(rc == kIOReturnSuccess, @"IOHIDManagerOpen failed: %d", rc);
    NSSet *devices = CFBridgingRelease(IOHIDManagerCopyDevices(_manager));
    _device = toCF devices.anyObject;
    if (!_device) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"No mouse imposter tester found" defaultButton:@"Bummer" alternateButton:nil otherButton:nil informativeTextWithFormat:@"I couldn't find a mouse imposter.  Are you sure your Teensy is plugged in and running the mouse imposter program?", nil];
        [alert runModal];
        return NO;
    }
    CFRetain(_device);
    return YES;
}

- (void)destroyDevice {
    if (_device) {
        CFRelease(_device);
        _device = NULL;
    }
    if (_manager) {
        IOHIDManagerClose(_manager, kIOHIDOptionsTypeNone);
        CFRelease(_manager);
        _manager = NULL;
    }
}

- (void)updateRunButtonTitle {
    if (_ticksExecuted < _ticksTotal)
        self.runButton.title = [NSString stringWithFormat:@"%u", _ticksTotal - _ticksExecuted];
    else
        self.runButton.title = @"Run";
}

- (void)reportLatencies {
    uint64_t *probeTimePointer = _probeTimeData.mutableBytes;
    NSMutableString *string = [NSMutableString string];

    char *separator = "";
    for (Probe *probe in _probes) {
        [string appendFormat:@"%s%@", separator, probe.label];
        separator = "\t";
    }
    [string appendString:@"\n"];

    for (unsigned int i = 0; i < _ticksTotal; ++i) {
        uint64_t pingTime = *probeTimePointer++;
        separator = "";
        for (Probe *probe in _probes) {
            uint64_t probeTime = *probeTimePointer++;
            uint64_t latencyNative = probeTime - pingTime;
            Nanoseconds latencyNanosecondsStruct = AbsoluteToNanoseconds(*(AbsoluteTime *)&latencyNative);
            double latencyMilliseconds = *(uint64_t *)&latencyNanosecondsStruct / (double)NSEC_PER_MSEC;
            [string appendFormat:@"%s%9.6f", separator, latencyMilliseconds];
            separator = "\t";
        }
        [string appendString:@"\n"];
    }
    
    [self.logView.textStorage.mutableString setString:string];
    [self.logView selectAll:self];
}

- (void)stop {
    _ticksExecuted = _ticksTotal;
    [_timer invalidate];
    _timer = nil;

    [self reportLatencies];
    [self updateRunButtonTitle];
    [self.runButton setEnabled:YES];
    _probes = nil;
    [self destroyDevice];    
}

- (void)timerDidFire:(NSTimer *)timer {
    if (_ticksExecuted == _ticksTotal) {
        [self stop];
        return;
    }

    ++_ticksExecuted;
    [self updateRunButtonTitle];
    [self.window displayIfNeeded]; // Do this now so it can't delay the probes
    
    uint64_t *startTime = _probeTimePointer++;
    for (Probe *probe in _probes) {
        probe.timePointer = _probeTimePointer++;
    }

    uint8_t const report = 'r';
    *startTime = mach_absolute_time();
    IOHIDDeviceSetReport(_device, kIOHIDReportTypeOutput, 0, &report, sizeof report);
}

- (IBAction)run:(id)sender {
    if (_timer)
        return;

    @autoreleasepool {
        
        if (![self initDevice])
            return;
        
        _probes = [NSMutableArray array];
        if (self.checkbox_IOHIDDeviceRegisterInputReportCallback.state == NSOnState)
            [_probes addObject:[[InputReportProbe alloc] initWithLabel:@"report" device:_device]];
        if (self.checkbox_kCGHIDEventTap.state == NSOnState)
            [_probes addObject:[[EventTapProbe alloc] initWithLabel:@"hidtap" location:kCGHIDEventTap options:kCGEventTapOptionDefault]];
        if (self.checkbox_kCGSessionEventTap.state == NSOnState)
            [_probes addObject:[[EventTapProbe alloc] initWithLabel:@"sessiontap" location:kCGSessionEventTap options:kCGEventTapOptionDefault]];
        if (self.checkbox_kCGAnnotatedSessionEventTap.state == NSOnState)
            [_probes addObject:[[EventTapProbe alloc] initWithLabel:@"annotatedsessiontap" location:kCGAnnotatedSessionEventTap options:kCGEventTapOptionDefault]];
        if (self.checkbox_sendEvent.state == NSOnState)
            [_probes addObject:[[MyNSEventProbe alloc] initWithLabel:@"nsevent"]];
        if (self.checkbox_kCGHIDEventTap_ListenOnly.state == NSOnState)
            [_probes addObject:[[EventTapProbe alloc] initWithLabel:@"hidtap-listen" location:kCGHIDEventTap options:kCGEventTapOptionListenOnly]];
        if (self.checkbox_kCGSessionEventTap_ListenOnly.state == NSOnState)
            [_probes addObject:[[EventTapProbe alloc] initWithLabel:@"sessiontap-listen" location:kCGSessionEventTap options:kCGEventTapOptionListenOnly]];
        if (self.checkbox_kCGAnnotatedSessionEventTap_ListenOnly.state == NSOnState)
            [_probes addObject:[[EventTapProbe alloc] initWithLabel:@"annotatedsessiontap-listen" location:kCGAnnotatedSessionEventTap options:kCGEventTapOptionListenOnly]];
        
        if (!_probes.count) {
            [self destroyDevice];
            NSAlert *alert = [NSAlert alertWithMessageText:@"No probes enabled" defaultButton:@"Oops" alternateButton:nil otherButton:nil informativeTextWithFormat:@"You need to enable at least one probe before running the test.", nil];
            [alert runModal];
            return;
        }
        
        [self.runButton setEnabled:NO];
    }
    
    static CFTimeInterval const duration = 20;
    static CFTimeInterval const ticksPerSecond = 10;
    _ticksTotal = duration * ticksPerSecond;
    _ticksExecuted = 0;

    _probeTimeData = [[NSMutableData alloc] initWithLength:_ticksTotal * (_probes.count + 1) * sizeof(uint64_t)];
    _probeTimePointer = _probeTimeData.mutableBytes;

    [self updateRunButtonTitle];
    _timer = [NSTimer scheduledTimerWithTimeInterval:1 / ticksPerSecond target:self selector:@selector(timerDidFire:) userInfo:nil repeats:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self.window setAcceptsMouseMovedEvents:YES];
}

- (void)windowWillClose:(NSNotification *)notification {
    [NSApp terminate:self];
}

@end
