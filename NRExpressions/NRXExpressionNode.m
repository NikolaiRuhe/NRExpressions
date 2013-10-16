//
//  NRExpressions
//
//  Author: Nikolai Ruhe
//  Copyright (c) 2013 Nikolai Ruhe. All rights reserved.
//

#import "NRXExpressionNode.h"
#import "NRXInterpreter.h"
#import "NRXError.h"
#import "NRXStatementNode.h"



@implementation NRXExpressionNode
@end



@implementation NRXLiteralNode

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

- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	return self.value;
}

@end


@implementation NRXListLiteralNode

- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	assert([self.value isKindOfClass:[NSArray class]]);

	NSMutableArray *resultArray = [NSMutableArray array];
	for (NRXExpressionNode *element in (NSArray *)(self.value))
	{
		EVALUATE_EXPRESSION(elementValue, element);
		if (elementValue == nil)
			elementValue = [NSNull null];
		[resultArray addObject:elementValue];
	}
	
	return resultArray;
}

@end


@implementation NRXDictionaryLiteralNode

- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	assert([self.value isKindOfClass:[NSArray class]]);

	NSMutableDictionary *resultDictionary = [NSMutableDictionary dictionary];
	for (NSArray *keyValuePair in (NSArray *)(self.value))
	{
		EVALUATE_VALUE(key, keyValuePair[0], NO);
		if (! [key isKindOfClass:[NSString class]])
			return [NRXArgumentError errorWithFormat:@"Dictionary literal: key not a String: %@", key];

		EVALUATE_EXPRESSION(value,   keyValuePair[1]);
		if (value == nil)
			value = [NSNull null];

		[resultDictionary setObject:value forKey:(NSString *)key];
	}

	return resultDictionary;
}

@end



@implementation NRXLookupNode
{
	NSMutableArray *_tokenPairs;
}

- (id)initWithSingleLookup:(NSString *)token
{
	self = [self init];
	if (self != nil)
	{
		_tokenPairs = [[NSMutableArray alloc] init];
		[self appendLookup:token isMulti:NO];
	}
	return self;
}

- (id)initWithMultiLookup:(NSString *)token
{
	self = [self init];
	if (self != nil)
	{
		_tokenPairs = [[NSMutableArray alloc] init];
		[self appendLookup:token isMulti:YES];
	}
	return self;
}

- (void)appendLookup:(NSString *)token isMulti:(BOOL)isMulti
{
	[_tokenPairs addObject:@[@(isMulti), token]];
}

- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	return [interpreter lookupNode:self];
}

- (NSUInteger)tokenCount
{
	return [_tokenPairs count];
}

- (void)enumerateTokens:(void(^)(NSString *token, BOOL isMulti, BOOL *stop))block
{
	for (NSArray *tokenPair in _tokenPairs) {
		BOOL stop = NO;
		block(tokenPair[1], [tokenPair[0] boolValue], &stop);
		if (stop)
			break;
	}
}

@end



@implementation NRXSymbolNode

@synthesize name = _name;

- (id)initWithName:(NSString *)name
{
	self = [self init];
	if (self != nil)
	{
		_name = [name copy];
	}
	return self;
}

- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	return [interpreter resolveSymbol:self.name];
}

@end



@implementation NRXUnaryOperationNode

@synthesize argument = _argument;

- (id)initWithArgument:(NRXExpressionNode *)argument
{
	self = [self init];
	if (self != nil)
	{
		_argument  = argument;
	}
	return self;
}

- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

@end



@implementation NRXBinaryInfixOperationNode

@synthesize left = _left;
@synthesize right = _right;

- (id)initWithLeft:(NRXExpressionNode *)left right:(NRXExpressionNode *)right
{
	self = [self init];
	if (self != nil)
	{
		_left  = left;
		_right = right;
	}
	return self;
}

- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

@end



@implementation NRXCallNode

@synthesize callable = _callable;
@synthesize arguments = _arguments;

- (id)initWithCallable:(NRXExpressionNode *)callable arguments:(NSArray *)arguments
{
	self = [self init];
	if (self != nil)
	{
		_callable  = callable;
		_arguments = arguments;
	}
	return self;
}

- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(callable, self.callable);

	// TODO: implement universal method call bridge
	if (! [callable conformsToProtocol:@protocol(NRXCallable)])
		return [NRXArgumentError errorWithFormat:@"not a callable: %@", callable];

	// first evaluate all arguments in outer scope
	NSMutableArray *arguments = [NSMutableArray array];
	for (NRXExpressionNode *element in self.arguments)
	{
		EVALUATE_EXPRESSION(elementValue, element);
		if (elementValue == nil)
			elementValue = [NSNull null];
		[arguments addObject:elementValue];
	}

	@autoreleasepool {
		// then call callable with evaluated args
		return [((id<NRXCallable>)callable) callWithArguments:arguments interpreter:interpreter];
	}
}

