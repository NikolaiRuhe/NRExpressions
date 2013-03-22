//
//  NRExpressions
//
//  Author: Nikolai Ruhe
//  Copyright (c) 2013 Nikolai Ruhe. All rights reserved.
//

#import "NRXTypes.h"
#import "NRXExpressionNode.h"
@class NRXInterpreter;



@interface NRXStatementNode : NRXNode
@end



@protocol NRXCallable
- (id <NRXValue>)callWithArguments:(NSArray *)arguments interpreter:(NRXInterpreter *)interpreter;
@end



@interface NRXNoOperationNode : NRXStatementNode @end
@interface NRXContinueNode    : NRXStatementNode @end
@interface NRXBreakNode       : NRXStatementNode @end



@interface NRXSingleExpressionStatementNode : NRXStatementNode
@property (nonatomic, readonly, retain) NRXExpressionNode *expression;
- (id)initWithExpression:(NRXExpressionNode *)expression;
@end



@interface NRXPrintNode  : NRXSingleExpressionStatementNode @end
@interface NRXAssertNode : NRXSingleExpressionStatementNode @end
@interface NRXErrorNode  : NRXSingleExpressionStatementNode @end
@interface NRXReturnNode : NRXSingleExpressionStatementNode @end



@interface NRXBlockNode : NRXStatementNode
@property (nonatomic, readonly, retain) NSArray *statements;
- (id)initWithStatements:(NSArray *)statements;
@end



@interface NRXAssignmentNode : NRXStatementNode
@property (nonatomic, readonly, copy) NSString *variableName;
@property (nonatomic, readonly, retain) NRXExpressionNode *expression;
- (id)initWithVariableName:(NSString *)name expression:(NRXExpressionNode *)expression;
@end



@interface NRXPropertyAssignmentNode : NRXStatementNode
@property (nonatomic, readonly, retain) NRXExpressionNode *object;
@property (nonatomic, readonly, copy) NSString *propertyName;
@property (nonatomic, readonly, retain) NRXExpressionNode *expression;
- (id)initWithObject:(NRXExpressionNode *)object propertyName:(NSString *)propertyName expression:(NRXExpressionNode *)expression;
@end



@interface NRXFunctionDefinitionNode : NRXExpressionNode <NRXCallable, NRXValue>
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, retain) NSArray *parameterList;
@property (nonatomic, readonly, retain) NRXBlockNode *body;
- (id)initWithName:(NSString *)name parameterList:(NSArray *)parameterList body:(NRXBlockNode *)body;
@end



typedef id <NRXValue>(^NRXBlockFunctionBlock)(NSArray *arguments);

@interface NRXBlockFunctionNode : NRXFunctionDefinitionNode
@property (nonatomic, readonly, copy) NRXBlockFunctionBlock block;
- (id)initWithName:(NSString *)name parameterList:(NSArray *)parameterList block:(NRXBlockFunctionBlock)block;
@end



@interface NRXDelegateCallbackNode : NRXExpressionNode <NRXCallable, NRXValue>
- (id)initWithName:(NSString *)name selector:(SEL)selector;
@end



@interface NRXIfElseNode : NRXStatementNode
@property (nonatomic, readonly, retain) NRXExpressionNode *condition;
@property (nonatomic, readonly, retain) NRXStatementNode *statement;
@property (nonatomic, readonly, retain) NRXStatementNode *elseStatement;
- (id)initWithCondition:(NRXExpressionNode *)condition statement:(NRXStatementNode *)statement elseStatement:(NRXStatementNode *)statement;
@end



@interface NRXWhileNode : NRXStatementNode
@property (nonatomic, readonly, retain) NRXExpressionNode *condition;
@property (nonatomic, readonly, retain) NRXStatementNode *statement;
- (id)initWithCondition:(NRXExpressionNode *)condition statement:(NRXStatementNode *)statement;
@end



@interface NRXForInNode : NRXStatementNode
@property (nonatomic, readonly, retain) NSString *variable;
@property (nonatomic, readonly, retain) NRXExpressionNode *list;
@property (nonatomic, readonly, retain) NRXStatementNode *statement;
- (id)initWithVariable:(NSString *)variable list:(NRXExpressionNode *)list statement:(NRXStatementNode *)statement;
@end



@interface NRXTryCatchNode : NRXStatementNode
@property (nonatomic, readonly, retain) NRXStatementNode *tryStatement;
@property (nonatomic, readonly, retain) NSString *symbol;
@property (nonatomic, readonly, retain) NRXStatementNode *catchStatement;
- (id)initWithTryStatement:(NRXStatementNode *)tryStatement symbol:(NSString *)symbol catchStatement:(NRXStatementNode *)catchStatement;
@end
