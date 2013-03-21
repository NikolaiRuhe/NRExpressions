//
//  NRExpressions
//
//  Author: Nikolai Ruhe
//  Copyright (c) 2013 Nikolai Ruhe. All rights reserved.
//

#import "NRXStatementNode.h"
#import "NRXError.h"
#import "NRXInterpreter.h"



@implementation NRXStatementNode
@end



@implementation NRXNoOperationNode

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	return nil;
}

@end



@implementation NRXBreakNode

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	return [[NRXBreakResult alloc] init];
}

@end



@implementation NRXContinueNode

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	return [[NRXContinueResult alloc] init];
}

@end



@implementation NRXSingleExpressionStatementNode

@synthesize expression = _expression;

- (id)initWithExpression:(NRXExpressionNode *)expression
{
	self = [self init];
	if (self != nil)
	{
		_expression = expression;
	}
	return self;
}

@end



@implementation NRXPrintNode

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(value, self.expression);
	[interpreter print:value];
	return nil;
}

@end



@implementation NRXAssertNode

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_BOOL_EXPRESSION(success, self.expression);
	if (! success)
		return [NRXAssertionError errorWithFormat:@"assertion failed"];
	return nil;
}

@end



@implementation NRXErrorNode

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(value, self.expression);
	return [NRXCustomError errorWithFormat:@"%@", value];
}

@end



@implementation NRXReturnNode

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(value, self.expression);
	return [[NRXReturnResult alloc] initWithValue:value];
}

@end



@implementation NRXAssignmentNode

@synthesize variableName = _variableName;
@synthesize expression = _expression;

- (id)initWithVariableName:(NSString *)variableName expression:(NRXExpressionNode *)expression
{
	self = [self init];
	if (self != nil)
	{
		_variableName = [variableName copy];
		_expression = expression;
	}
	return self;
}

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(expression, self.expression);
	[interpreter assignValue:expression toSymbol:self.variableName];
	return nil;
}

@end




@implementation NRXPropertyAssignmentNode
{
	SEL _selector;
}

@synthesize object = _object;
@synthesize propertyName = _propertyName;
@synthesize expression = _expression;

- (id)initWithObject:(NRXExpressionNode *)object propertyName:(NSString *)propertyName expression:(NRXExpressionNode *)expression;
{
	self = [self init];
	if (self != nil)
	{
		_object = object;
		_propertyName = [propertyName copy];
		_expression = expression;
		if ([self.propertyName length] >= 2)
		{
			NSString *rest = [self.propertyName substringFromIndex:1];
			NSString *firstCharacter = [[self.propertyName substringToIndex:1] uppercaseString];
			_selector = NSSelectorFromString([NSString stringWithFormat:@"nrx_set%@%@:", firstCharacter, rest]);
		}
	}
	return self;
}

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_EXPRESSION(object, self.object);
	EVALUATE_EXPRESSION(value, self.expression);

	if ([object respondsToSelector:_selector])
	{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		return [object performSelector:_selector withObject:value];
#pragma clang diagnostic pop
	}

	return [object nrx_setValue:value forKey:self.propertyName];
}

@end



@implementation NRXBlockNode

@synthesize statements = _statements;

- (id)initWithStatements:(NSArray *)statements
{
	self = [self init];
	if (self != nil)
	{
		_statements  = statements;
	}
	return self;
}

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	for (NRXStatementNode *node in self.statements)
	{
		EVALUATE_STATEMENT(node);
	}
	
	return nil;
}

@end



@implementation NRXFunctionDefinitionNode

@synthesize name = _name;
@synthesize parameterList = _parameterList;
@synthesize body = _body;

- (id)initWithName:(NSString *)name parameterList:(NSArray *)parameterList body:(NRXBlockNode *)body
{
	self = [self init];
	if (self != nil)
	{
		_name  = [name copy];
		_parameterList = parameterList;
		_body = body;
	}
	return self;
}

+ (NSString *)nrx_typeString
{
	return @"Function";
}

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	[interpreter assignValue:self toGlobalSymbol:self.name];
	return nil;
}

- (NRXValue *)callWithArguments:(NSArray *)arguments interpreter:(NRXInterpreter *)interpreter
{
	// create a function local scope
	if (! [interpreter pushScope])
		return [NRXInterpreterError errorWithFormat:@"call stack exceeded"];
	
	// check argument count
	NSUInteger parameterCount = [self.parameterList count];
	NSUInteger argumentCount  = [arguments count];

	if (parameterCount != argumentCount)
		return [NRXArgumentError errorWithFormat:@"argument mismatch: function %@ takes: %lu, given: %lu", self.name, (unsigned long)parameterCount, (unsigned long)argumentCount];

	// push arguments into local scope
	for (NSUInteger idx = 0; idx < argumentCount; ++idx)
	{
		NRXSymbolNode *symbol = self.parameterList[idx];
		assert([symbol isKindOfClass:[NRXSymbolNode class]]);
		NRXValue *argument = arguments[idx];
		[interpreter assignValue:argument toSymbol:symbol.name];
	}

	// call function body
	NRXValue *result = [self.body evaluate:interpreter];

	// restore scope
	[interpreter popScope];

	// return errors
	if ([result isKindOfClass:[NRXReturnResult class]])
		return ((NRXReturnResult *)result).value;

	return result;
}

@end



@implementation NRXBlockFunctionNode

@synthesize block = _block;

- (id)initWithName:(NSString *)name parameterList:(NSArray *)parameterList block:(NRXBlockFunctionBlock)block
{
	self = [super initWithName:name parameterList:parameterList body:nil];
	if (self != nil)
	{
		_block = [block copy];
	}
	return self;
}

