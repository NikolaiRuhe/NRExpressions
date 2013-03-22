#import <Foundation/Foundation.h>
#import "NRXTypes.h"
#import "NRXInterpreter.h"
@class NRXBlockNode;


@interface NRExpression : NSObject

@property (nonatomic, copy, readonly) NSString *sourceString;
@property (nonatomic, retain, readonly) NRXBlockNode *rootNode;
@property (nonatomic, copy) NRXPrintBlock printBlock;

- (BOOL)parseSourceString:(NSString *)sourceString;
- (BOOL)parseSourceString:(NSString *)sourceString errorBlock:(NRXErrorBlock)errorBlock;

- (id <NRXValue>)evaluate;

@end

