//
//  NRExpressions
//
//  Author: Nikolai Ruhe
//  Copyright (c) 2013 Nikolai Ruhe. All rights reserved.
//

#import "NRXTypes.h"
@class NRXBlockNode;


@protocol NRXInterpreterDelegate <NSObject>
@optional
- (id <NRXValue>)resolveSymbol:(NSString *)symbol;
- (id <NRXValue>)lookupToken:(NSString *)token;
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

- (id <NRXValue>)lookupToken:(NSString *)token;

- (BOOL)pushScope;
- (void)popScope;

- (void)print:(id <NRXValue>)value;

- (BOOL)timeout;

- (id <NRXValue>)runWithRootNode:(NRXNode *)node;

+ (NRXBlockNode *)parseSourceString:(NSString *)sourceString withErrorBlock:(NRXErrorBlock)errorBlock;

// convenience parse and evaluate. blacks can be nil.
+ (id <NRXValue>)evaluateSourceString:(NSString *)sourceString withErrorBlock:(NRXErrorBlock)errorBlock printBlock:(NRXPrintBlock)printBlock;
+ (id <NRXValue>)evaluateSourceString:(NSString *)sourceString;

@end
