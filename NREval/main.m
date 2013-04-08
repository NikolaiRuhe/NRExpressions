#import <Foundation/Foundation.h>
#import "NRExpressions.h"

int main (int argc, const char * argv[])
{
	if (argc > 2)
	{
		fprintf(stderr, "usage: %s [ file ]\n", argv[0]);
		return 1;
	}

	@autoreleasepool
	{
		
		NSFileHandle* input;
		if (argc == 1 || strcmp(argv[1], "-") == 0)
			input = [NSFileHandle fileHandleWithStandardInput];
		else
			input = [NSFileHandle fileHandleForReadingAtPath:[NSString stringWithUTF8String:argv[1]]];

		NSData *data = [input readDataToEndOfFile];
	    NSString *sourceString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

		__block int status = 0;
		id <NRXValue> result = [NRXInterpreter evaluateSourceString:sourceString
													 withErrorBlock:^(NSString *message, NSUInteger lineNumber) {
														 fprintf(stderr, "error in line %d: %s\n", (int)lineNumber, [message UTF8String]);
														 status = 1;
													 }
														 printBlock:^(id <NRXValue> output) {
															 fprintf(stdout, "%s\n", [[output description] UTF8String]);
														 }];

		if (result == nil)
			return status;

		if ([result isKindOfClass:[NRXError class]])
		{
			fprintf(stderr, "%s\n", [[result description] UTF8String]);
			return 2;
		}

		fprintf(stdout, "%s\n", [[result description] UTF8String]);
		return 0;
	}
}
