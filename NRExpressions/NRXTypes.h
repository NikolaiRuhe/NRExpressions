//
//  NRExpressions
//
//  Author: Nikolai Ruhe
//  Copyright (c) 2013 Nikolai Ruhe. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NRXInterpreter, NRXError;


// Common value functionality. This can be used to bridge to Objective-C objects.
@protocol NRXValue <NSObject>
@optional

+ (NSString *)nrx_typeString;
- (NSString *)nrx_typeString;

- (id <NRXValue>)nrx_promoteToValue;

- (id <NRXValue>)nrx_negation;

- (id <NRXValue>)nrx_addition:(id <NRXValue>)argument;
- (id <NRXValue>)nrx_subtraction:(id <NRXValue>)argument;
- (id <NRXValue>)nrx_multiplication:(id <NRXValue>)argument;
- (id <NRXValue>)nrx_division:(id <NRXValue>)argument;
- (id <NRXValue>)nrx_modulus:(id <NRXValue>)argument;

- (NSComparisonResult)nrx_compare:(id <NRXValue>)argument error:(NRXError * __autoreleasing *)error;

@end


@interface NSNull (NRXValueAdditions) <NRXValue>
@end

@interface NSArray (NRXValueAdditions) <NRXValue>
- (NSDecimalNumber *)nrx_count;
@end

@interface NSString (NRXValueAdditions) <NRXValue>
- (NSDecimalNumber *)nrx_len;
@end

@interface NSDate (NRXValueAdditions) <NRXValue>
@end

@interface NSDecimalNumber (NRXValueAdditions) <NRXValue>
- (id <NRXValue>)nrx_negation;
- (id <NRXValue>)nrx_addition:(id <NRXValue>)argument;
- (id <NRXValue>)nrx_subtraction:(id <NRXValue>)argument;
- (id <NRXValue>)nrx_multiplication:(id <NRXValue>)argument;
- (id <NRXValue>)nrx_division:(id <NRXValue>)argument;
- (id <NRXValue>)nrx_modulus:(id <NRXValue>)argument;
- (NSComparisonResult)nrx_compare:(id <NRXValue>)argument error:(NRXError * __autoreleasing *)error;
@end

@interface NRXBoolean : NSObject <NRXValue>
+ (NRXBoolean *)yes;
+ (NRXBoolean *)no;
+ (NRXBoolean *)booleanWithBool:(BOOL)value;
- (BOOL)boolValue;
@end


@interface NRXInterruptExecutionResult : NSObject <NRXValue> @end

// NRXReturnResult is a special value class, that serves to identify function returns.
// It is used to return from nested scopes to function level and to carry the return
// statement's expression value.
@interface NRXReturnResult : NRXInterruptExecutionResult
@property (nonatomic, retain) id <NRXValue> value;
- (id)initWithValue:(id <NRXValue>)value;
@end

@interface NRXBreakResult    : NRXInterruptExecutionResult @end
@interface NRXContinueResult : NRXInterruptExecutionResult @end
@interface NRXTimeoutResult  : NRXInterruptExecutionResult @end


// The parser creates an abstract syntax tree from source code. The syntax tree
// consists of objects conforming to NRXStatementNode or NRXExpressionNode.
// AST nodes are immutable representations of code fragments.
@interface NRXNode : NSObject
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter;
@end



#define EVALUATE_EXPRESSION(var, node) \
id <NRXValue> var = [(node) evaluate:interpreter]; \
assert(! [var isKindOfClass:[NRXReturnResult class]]); \
if ([var isKindOfClass:[NRXInterruptExecutionResult class]]) \
	return var;

#define EVALUATE_VALUE(var, node) \
id <NRXValue> var = [(node) evaluate:interpreter]; \
if ([var isKindOfClass:[NRXInterruptExecutionResult class]]) \
	return var; \
if ([var respondsToSelector:@selector(nrx_promoteToValue)]) \
	var = [var nrx_promoteToValue];


#define EVALUATE_BOOL_EXPRESSION(var, node) \
BOOL var; \
{ \
	EVALUATE_VALUE(value, (node)) \
	if (! [value isKindOfClass:[NRXBoolean class]]) \
		return [NRXTypeError errorWithFormat:@"type error: boolean expression expected, got %@", [value nrx_typeString]]; \
	var = [(id)value boolValue]; \
}

#define EVALUATE_STATEMENT(node) \
{ \
	id <NRXValue> evaluated_value = [(node) evaluate:interpreter]; \
	if ([evaluated_value isKindOfClass:[NRXInterruptExecutionResult class]]) \
		return evaluated_value; \
}
