//
//  NRExpressions
//
//  Author: Nikolai Ruhe
//  Copyright (c) 2013 Nikolai Ruhe. All rights reserved.
//

#import "NRXError.h"



@implementation NRXError

@synthesize reason = _reason;

- (id)initWithReason:(NSString *)reason
{
	self = [self init];
	if (self != nil)
	{
		_reason = [reason copy];
	}
	return self;
}

+ (NRXError *)errorWithFormat:(NSString *)format, ...
{
	va_list arguments;
	va_start(arguments, format);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-nonliteral"
	NSString *reason = [[NSString alloc] initWithFormat:format arguments:arguments];
#pragma clang diagnostic pop
	va_end(arguments);
	return [[self alloc] initWithReason:reason];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@: %@", [[self class] nrx_typeString], self.reason];
}

@end



@implementation NRXParserError      @end
@implementation NRXSyntaxError      @end

@implementation NRXRuntimeError     @end
@implementation NRXInterpreterError @end
@implementation NRXMathError        @end
@implementation NRXLookupError      @end
@implementation NRXArgumentError    @end
@implementation NRXTypeError        @end
@implementation NRXAssertionError   @end
@implementation NRXConversionError  @end
@implementation NRXCustomError      @end
