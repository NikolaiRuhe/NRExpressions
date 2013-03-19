#import <Cocoa/Cocoa.h>

@interface NRAppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, assign) IBOutlet NSWindow *window;
@property (nonatomic, retain) IBOutlet NSTextField *expressionField;
@property (nonatomic, retain) IBOutlet NSTextField *resultField;

- (IBAction)evaluate:(id)sender;
- (IBAction)save:(id)sender;

@end
