//
//  NRExpressions
//
//  Author: Nikolai Ruhe
//  Copyright (c) 2013 Nikolai Ruhe. All rights reserved.
//

#import "NRXTypes.h"


@protocol NRXInterpreterDelegate <NSObject>
@optional
- (NRXValue *)resolveSymbol:(NSString *)symbol;
- (NRXValue *)lookupToken:(NSString *)token;
@end


typedef void (^NRXPrintBlock)(NRXValue *value);
typedef void (^NRXErrorBlock)(NSString *message, NSUInteger lineNumber);

@interface NRXInterpreter : NSObject

@property (nonatomic, weak) id <NRXInterpreterDelegate> delegate;

@property (nonatomic, copy) NRXPrintBlock printBlock;
@property (nonatomic, retain) NSMutableDictionary *globalScope;
@property (nonatomic) double maxEvaluationTime;
@property (nonatomic) NSUInteger maxCallDepth;

+ (NSDictionary *)defaultGlobalScope;

- (NRXValue *)resolveSymbol:(NSString *)symbol;
- (void)assignValue:(NRXValue *)value toSymbol:(NSString *)symbol;
- (void)assignValue:(NRXValue *)value toGlobalSymbol:(NSString *)symbol;

- (NRXValue *)lookupToken:(NSString *)token;

- (BOOL)pushScope;
- (void)popScope;

- (void)print:(NRXValue *)value;

- (BOOL)timeout;

- (NRXValue *)runWithRootNode:(NRXNode *)node;

@end
