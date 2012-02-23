#import <Cocoa/Cocoa.h>

@protocol MouseMovedDelegate <NSObject>

- (void)mouseMoved:(NSEvent *)event;

@end

@interface FirstResponderAcceptingView : NSView

@property (nonatomic, weak) IBOutlet NSObject<MouseMovedDelegate> *mouseMovedDelegate;

@end
