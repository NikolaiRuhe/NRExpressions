//
//  NRExpressions
//
//  Author: Nikolai Ruhe
//  Copyright (c) 2013 Nikolai Ruhe. All rights reserved.
//

#import "NRXTypes.h"
@class NRXBlockNode, NRXLookupNode;


@protocol NRXInterpreterDelegate <NSObject>
@optional
- (id <NRXValue>)resolveSymbol:(NSString *)symbol;
- (id <NRXValue>)lookupNode:(NRXLookupNode *)node;
@end


typedef void (^NRXPrintBlock)(id <NRXValue> value);
typedef void (^NRXErrorBlock)(NSString *message, NSUInteger lineNumber);


@interface NRXInterpreter : NSObject

@property (nonatomic, weak) id <NRXInterpreterDelegate> delegate;

@property (nonatomic, copy) NRXPrintBlock printBlock;
@property (nonatomic, retain) NSMutableDictionary *globalScope;
@property (nonatomic) double maxEvaluationTime;
@property (nonatomic) NSUInteger maxCallDepth;

+ (NSDictionary *)defaultGlobalScope;

- (id <NRXValue>)resolveSymbol:(NSString *)symbol;
- (void)assignValue:(id <NRXValue>)value toSymbol:(NSString *)symbol;
- (void)assignValue:(id <NRXValue>)value toGlobalSymbol:(NSString *)symbol;

- (id <NRXValue>)lookupNode:(NRXLookupNode *)lookupNode;

- (id <NRXValue>)performInNestedScope:(id <NRXValue>(^)(void))block;
- (id <NRXValue>)performInNewScope:(id <NRXValue>(^)(void))block;

- (void)print:(id <NRXValue>)value;

- (BOOL)timeout;

- (id <NRXValue>)runWithRootNode:(NRXNode *)node;

+ (NRXBlockNode *)parseSourceString:(NSString *)sourceString withErrorBlock:(NRXErrorBlock)errorBlock;

// convenience parse and evaluate. blacks can be nil.
+ (id <NRXValue>)evaluateSourceString:(NSString *)sourceString withErrorBlock:(NRXErrorBlock)errorBlock printBlock:(NRXPrintBlock)printBlock;
+ (id <NRXValue>)evaluateSourceString:(NSString *)sourceString;

+ (NSDecimalNumber *)decimalNumberFromString:(NSString *)string;
+ (NSString *)stringFromDecimalNumber:(NSDecimalNumber *)number;

@end
