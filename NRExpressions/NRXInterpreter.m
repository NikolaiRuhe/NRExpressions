//
//  NRExpressions
//
//  Author: Nikolai Ruhe
//  Copyright (c) 2013 Nikolai Ruhe. All rights reserved.
//

#import "NRXInterpreter.h"
#import "NRXStatementNode.h"
#import "NRXError.h"
#import "NRXParser.h"



@interface NRXInterpreter()
@property (nonatomic, readonly, retain) NSMutableArray *stack;
@end



@implementation NRXInterpreter
{
	CFAbsoluteTime _start;
}

@synthesize delegate = _delegate;
@synthesize stack = _stack;
@synthesize globalScope = _globalScope;
@synthesize printBlock = _printBlock;
@synthesize maxEvaluationTime = _maxEvaluationTime;
@synthesize maxCallDepth = _maxCallDepth;

+ (NSDictionary *)defaultGlobalScope
{
	return @{};
}

- (NSMutableArray *)stack
{
	if (_stack == nil)
	{
		_stack = [[NSMutableArray alloc] init];
		[self pushScope];
	}
	return _stack;
}

- (NSMutableDictionary *)currentScope
{
	return [self.stack lastObject];
}

- (NSMutableDictionary *)globalScope
{
	if (_globalScope == nil)
		_globalScope = [[[self class] defaultGlobalScope] mutableCopy];
	return _globalScope;
}

- (id <NRXValue>)lookupToken:(NSString *)token
{
	if ([self.delegate respondsToSelector:@selector(lookupToken:)])
		return [self.delegate lookupToken:token];
	return [NRXInterpreterError errorWithFormat:@"token lookup not supported"];
}

- (id <NRXValue>)resolveSymbol:(NSString *)symbol
{
	assert(symbol != nil);
	id <NRXValue> value = [[self currentScope] objectForKey:symbol];
	if (value != nil)
		return value;

	value = [[self globalScope] objectForKey:symbol];
	if (value != nil)
		return value;

	if ([self.delegate respondsToSelector:@selector(resolveSymbol:)]) {
		value = [self.delegate resolveSymbol:symbol];
		if (value != nil)
			return value;
	}

	return [NRXLookupError errorWithFormat:@"symbol not found: \"%@\"", symbol];
}

- (void)assignValue:(id <NRXValue>)value toSymbol:(NSString *)symbol
{
	assert(symbol != nil);
	if (value == nil)
		value = [NSNull null];
	[[self currentScope] setObject:value forKey:symbol];
}

- (void)assignValue:(id <NRXValue>)value toGlobalSymbol:(NSString *)symbol
{
	assert(symbol != nil);
	if (value == nil)
		value = [NSNull null];
	[[self globalScope] setObject:value forKey:symbol];
}

- (void)print:(id <NRXValue>)value
{
	if (self.printBlock != NULL)
		self.printBlock(value);
	else
		NSLog(@"%@", value);
}

- (BOOL)pushScope
{
	NSMutableArray *stack = self.stack;
	if (self.maxCallDepth != 0 && [stack count] > self.maxCallDepth)
		return NO;
	[self.stack addObject:[NSMutableDictionary dictionary]];
	return YES;
}

- (void)popScope
{
	[self.stack removeLastObject];
}

- (BOOL)timeout
{
	if (self.maxEvaluationTime == 0)
		return NO;
	CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
	if (_start == 0)
		_start = now;
	return now - _start > self.maxEvaluationTime;
}

- (id <NRXValue>)runWithRootNode:(NRXNode *)node
{
	if (node == nil)
		return nil;

	id <NRXValue> result = [node evaluate:self];

	if ([result isKindOfClass:[NRXReturnResult class]])
		return ((NRXReturnResult *)result).value;

	// TODO: define expected result types
	return result;
}

@end
