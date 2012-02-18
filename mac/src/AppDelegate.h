#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet NSTextView *logView;

@property (unsafe_unretained) IBOutlet NSButton *checkbox_IOHIDDeviceRegisterInputReportCallback;
@property (unsafe_unretained) IBOutlet NSButton *checkbox_kCGHIDEventTap;
@property (unsafe_unretained) IBOutlet NSButton *checkbox_kCGSessionEventTap;
@property (unsafe_unretained) IBOutlet NSButton *checkbox_kCGAnnotatedSessionEventTap;
@property (unsafe_unretained) IBOutlet NSButton *checkbox_sendEvent;
@property (unsafe_unretained) IBOutlet NSButton *checkbox_kCGHIDEventTap_ListenOnly;
@property (unsafe_unretained) IBOutlet NSButton *checkbox_kCGSessionEventTap_ListenOnly;
@property (unsafe_unretained) IBOutlet NSButton *checkbox_kCGAnnotatedSessionEventTap_ListenOnly;
@property (unsafe_unretained) IBOutlet NSButton *runButton;

@end
