//
//  NRExpressions
//
//  Author: Nikolai Ruhe
//  Copyright (c) 2013 Nikolai Ruhe. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NRExpression;
@class NRXBlockNode;


typedef void (^ NRXParserErrorBlock)(NSString *message, NSUInteger lineNumber);

NRXBlockNode *NRXParserParseString(NSString *sourceString, NRXParserErrorBlock errorBlock);


// private part

#include "y.tab.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpadded"
typedef struct {
	const char *sourceString;
	BOOL error;
	__unsafe_unretained NRXParserErrorBlock errorBlock;
	void *result;
	void *scanner;
	void *buffer;
} NRXParser;
#pragma clang diagnostic pop


int NRX_lex(YYSTYPE *lvalp, YYLTYPE* llocp, void *scanner);

#define NRX_error(llocp, parser, msg) \
{ \
	(parser)->error = YES; \
	if ((parser)->errorBlock != NULL) \
	{ \
		(parser)->errorBlock([NSString stringWithUTF8String:(msg)], (llocp)->first_line + 1); \
	} \
	YYERROR; \
}

void NRXParserInit(NRXParser *parser);
void NRXParserCleanup(NRXParser *parser);
