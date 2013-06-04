//
//  NRExpressions
//
//  Author: Nikolai Ruhe
//  Copyright (c) 2013 Nikolai Ruhe. All rights reserved.
//

#import "NRXTypes.h"



@interface NRXExpressionNode : NRXNode
@end



@interface NRXLiteralNode : NRXExpressionNode
@property (nonatomic, readonly, copy) id <NRXValue> value;
- (id)initWithValue:(id <NRXValue>)value;
@end

@interface NRXListLiteralNode       : NRXLiteralNode @end
@interface NRXDictionaryLiteralNode : NRXLiteralNode @end



@interface NRXLookupNode : NRXExpressionNode
@property (nonatomic, readonly, copy) NSString *token;
- (id)initWithToken:(NSString *)token;
@end



@interface NRXSymbolNode : NRXExpressionNode
@property (nonatomic, readonly, copy) NSString *name;
- (id)initWithName:(NSString *)name;
@end



@interface NRXUnaryOperationNode : NRXExpressionNode
@property (nonatomic, readonly, retain) NRXExpressionNode *argument;
- (id)initWithArgument:(NRXExpressionNode *)argument;
@end



@interface NRXBinaryInfixOperationNode : NRXExpressionNode
@property (nonatomic, readonly, retain) NRXExpressionNode *left;
@property (nonatomic, readonly, retain) NRXExpressionNode *right;
- (id)initWithLeft:(NRXExpressionNode *)left right:(NRXExpressionNode *)right;
@end



@interface NRXCallNode : NRXExpressionNode
@property (nonatomic, readonly, copy) NRXExpressionNode *callable;
@property (nonatomic, readonly, retain) NSArray *arguments;
- (id)initWithCallable:(NRXExpressionNode *)callable arguments:(NSArray *)arguments;
@end



@interface NRXSubscriptNode : NRXExpressionNode
@property (nonatomic, readonly, retain) NRXExpressionNode *subscriptableExpression;
@property (nonatomic, readonly, retain) NRXExpressionNode *subscriptExpression;
- (id)initWithSubscriptableExpression:(NRXExpressionNode *)subscriptableExpression subscriptExpression:(NRXExpressionNode *)subscriptExpression;
@end



@interface NRXPropertyAccessNode : NRXExpressionNode
@property (nonatomic, readonly, retain) NRXExpressionNode *object;
@property (nonatomic, readonly, copy) NSString *propertyName;
- (id)initWithObject:(NRXExpressionNode *)object propertyName:(NSString *)propertyName;
@end



@interface NRXTernaryConditionNode : NRXExpressionNode
@property (nonatomic, readonly, retain) NRXExpressionNode *condition;
@property (nonatomic, readonly, retain) NRXExpressionNode *positiveExpression;
@property (nonatomic, readonly, retain) NRXExpressionNode *negativeExpression;
- (id)initWithCondition:(NRXExpressionNode *)condition positiveExpression:(NRXExpressionNode *)positiveExpression negativeExpression:(NRXExpressionNode *)negativeExpression;
@end



@interface NRXWhereNode : NRXExpressionNode
@property (nonatomic, readonly, retain) NRXExpressionNode *list;
@property (nonatomic, readonly, copy) NSString *variable;
@property (nonatomic, readonly, retain) NRXExpressionNode *condition;
- (id)initWithList:(NRXExpressionNode *)list variable:(NSString *)variable condition:(NRXExpressionNode *)condition;
@end

@interface NRXLogicalNegationNode : NRXUnaryOperationNode @end
@interface NRXNegationNode        : NRXUnaryOperationNode @end

@interface NRXAdditionNode        : NRXBinaryInfixOperationNode @end
@interface NRXSubtractionNode     : NRXBinaryInfixOperationNode @end
@interface NRXMultiplicationNode  : NRXBinaryInfixOperationNode @end
@interface NRXDivisionNode        : NRXBinaryInfixOperationNode @end
@interface NRXModulusNode         : NRXBinaryInfixOperationNode @end
@interface NRXLogicalAndNode      : NRXBinaryInfixOperationNode @end
@interface NRXLogicalOrNode       : NRXBinaryInfixOperationNode @end
@interface NRXLessThanNode        : NRXBinaryInfixOperationNode @end
@interface NRXGreaterThanNode     : NRXBinaryInfixOperationNode @end
@interface NRXGreaterOrEqualNode  : NRXBinaryInfixOperationNode @end
@interface NRXLessOrEqualNode     : NRXBinaryInfixOperationNode @end
@interface NRXNotEqualNode        : NRXBinaryInfixOperationNode @end
@interface NRXEqualNode           : NRXBinaryInfixOperationNode @end