@end




@implementation NRXSubscriptNode

@synthesize subscriptableExpression = _subscriptableExpression;
@synthesize subscriptExpression = _subscriptExpression;

- (id)initWithSubscriptableExpression:(NRXExpressionNode *)subscriptableExpression subscriptExpression:(NRXExpressionNode *)subscriptExpression
{
	self = [self init];
	if (self != nil)
	{
		_subscriptableExpression  = subscriptableExpression;
		_subscriptExpression = subscriptExpression;
	}
	return self;
}

- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(subscriptable, self.subscriptableExpression);
	EVALUATE_VALUE(subscript, self.subscriptExpression, NO);

	if (subscriptable == nil || subscriptable == [NSNull null])
		return nil;

	if ([subscriptable respondsToSelector:@selector(nrx_subscript:)])
		return [subscriptable nrx_subscript:subscript];

	return [NRXArgumentError errorWithFormat:@"subscript operator: object not subscriptable"];
}

@end



@implementation NRXPropertyAccessNode
{
	SEL _selector;
}

@synthesize object = _object;
@synthesize propertyName = _propertyName;

- (id)initWithObject:(NRXExpressionNode *)object propertyName:(NSString *)propertyName
{
	self = [self init];
	if (self != nil)
	{
		_object = object;
		_propertyName = [propertyName copy];
		_selector = NSSelectorFromString([@"nrx_" stringByAppendingString:self.propertyName]);
	}
	return self;
}

- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(object, self.object);

	if (object == nil || object == [NSNull null])
		return nil;

	if ([object respondsToSelector:_selector])
	{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		return [object performSelector:_selector];
#pragma clang diagnostic pop
	}

	if ([object respondsToSelector:@selector(nrx_valueForProperty:)])
	{
		return [object nrx_valueForProperty:self.propertyName];
	}

	return [NRXLookupError errorWithFormat:@"no member '%@' on object of type %@", self.propertyName, [object nrx_typeString]];
}

@end



@implementation NRXTernaryConditionNode

@synthesize condition = _condition;
@synthesize positiveExpression = _positiveExpression;
@synthesize negativeExpression = _negativeExpression;

- (id)initWithCondition:(NRXExpressionNode *)condition positiveExpression:(NRXExpressionNode *)positiveExpression negativeExpression:(NRXExpressionNode *)negativeExpression
{
	self = [self init];
	if (self != nil)
	{
		_condition  = condition;
		_positiveExpression = positiveExpression;
		_negativeExpression = negativeExpression;
	}
	return self;
}

- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_BOOL_EXPRESSION(condition, self.condition);
	if (condition)
	{
		EVALUATE_EXPRESSION(result, self.positiveExpression);
		return result;
	}
	EVALUATE_EXPRESSION(result, self.negativeExpression);
	return result;
}

@end



@implementation NRXWhereNode

@synthesize list = _list;
@synthesize variable = _variable;
@synthesize condition = _condition;

- (id)initWithList:(NRXExpressionNode *)list variable:(NSString *)variable condition:(NRXExpressionNode *)condition
{
	self = [self init];
	if (self != nil)
	{
		_list = list;
		_variable = [variable copy];
		_condition = condition;
	}
	return self;
}

- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_VALUE(list, self.list, YES);
	if (! [list isKindOfClass:[NSArray class]])
		return [NRXTypeError errorWithFormat:@"'where' operator: not a list, got %@", [list nrx_typeString]];

	NSMutableArray *result = [NSMutableArray arrayWithCapacity:[((NSArray *)list) count]];
	for (id <NRXValue> element in (NSArray *)list) {
		[interpreter pushScope];
		[interpreter assignValue:element toSymbol:self.variable];

		EVALUATE_BOOL_EXPRESSION(condition, self.condition);

		if (condition)
			[result addObject:element];

		[interpreter popScope];
	}

	return result;
}
@end



@implementation NRXNegationNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_VALUE(argument, self.argument, YES);
	if ([argument respondsToSelector:@selector(nrx_negation)])
		return [argument nrx_negation];
	return [NRXArgumentError errorWithFormat:@"negation not defined"];
}
@end




@implementation NRXAdditionNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_VALUE(left,  self.left,  YES);
	EVALUATE_VALUE(right, self.right, YES);

	if ([left respondsToSelector:@selector(nrx_addition:)])
		return [left nrx_addition:right];

	return [NRXArgumentError errorWithFormat:@"'+' operator: bad operands"];
}
@end

