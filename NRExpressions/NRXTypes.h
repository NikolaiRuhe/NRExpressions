//
//  NRExpressions
//
//  Author: Nikolai Ruhe
//  Copyright (c) 2013 Nikolai Ruhe. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NRXInterpreter;



typedef NSObject NRXValue;


// Add common value functionality to all NSObjects. This bridges to Objective-C objects.
@interface NSObject (NRXValueAdditions)
+ (NSString *)nrx_typeString;
- (NSString *)nrx_typeString;
- (NRXValue *)nrx_valueForKey:(NSString *)key;
- (NRXValue *)nrx_setValue:(NRXValue *)value forKey:(NSString *)key;
@end



@interface NRXInterruptExecutionResult : NRXValue @end

// NRXReturnResult is a special value class, that serves to identify function returns.
// It is used to return from nested scopes to function level and to carry the return
// statement's expression value.
@interface NRXReturnResult : NRXInterruptExecutionResult
@property (nonatomic, retain) NRXValue *value;
- (id)initWithValue:(NRXValue *)value;
@end

@interface NRXBreakResult    : NRXInterruptExecutionResult @end
@interface NRXContinueResult : NRXInterruptExecutionResult @end
@interface NRXTimeoutResult  : NRXInterruptExecutionResult @end


// The parser creates an abstract syntax tree from source code. The syntax tree
// consists of objects conforming to NRXStatementNode or NRXExpressionNode.
// AST nodes are immutable representations of code fragments.
@interface NRXNode : NSObject
- (NRXValue *)evaluate:(NRXInterpreter *)interpreter;
@end



#define EVALUATE_EXPRESSION(var, node) \
NRXValue *var = [(node) evaluate:interpreter]; \
assert(! [var isKindOfClass:[NRXReturnResult class]]); \
if ([var isKindOfClass:[NRXInterruptExecutionResult class]]) \
	return var;

#define EVALUATE_EXPRESSION_OF_TYPE(var, node, expectedClass) \
EVALUATE_EXPRESSION(var, (node)) \
if (! [var isKindOfClass:expectedClass]) \
	return [NRXTypeError errorWithFormat:@"type error: %@ expected, got %@", [expectedClass nrx_typeString], [var nrx_typeString]];

#define EVALUATE_LIST_EXPRESSION(var, node) \
NSMutableArray *var; \
{ \
	EVALUATE_EXPRESSION_OF_TYPE(value, (node), [NSMutableArray class]); \
	var = (NSMutableArray *)value; \
}

#define EVALUATE_NUMBER_EXPRESSION(var, node) \
NSNumber *var; \
{ \
	EVALUATE_EXPRESSION_OF_TYPE(value, (node), [NSNumber class]); \
	var = (NSNumber *)value; \
}

#define EVALUATE_BOOL_EXPRESSION(var, node) \
BOOL var; \
{ \
	EVALUATE_EXPRESSION(value, (node)) \
	if (! [value respondsToSelector:@selector(boolValue)]) \
		return [NRXTypeError errorWithFormat:@"type error: boolean expression expected, got %@", [value nrx_typeString]]; \
	var = [(id)value boolValue]; \
}

#define EVALUATE_DOUBLE_EXPRESSION(var, node) \
double var; \
{ \
	EVALUATE_EXPRESSION_OF_TYPE(value, (node), [NSNumber class]); \
	var = [(NSNumber *)value doubleValue]; \
}

#define EVALUATE_STATEMENT(node) \
{ \
	NRXValue *evaluated_value = [(node) evaluate:interpreter]; \
	if ([evaluated_value isKindOfClass:[NRXInterruptExecutionResult class]]) \
		return evaluated_value; \
}
