#import "MyNSEventProbe.h"
#import "MyApplication.h"

@implementation MyNSEventProbe

- (void)didReceiveMouseMoved {
    [self recordTime];
}

- (id)initWithLabel:(NSString *)label
{
    if (!(self = [super initWithLabel:label]))
        return nil;

    ((MyApplication *)NSApp).eventProbe = self;

    return self;
}

- (void)dealloc {
    ((MyApplication *)NSApp).eventProbe = nil;
}

@end