- (NRXValue *)callWithArguments:(NSArray *)arguments interpreter:(NRXInterpreter *)interpreter
{
	// check argument count
	NSUInteger parameterCount = [self.parameterList count];
	NSUInteger argumentCount = [arguments count];
	
	if (parameterCount != argumentCount)
		return [NRXArgumentError errorWithFormat:@"argument mismatch: function %@ takes: %lu, given: %lu", self.name, (unsigned long)parameterCount, (unsigned long)argumentCount];

	for (NSUInteger idx = 0; idx < argumentCount; ++idx)
	{
		Class variableClass = self.parameterList[idx];
		NRXValue *argument = arguments[idx];
		if (! [argument isKindOfClass:variableClass])
			return [NRXArgumentError errorWithFormat:@"bad argument type: %@", NSStringFromClass([argument class])];
	}
	
	return self.block(arguments);
}

@end



@implementation NRXDelegateCallbackNode
{
	NSString *_name;
	SEL _selector;
}

- (id)initWithName:(NSString *)name selector:(SEL)selector
{
	self = [self init];
	if (self != nil)
	{
		_name     = [name copy];
		_selector = selector;

#ifdef DEBUG
		const char *s = sel_getName(selector);
		NSUInteger colonCount = 0;
		while (*s != 0) {
			if (*s++ == ':')
				colonCount += 1;
		}
		NSAssert(colonCount == 2, @"bad selector in NRXDelegateCallbackNode");
#endif
	}
	return self;
}

+ (NSString *)nrx_typeString
{
	return @"Function";
}

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	return self;
}

- (NRXValue *)callWithArguments:(NSArray *)arguments interpreter:(NRXInterpreter *)interpreter
{
	// create a function local scope
	if (! [interpreter pushScope])
		return [NRXInterpreterError errorWithFormat:@"call stack exceeded"];

	// call delegate
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	NRXValue *result = [interpreter.delegate performSelector:_selector withObject:_name withObject:arguments];
#pragma clang diagnostic pop

	// restore scope
	[interpreter popScope];

	if ([result isKindOfClass:[NRXReturnResult class]])
		return ((NRXReturnResult *)result).value;

	return result;
}

@end



@implementation NRXIfElseNode

@synthesize condition = _condition;
@synthesize statement = _statement;
@synthesize elseStatement = _elseStatement;

- (id)initWithCondition:(NRXExpressionNode *)condition statement:(NRXStatementNode *)statement elseStatement:(NRXStatementNode *)elseStatement
{
	self = [self init];
	if (self != nil)
	{
		_condition  = condition;
		_statement = statement;
		_elseStatement = elseStatement;
	}
	return self;
}

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_BOOL_EXPRESSION(condition, self.condition);
	if (condition)
	{
		EVALUATE_STATEMENT(self.statement);
	}
	else
	{
		EVALUATE_STATEMENT(self.elseStatement);
	}
	return nil;
}

@end



@implementation NRXWhileNode

@synthesize condition = _condition;
@synthesize statement = _statement;

- (id)initWithCondition:(NRXExpressionNode *)condition statement:(NRXStatementNode *)statement;
{
	self = [self init];
	if (self != nil)
	{
		_condition = condition;
		_statement = statement;
	}
	return self;
}

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	while (YES)
	{
		@autoreleasepool {
			if ([interpreter timeout])
				return [[NRXTimeoutResult alloc] init];
			EVALUATE_BOOL_EXPRESSION(condition, self.condition);
			if (! condition)
				return nil;
			NRXValue *value = [self.statement evaluate:interpreter];
			if ([value isKindOfClass:[NRXInterruptExecutionResult class]])
			{
				if ([value isKindOfClass:[NRXBreakResult class]])
					return nil;
				if ([value isKindOfClass:[NRXContinueResult class]])
					continue;
				return value;
			}
		}
	}
}

@end



@implementation NRXForInNode

@synthesize variable = _variable;
@synthesize list = _list;
@synthesize statement = _statement;

- (id)initWithVariable:(NSString *)variable list:(NRXExpressionNode *)list statement:(NRXStatementNode *)statement;
{
	self = [self init];
	if (self != nil)
	{
		_variable  = [variable copy];
		_list      = list;
		_statement = statement;
	}
	return self;
}

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	EVALUATE_LIST_EXPRESSION(list, self.list);
	for (NRXValue *element in list)
	{
		@autoreleasepool {
			[interpreter assignValue:element toSymbol:self.variable];
			NRXValue *value = [self.statement evaluate:interpreter];
			if ([value isKindOfClass:[NRXInterruptExecutionResult class]])
			{
				if ([value isKindOfClass:[NRXBreakResult class]])
					return nil;
				if ([value isKindOfClass:[NRXContinueResult class]])
					continue;
				return value;
			}
		}
	}
	return nil;
}

@end



@implementation NRXTryCatchNode

@synthesize tryStatement = _tryStatement;
@synthesize symbol = _symbol;
@synthesize catchStatement = _catchStatement;

- (id)initWithTryStatement:(NRXStatementNode *)tryStatement symbol:(NSString *)symbol catchStatement:(NRXStatementNode *)catchStatement;
{
	self = [self init];
	if (self != nil)
	{
		_tryStatement  = tryStatement;
		_symbol = [symbol copy];
		_catchStatement = catchStatement;
	}
	return self;
}

- (NRXValue *)evaluate:(NRXInterpreter *)interpreter
{
	NRXValue *value = [self.tryStatement evaluate:interpreter];
	if (! [value isKindOfClass:[NRXInterruptExecutionResult class]])
		return nil;

	if (! [value isKindOfClass:[NRXError class]])
		return value;

	[interpreter assignValue:[value description] toSymbol:self.symbol];
	EVALUATE_STATEMENT(self.catchStatement);

	return nil;
}

@end
