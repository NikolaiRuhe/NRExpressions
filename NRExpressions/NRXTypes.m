//
//  NRExpressions
//
//  Author: Nikolai Ruhe
//  Copyright (c) 2013 Nikolai Ruhe. All rights reserved.
//

#import "NRXError.h"
#import "NRXInterpreter.h"
#import "NRXStatementNode.h"


@implementation NSObject (NRXValueAdditions)

+ (NSString *)nrx_typeString
{
	NSString *name = NSStringFromClass(self);
	if ([name hasPrefix:@"NRX"]) {
		name = [name substringFromIndex:3];
	}
	return name;
}

- (NSString *)nrx_typeString
{
	return [[self class] nrx_typeString];
}

- (NRXValue *)nrx_valueForKey:(NSString *)key
{
	return [NRXLookupError errorWithFormat:@"no member '%@' on object of type %@", key, [self nrx_typeString]];
}

- (NRXValue *)nrx_setValue:(NRXValue *)value forKey:(NSString *)key
{
	return [NRXLookupError errorWithFormat:@"can not set '%@' on object of type %@", key, [self nrx_typeString]];
}

@end



@implementation NRXInterruptExecutionResult
@end



@implementation NRXReturnResult

@synthesize value = _value;

- (id)initWithValue:(NRXValue *)value
{
	self = [self init];
	if (self != nil)
	{
		_value = value;
	}
	return self;
}

@end

@implementation NRXBreakResult    @end
@implementation NRXContinueResult @end
@implementation NRXTimeoutResult  @end



@implementation NSNumber (NRXAdditions)

+ (NSString *)nrx_typeString
{
	return @"Number";
}

@end



@implementation NSString (NRXAdditions)

+ (NSString *)nrx_typeString
{
	return @"String";
}

- (NSNumber *)nrx_len
{
	return [NSNumber numberWithUnsignedInteger:[self length]];
}

@end



@implementation NSMutableArray (NRXAdditions)

+ (NSString *)nrx_typeString
{
	return @"List";
}

- (NSNumber *)nrx_count
{
	return [NSNumber numberWithUnsignedInteger:[self count]];
}

- (NRXValue *)nrx_appendWithArguments:(NSArray *)arguments
{
	// TODO: implement universal method call bridge
	if ([arguments count] == 0)
		return [NRXArgumentError errorWithFormat:@"list.append with zero arguments"];
	[self addObjectsFromArray:arguments];
	return nil;
}

@end



@implementation NSNull (NRXAdditions)

+ (NSString *)nrx_typeString
{
	return @"Null";
}

@end



@implementation NRXNode

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

@end
