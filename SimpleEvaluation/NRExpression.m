#import "NRExpression.h"
#import "NRExpressions.h"



@interface NRExpression()
@property (nonatomic, retain, readwrite) NRXBlockNode *rootNode;
@end



@implementation NRExpression

@synthesize sourceString = _sourceString;
@synthesize printBlock = _printBlock;
@synthesize rootNode = _rootNode;

- (BOOL)parseSourceString:(NSString *)sourceString
{
	return [self parseSourceString:sourceString errorBlock:NULL];
}

- (BOOL)parseSourceString:(NSString *)sourceString errorBlock:(NRXErrorBlock)errorBlock
{
	_sourceString = sourceString;
	if (errorBlock == NULL)
	{
		errorBlock = ^ void (NSString *message, NSUInteger lineNumber)
		{
			NSLog(@"error in line %lu: %@", (unsigned long)lineNumber, message);
		};
	}
	self.rootNode = NRXParserParseString(self.sourceString, errorBlock);
	assert(self.rootNode == nil || [self.rootNode isKindOfClass:[NRXBlockNode class]]);

	return self.rootNode != nil;
}

- (NRXValue *)evaluate
{
	NRXInterpreter *interpreter = [[NRXInterpreter alloc] init];
	interpreter.printBlock = self.printBlock;
	return [interpreter runWithRootNode:self.rootNode];
}

@end
