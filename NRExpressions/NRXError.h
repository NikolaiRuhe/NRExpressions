//
//  NRExpressions
//
//  Author: Nikolai Ruhe
//  Copyright (c) 2013 Nikolai Ruhe. All rights reserved.
//

#import "NRXTypes.h"


@interface NRXError : NRXInterruptExecutionResult

@property (nonatomic, copy, readonly) NSString *reason;

+ (NRXError *)errorWithFormat:(NSString *)format, ...;

@end


// parse time errors
@interface NRXParserError      : NRXError        @end
@interface NRXSyntaxError      : NRXParserError  @end

// runtime errors
@interface NRXRuntimeError     : NRXError        @end
@interface NRXInterpreterError : NRXError        @end
@interface NRXMathError        : NRXRuntimeError @end
@interface NRXLookupError      : NRXRuntimeError @end
@interface NRXArgumentError    : NRXRuntimeError @end
@interface NRXTypeError        : NRXRuntimeError @end
@interface NRXAssertionError   : NRXRuntimeError @end
@interface NRXCustomError      : NRXRuntimeError @end
