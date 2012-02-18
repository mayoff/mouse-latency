#import <Foundation/Foundation.h>

@interface Probe : NSObject

@property (nonatomic, copy) NSString *label;
@property (nonatomic) uint64_t *timePointer;

- (id)initWithLabel:(NSString *)label;

- (void)recordTime;

@end
