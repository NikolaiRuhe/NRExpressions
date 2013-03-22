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

@end



@implementation NSNull (NRXValueAdditions)
+ (NSString *)nrx_typeString
{
	return @"Null";
}
@end

@implementation NSArray (NRXValueAdditions)
+ (NSString *)nrx_typeString
{
	return @"List";
}
- (NSDecimalNumber *)nrx_count
{
	return [NSDecimalNumber decimalNumberWithMantissa:[self count] exponent:0 isNegative:NO];
}
@end

@implementation NSString (NRXValueAdditions)
+ (NSString *)nrx_typeString
{
	return @"String";
}
- (NSDecimalNumber *)nrx_len
{
	return [NSDecimalNumber decimalNumberWithMantissa:[self length] exponent:0 isNegative:NO];
}
- (id <NRXValue>)nrx_addition:(id <NRXValue>)argument
{
	if ([argument isKindOfClass:[NSString class]])
		return [self stringByAppendingString:(NSString *)argument];
	return [NRXArgumentError errorWithFormat:@"operand mismatch in addition"];
}
@end

@implementation NSDecimalNumber (NRXValueAdditions)
+ (NSString *)nrx_typeString
{
	return @"Number";
}
- (id <NRXValue>)nrx_negation
{
	NSDecimal decimal = [self decimalValue];
	decimal._isNegative = decimal._isNegative ? 0 : 1;
	return [NSDecimalNumber decimalNumberWithDecimal:decimal];
}
- (id <NRXValue>)nrx_addition:(id <NRXValue>)argument
{
	if ([argument isKindOfClass:[NSDecimalNumber class]])
		return [self decimalNumberByAdding:(NSDecimalNumber *)argument];
	return [NRXArgumentError errorWithFormat:@"operand mismatch in addition"];
}
- (id <NRXValue>)nrx_subtraction:(id <NRXValue>)argument
{
	if ([argument isKindOfClass:[NSDecimalNumber class]])
		return [self decimalNumberBySubtracting:(NSDecimalNumber *)argument];
	return [NRXArgumentError errorWithFormat:@"operand mismatch in subtraction"];
}
- (id <NRXValue>)nrx_multiplication:(id <NRXValue>)argument
{
	if ([argument isKindOfClass:[NSDecimalNumber class]])
		return [self decimalNumberByMultiplyingBy:(NSDecimalNumber *)argument];
	return [NRXArgumentError errorWithFormat:@"operand mismatch in multiplication"];
}
- (id <NRXValue>)nrx_division:(id <NRXValue>)argument
{
	if (! [argument isKindOfClass:[NSDecimalNumber class]])
		return [NRXArgumentError errorWithFormat:@"operand mismatch in division"];
	NSDecimal left = [self decimalValue];
	NSDecimal right = [(NSDecimalNumber *)argument decimalValue];
	NSDecimal result;
	NSCalculationError status = NSDecimalDivide(&result, &left, &right, NSRoundPlain);
	if (status == NSCalculationDivideByZero)
		return [NRXMathError errorWithFormat:@"division by zero"];
	return [NSDecimalNumber decimalNumberWithDecimal:result];
}
- (id <NRXValue>)nrx_modulus:(id <NRXValue>)argument
{
	if (! [argument isKindOfClass:[NSDecimalNumber class]])
		return [NRXArgumentError errorWithFormat:@"operand mismatch in modulus"];

	NSDecimal left = [self decimalValue];
	NSDecimal right = [(NSDecimalNumber *)argument decimalValue];

	if (right._isNegative)
		return [NRXMathError errorWithFormat:@"modulus with negative divisor"];

	NSDecimal fraction;
	NSCalculationError status = NSDecimalDivide(&fraction, &left, &right, NSRoundPlain);
	if (status == NSCalculationDivideByZero)
		return [NRXMathError errorWithFormat:@"division by zero"];

	fraction._isNegative = 0;
	NSDecimal integerFraction;
	NSDecimalRound(&integerFraction, &fraction, 0, NSRoundDown);

	NSDecimal factor;
	NSDecimalMultiply(&factor, &integerFraction, &right, NSRoundPlain);

	factor._isNegative = left._isNegative;
	NSDecimal result;
	NSDecimalSubtract(&result, &left, &factor, NSRoundPlain);

	return [NSDecimalNumber decimalNumberWithDecimal:result];
}
- (NSComparisonResult)nrx_compare:(id <NRXValue>)argument error:(NRXError * __autoreleasing *)error
{
	if (! [argument isKindOfClass:[NSDecimalNumber class]]) {
		if (error != NULL) {
			*error = [NRXArgumentError errorWithFormat:@"operand mismatch in comparison"];
			return NSOrderedSame;
		}
	}

	if (error != NULL)
		*error = nil;

	return [self compare:(NSDecimalNumber *)argument];
}
@end

@implementation NRXBoolean

+ (id)allocWithZone:(NSZone *)zone
{
	NSAssert(NO, @"can not allocate NRXBoolean class");
	return nil;
}

+ (NRXBoolean *)yes
{
	static NRXBoolean *yes = nil;
	if (yes == nil)
		yes = [[super allocWithZone:nil] init];
	return yes;
}

+ (NRXBoolean *)no
{
	static NRXBoolean *no = nil;
	if (no == nil)
		no = [[super allocWithZone:nil] init];
	return no;
}

+ (NRXBoolean *)booleanWithBool:(BOOL)value
{
	return value ? [self yes] : [self no];
}

- (BOOL)boolValue
{
	return self == [[self class] yes];
}

@end


@implementation NRXInterruptExecutionResult
@end



@implementation NRXReturnResult

@synthesize value = _value;

- (id)initWithValue:(id <NRXValue>)value
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



@implementation NRXNode

- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

@end