@implementation NRXSubtractionNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_VALUE(left,  self.left,  YES);
	EVALUATE_VALUE(right, self.right, YES);

	if ([left respondsToSelector:@selector(nrx_subtraction:)])
		return [left nrx_subtraction:right];

	return [NRXArgumentError errorWithFormat:@"'-' operator: bad operands"];
}
@end

@implementation NRXMultiplicationNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_VALUE(left,  self.left,  YES);
	EVALUATE_VALUE(right, self.right, YES);

	if ([left respondsToSelector:@selector(nrx_multiplication:)])
		return [left nrx_multiplication:right];

	return [NRXArgumentError errorWithFormat:@"'*' operator: bad operands"];
}
@end

@implementation NRXDivisionNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_VALUE(left,  self.left,  YES);
	EVALUATE_VALUE(right, self.right, YES);

	if ([left respondsToSelector:@selector(nrx_division:)])
		return [left nrx_division:right];

	return [NRXArgumentError errorWithFormat:@"'/' operator: bad operands"];
}
@end

@implementation NRXModulusNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_VALUE(left,  self.left,  YES);
	EVALUATE_VALUE(right, self.right, YES);

	if ([left respondsToSelector:@selector(nrx_modulus:)])
		return [left nrx_modulus:right];

	return [NRXArgumentError errorWithFormat:@"'%' operator: bad operands"];
}
@end

@implementation NRXLessThanNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_VALUE(left,  self.left,  NO);
	EVALUATE_VALUE(right, self.right, NO);

	NRXComparisonResult result = [left nrx_compare:right];
	if (result == NRXUnrelated)
		return [NRXArgumentError errorWithFormat:@"operand mismatch in comparison"];
	return [NRXBoolean booleanWithBool:result == NRXOrderedAscending];
}
@end

@implementation NRXGreaterThanNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_VALUE(left,  self.left,  NO);
	EVALUATE_VALUE(right, self.right, NO);

	NRXComparisonResult result = [left nrx_compare:right];
	if (result == NRXUnrelated)
		return [NRXArgumentError errorWithFormat:@"operand mismatch in comparison"];
	return [NRXBoolean booleanWithBool:result == NRXOrderedDescending];
}
@end

@implementation NRXGreaterOrEqualNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_VALUE(left,  self.left,  NO);
	EVALUATE_VALUE(right, self.right, NO);

	NRXComparisonResult result = [left nrx_compare:right];
	if (result == NRXUnrelated)
		return [NRXArgumentError errorWithFormat:@"operand mismatch in comparison"];
	return [NRXBoolean booleanWithBool:result != NRXOrderedAscending];
}
@end

@implementation NRXLessOrEqualNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_VALUE(left,  self.left,  NO);
	EVALUATE_VALUE(right, self.right, NO);

	NRXComparisonResult result = [left nrx_compare:right];
	if (result == NRXUnrelated)
		return [NRXArgumentError errorWithFormat:@"operand mismatch in comparison"];
	return [NRXBoolean booleanWithBool:result != NRXOrderedDescending];
}
@end

@implementation NRXNotEqualNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_VALUE(left,  self.left,  NO);
	EVALUATE_VALUE(right, self.right, NO);

	NRXComparisonResult result = [left nrx_compare:right];
	return [NRXBoolean booleanWithBool:result != NRXOrderedSame];
}
@end

@implementation NRXEqualNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_VALUE(left,  self.left,  NO);
	EVALUATE_VALUE(right, self.right, NO);

	NRXComparisonResult result = [left nrx_compare:right];
	return [NRXBoolean booleanWithBool:result == NRXOrderedSame];
}
@end

@implementation NRXLogicalAndNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_BOOL_EXPRESSION(left,  self.left);
	
	// care for short-circuiting right operand
	if (! left)
		return [NRXBoolean no];
	
	EVALUATE_BOOL_EXPRESSION(right, self.right);
	return [NRXBoolean booleanWithBool:right];
}
@end

@implementation NRXLogicalOrNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_BOOL_EXPRESSION(left,  self.left);
	
	// care for short-circuiting right operand
	if (left)
		return [NRXBoolean yes];
	
	EVALUATE_BOOL_EXPRESSION(right, self.right);
	return [NRXBoolean booleanWithBool:right];
}
@end

@implementation NRXLogicalNegationNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_BOOL_EXPRESSION(argument, self.argument);
	return [NRXBoolean booleanWithBool:! argument];
}
@end
