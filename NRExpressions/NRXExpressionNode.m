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

- (id)initWithValue:(NRXValue *)value
{
	self = [self init];
	if (self != nil)
	{
		_value = value;
	}
	return self;
}

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	return self.value;
}

@end

@implementation NRXNumberLiteralNode @end
@implementation NRXBoolLiteralNode   @end
@implementation NRXNullLiteralNode   @end
@implementation NRXStringLiteralNode @end

@implementation NRXListLiteralNode

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
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

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
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

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
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

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
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

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
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

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
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

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_LIST_EXPRESSION(list, self.listExpression);
	EVALUATE_NUMBER_EXPRESSION(index, self.index);
	NSInteger idx = [index integerValue];

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

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(object, self.object);

	if ([object respondsToSelector:_selector])
	{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		return [object performSelector:_selector];
#pragma clang diagnostic pop
	}

	return [object nrx_valueForKey:self.propertyName];
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

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
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
- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_DOUBLE_EXPRESSION(argument, self.argument);
	return [NSNumber numberWithDouble:-argument];
}
@end




@implementation NRXAdditionNode
- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(left,  self.left);
	EVALUATE_EXPRESSION(right, self.right);
	if ([left isKindOfClass:[NSString class]] || [right isKindOfClass:[NSString class]])
		return [NSString stringWithFormat:@"%@%@", left, right];
	if ([left isKindOfClass:[NSNumber class]] && [right isKindOfClass:[NSNumber class]])
		return [NSNumber numberWithDouble:[(NSNumber *)left doubleValue] + [(NSNumber *)right doubleValue]];
	return [NRXArgumentError errorWithFormat:@"'+' operator: bad operands"];
}
@end

@implementation NRXSubtractionNode
- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_DOUBLE_EXPRESSION(left,  self.left);
	EVALUATE_DOUBLE_EXPRESSION(right, self.right);
	return [NSNumber numberWithDouble:left - right];
}
@end

@implementation NRXMultiplicationNode
- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_DOUBLE_EXPRESSION(left,  self.left);
	EVALUATE_DOUBLE_EXPRESSION(right, self.right);
	return [NSNumber numberWithDouble:left * right];
}
@end

@implementation NRXDivisionNode
- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_DOUBLE_EXPRESSION(left,  self.left);
	EVALUATE_DOUBLE_EXPRESSION(right, self.right);
	if (right == 0)
		return [NRXMathError errorWithFormat:@"division by zero"];
	return [NSNumber numberWithDouble:left / right];
}
@end

@implementation NRXModulusNode
- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_DOUBLE_EXPRESSION(left,  self.left);
	EVALUATE_DOUBLE_EXPRESSION(right, self.right);
	if (right == 0)
		return [NRXMathError errorWithFormat:@"modulus division by zero"];
	return [NSNumber numberWithDouble:fmod(left, right)];
}
@end

@implementation NRXLessThanNode
- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_DOUBLE_EXPRESSION(left,  self.left);
	EVALUATE_DOUBLE_EXPRESSION(right, self.right);
	return [NSNumber numberWithBool:left < right];
}
@end

@implementation NRXGreaterThanNode
- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_DOUBLE_EXPRESSION(left,  self.left);
	EVALUATE_DOUBLE_EXPRESSION(right, self.right);
	return [NSNumber numberWithBool:left > right];
}
@end

@implementation NRXGreaterOrEqualNode
- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_DOUBLE_EXPRESSION(left,  self.left);
	EVALUATE_DOUBLE_EXPRESSION(right, self.right);
	return [NSNumber numberWithBool:left >= right];
}
@end

@implementation NRXLessOrEqualNode
- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_DOUBLE_EXPRESSION(left,  self.left);
	EVALUATE_DOUBLE_EXPRESSION(right, self.right);
	return [NSNumber numberWithBool:left <= right];
}
@end

@implementation NRXNotEqualNode
- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(left,  self.left);
	EVALUATE_EXPRESSION(right, self.right);
	return [NSNumber numberWithBool:! (left == right || [left isEqual:right])];
}
@end

@implementation NRXEqualNode
- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(left,  self.left);
	EVALUATE_EXPRESSION(right, self.right);
	return [NSNumber numberWithBool:left == right || [left isEqual:right]];
}
@end

@implementation NRXLogicalAndNode
- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_BOOL_EXPRESSION(left,  self.left);
	
	// care for short-circuiting right operand
	if (! left)
		return [NSNumber numberWithBool:NO];
	
	EVALUATE_BOOL_EXPRESSION(right, self.right);
	return [NSNumber numberWithBool:right];
}
@end

@implementation NRXLogicalOrNode
- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_BOOL_EXPRESSION(left,  self.left);
	
	// care for short-circuiting right operand
	if (left)
		return [NSNumber numberWithBool:YES];
	
	EVALUATE_BOOL_EXPRESSION(right, self.right);
	return [NSNumber numberWithBool:right];
}
@end

@implementation NRXLogicalNegationNode
- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_BOOL_EXPRESSION(argument, self.argument);
	return [NSNumber numberWithBool:! argument];
}
@end
