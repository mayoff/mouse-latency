#import <AppKit/AppKit.h>

@class MyNSEventProbe;

@interface MyApplication : NSApplication

@property (nonatomic, unsafe_unretained) MyNSEventProbe *eventProbe;

@end
