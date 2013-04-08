#import "NRAppDelegate.h"
#import "NRExpressions.h"



@implementation NRAppDelegate

@synthesize window = _window;
@synthesize expressionField = _expressionField;
@synthesize resultField = _resultField;

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	NSString *sourceString = [[NSUserDefaults standardUserDefaults] objectForKey:@"sourceString"];
	if (sourceString == nil)
		sourceString = @"index := 0;\nwhile (index < 3) {\n\tprint index;\n\tindex := index + 1;\n}\n";
	[self.expressionField setStringValue:sourceString];
}

- (IBAction)evaluate:(id)sender
{
	[self.resultField setStringValue:@""];

	NSString *sourceString = [self.expressionField stringValue];
	id <NRXValue> value = [NRXInterpreter evaluateSourceString:sourceString
												withErrorBlock:NULL
													printBlock:^(id value) {
														NSMutableAttributedString *result = [[self.resultField attributedStringValue] mutableCopy];
														NSDictionary *style = [NSDictionary dictionaryWithObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
														NSAttributedString *string = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", value]
																													 attributes:style];
														[result appendAttributedString:string];
														[self.resultField setAttributedStringValue:result];
													}];

	NSMutableAttributedString *result = [[self.resultField attributedStringValue] mutableCopy];
	NSColor *color = [value isKindOfClass:[NRXError class]] ? [NSColor colorWithDeviceRed:0.9 green:0 blue:0 alpha:1] : [NSColor colorWithDeviceRed:0 green:0.6 blue:0 alpha:1];
	NSDictionary *style = [NSDictionary dictionaryWithObject:color
													  forKey:NSForegroundColorAttributeName];
	NSAttributedString *string = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"result: %@\n", value]
																 attributes:style];
	[result appendAttributedString:string];
	[self.resultField setAttributedStringValue:result];
}

- (IBAction)save:(id)sender
{
	NSString *sourceString = [self.expressionField stringValue];
	[[NSUserDefaults standardUserDefaults] setObject:sourceString forKey:@"sourceString"];
}

@end
