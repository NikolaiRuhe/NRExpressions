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

@implementation NRXNumberLiteralNode @end
@implementation NRXBoolLiteralNode   @end
@implementation NRXNullLiteralNode   @end
@implementation NRXStringLiteralNode @end

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



@implementation NRXLookupNode

@synthesize token = _token;

- (id)initWithToken:(NSString *)token
{
	self = [self init];
	if (self != nil)
	{
		_token = [token copy];
	}
	return self;
}

- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	return [interpreter lookupToken:self.token];
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

@synthesize listExpression = _listExpression;
@synthesize index = _index;

- (id)initWithListExpression:(NRXExpressionNode *)listExpression index:(NRXExpressionNode *)index
{
	self = [self init];
	if (self != nil)
	{
		_listExpression  = listExpression;
		_index = index;
	}
	return self;
}

- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_LIST_EXPRESSION(list, self.listExpression);

	EVALUATE_EXPRESSION(index, self.index);
	if (! [index isKindOfClass:[NSDecimalNumber class]])
		return [NRXArgumentError errorWithFormat:@"bad index argument"];

	NSInteger idx = [(NSDecimalNumber *)index integerValue];

	if (idx < 0 || idx >= (NSInteger)[list count])
		return [NRXArgumentError errorWithFormat:@"%@: index out of bounds", index];

	return list[idx];
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
		_selector = NSSelectorFromString([NSString stringWithFormat:@"nrx_%@", self.propertyName]);
	}
	return self;
}

- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(object, self.object);

	if ([object respondsToSelector:_selector])
	{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		return [object performSelector:_selector];
#pragma clang diagnostic pop
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





@implementation NRXNegationNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(argument, self.argument);
	if ([argument respondsToSelector:@selector(nrx_negation)])
		return [argument nrx_negation];
	return [NRXArgumentError errorWithFormat:@"negation not defined"];
}
@end




@implementation NRXAdditionNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(left,  self.left);
	EVALUATE_EXPRESSION(right, self.right);

	if ([left respondsToSelector:@selector(nrx_addition:)])
		return [left nrx_addition:right];
	return [NRXArgumentError errorWithFormat:@"'+' operator: bad operands"];
}
@end

@implementation NRXSubtractionNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(left,  self.left);
	EVALUATE_EXPRESSION(right, self.right);

	if ([left respondsToSelector:@selector(nrx_subtraction:)])
		return [left nrx_subtraction:right];
	return [NRXArgumentError errorWithFormat:@"'-' operator: bad operands"];
}
@end

@implementation NRXMultiplicationNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(left,  self.left);
	EVALUATE_EXPRESSION(right, self.right);

	if ([left respondsToSelector:@selector(nrx_multiplication:)])
		return [left nrx_multiplication:right];
	return [NRXArgumentError errorWithFormat:@"'*' operator: bad operands"];
}
@end

@implementation NRXDivisionNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(left,  self.left);
	EVALUATE_EXPRESSION(right, self.right);

	if ([left respondsToSelector:@selector(nrx_division:)])
		return [left nrx_division:right];
	return [NRXArgumentError errorWithFormat:@"'/' operator: bad operands"];
}
@end

@implementation NRXModulusNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(left,  self.left);
	EVALUATE_EXPRESSION(right, self.right);

	if ([left respondsToSelector:@selector(nrx_modulus:)])
		return [left nrx_modulus:right];
	return [NRXArgumentError errorWithFormat:@"'%' operator: bad operands"];
}
@end

@implementation NRXLessThanNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(left,  self.left);
	EVALUATE_EXPRESSION(right, self.right);

	if (! [left respondsToSelector:@selector(nrx_compare:error:)])
		return [NRXArgumentError errorWithFormat:@"'<' operator: bad operands"];

	NRXError *error;
	NSComparisonResult result = [left nrx_compare:right error:&error];
	if (error != nil)
		return error;
	return [NRXBoolean booleanWithBool:result == NSOrderedAscending];
}
@end

@implementation NRXGreaterThanNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(left,  self.left);
	EVALUATE_EXPRESSION(right, self.right);

	if (! [left respondsToSelector:@selector(nrx_compare:error:)])
		return [NRXArgumentError errorWithFormat:@"'>' operator: bad operands"];

	NRXError *error;
	NSComparisonResult result = [left nrx_compare:right error:&error];
	if (error != nil)
		return error;
	return [NRXBoolean booleanWithBool:result == NSOrderedDescending];
}
@end

@implementation NRXGreaterOrEqualNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(left,  self.left);
	EVALUATE_EXPRESSION(right, self.right);

	if (! [left respondsToSelector:@selector(nrx_compare:error:)])
		return [NRXArgumentError errorWithFormat:@"'>=' operator: bad operands"];

	NRXError *error;
	NSComparisonResult result = [left nrx_compare:right error:&error];
	if (error != nil)
		return error;
	return [NRXBoolean booleanWithBool:result != NSOrderedAscending];
}
@end

@implementation NRXLessOrEqualNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(left,  self.left);
	EVALUATE_EXPRESSION(right, self.right);

	if (! [left respondsToSelector:@selector(nrx_compare:error:)])
		return [NRXArgumentError errorWithFormat:@"'>=' operator: bad operands"];

	NRXError *error;
	NSComparisonResult result = [left nrx_compare:right error:&error];
	if (error != nil)
		return error;
	return [NRXBoolean booleanWithBool:result != NSOrderedDescending];
}
@end

@implementation NRXNotEqualNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(left,  self.left);
	EVALUATE_EXPRESSION(right, self.right);

	if (! [left respondsToSelector:@selector(nrx_compare:error:)])
		return [NRXArgumentError errorWithFormat:@"'>=' operator: bad operands"];

	NRXError *error;
	NSComparisonResult result = [left nrx_compare:right error:&error];
	if (error != nil)
		return error;
	return [NRXBoolean booleanWithBool:result != NSOrderedSame];
}
@end

@implementation NRXEqualNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(left,  self.left);
	EVALUATE_EXPRESSION(right, self.right);

	if (! [left respondsToSelector:@selector(nrx_compare:error:)])
		return [NRXArgumentError errorWithFormat:@"'>=' operator: bad operands"];

	NRXError *error;
	NSComparisonResult result = [left nrx_compare:right error:&error];
	if (error != nil)
		return error;
	return [NRXBoolean booleanWithBool:result == NSOrderedSame];
}
@end

@implementation NRXLogicalAndNode
- (id <NRXValue>)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_BOOL_EXPRESSION(left,  self.left);
	
	// care for short-circuiting right operand
	if (! left)
		return [NRXBoolean booleanWithBool:NO];
	
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
		return [NRXBoolean booleanWithBool:YES];
	
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
