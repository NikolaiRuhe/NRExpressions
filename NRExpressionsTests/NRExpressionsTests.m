#import "NRExpressionsTests.h"
#import "NRExpressions.h"

@interface NRXEvaluationTests ()
- (BOOL)parse:(NSString *)sourceString;
@end



@implementation NRXEvaluationTests
{
	NSMutableString *_testResult;
	NSMutableString *_testOutput;
}

- (void)setUp
{
	[super setUp];
}

- (void)tearDown
{
	[super tearDown];
}

- (BOOL)parse:(NSString *)sourceString
{
	_testResult = [[NSMutableString alloc] init];
	_testOutput = [[NSMutableString alloc] init];

	BOOL __block error = NO;
	NRXBlockNode *rootNode = [NRXInterpreter parseSourceString:sourceString
												withErrorBlock:^(NSString *message, NSUInteger lineNumber) {
													NSLog(@"error in line %lu: %@", (unsigned long)lineNumber, message);
													error = YES;
												}];
	if (rootNode == nil) {
		STAssertTrue(error, @"no error while parsing");
		return NO;
	}

	STAssertFalse(error, @"error while parsing");
	STAssertTrue([rootNode isKindOfClass:[NRXBlockNode class]], @"bad root node");

	NRXInterpreter *interpreter = [NRXInterpreter new];
	__block NSMutableString *blockOutput = _testOutput;
	interpreter.printBlock = ^(id <NRXValue> value) {
		[blockOutput appendFormat:@"%@\n", value];
	};

	_testResult = [NSString stringWithFormat:@"%@", [interpreter runWithRootNode:rootNode]];
	return YES;
}

#define evaluate(string) STAssertTrue([self parse:string], @"parser error");
#define expectOutput(string) STAssertEqualObjects(_testOutput, string, @"unexpected output");
#define expectResult(string) STAssertEqualObjects(_testResult, string, @"unexpected result");

- (void)testEmptyScript
{
	evaluate(@"");
	expectOutput(@"");
	expectResult(@"(null)");
}

- (void)testEmptyExpression
{
	evaluate(@";");
	expectOutput(@"");
	expectResult(@"(null)");
}

- (void)testComment
{
	evaluate(@"// C++ style comment");
	expectOutput(@"");
	expectResult(@"(null)");
}

- (void)testCComment
{
	evaluate(@"/* C-style comment */");
	expectOutput(@"");
	expectResult(@"(null)");
}

- (void)testPrintStatement
{
	evaluate(@"print;");
	expectOutput(@"\n");
	expectResult(@"(null)");
}

- (void)testPrintWithArgument
{
	evaluate(@"print 1;");
	expectOutput(@"1\n");
	expectResult(@"(null)");
}

- (void)testHelloWorld
{
	evaluate(@"print \"Hello, World!\";");
	expectOutput(@"Hello, World!\n");
	expectResult(@"(null)");
}

- (void)testLessThan
{
	evaluate(@"print 1 < 2 ? 'yes' : 'no';");
	expectOutput(@"yes\n");
	expectResult(@"(null)");
}

- (void)testLessOrEqual
{
	evaluate(@"print 1 <= 2 ? 'yes' : 'no';");
	expectOutput(@"yes\n");
	expectResult(@"(null)");
}

- (void)testEqual
{
	evaluate(@"print 1 == 1 ? 'yes' : 'no';");
	expectOutput(@"yes\n");
	expectResult(@"(null)");
}

- (void)testNotEqual
{
	evaluate(@"print 1 != 2 ? 'yes' : 'no';");
	expectOutput(@"yes\n");
	expectResult(@"(null)");
}

- (void)testGreaterThan
{
	evaluate(@"print 2 > 1 ? 'yes' : 'no';");
	expectOutput(@"yes\n");
	expectResult(@"(null)");
}

- (void)testGreaterOrEqual
{
	evaluate(@"print 2 >= 1 ? 'yes' : 'no';");
	expectOutput(@"yes\n");
	expectResult(@"(null)");
}

- (void)testAddition
{
	evaluate(@"print 1 + 1;");
	expectOutput(@"2\n");
	expectResult(@"(null)");
}

- (void)testSubtraction
{
	evaluate(@"print 3 - 1;");
	expectOutput(@"2\n");
	expectResult(@"(null)");
}

- (void)testMultiplication
{
	evaluate(@"print 1 * 2;");
	expectOutput(@"2\n");
	expectResult(@"(null)");
}

- (void)testDivision
{
	evaluate(@"print 4 / 2;");
	expectOutput(@"2\n");
	expectResult(@"(null)");
}

- (void)testModulus
{
	evaluate(@"print 5 % 3;");
	expectOutput(@"2\n");
	expectResult(@"(null)");
}

- (void)testListSubscript
{
	evaluate(@"print [1, 2, 3][1];");
	expectOutput(@"2\n");
	expectResult(@"(null)");
}

- (void)testWhereExpression
{
	evaluate(@"print ([1, 2, 3] where x : x % 2 == 0).count;");
	expectOutput(@"1\n");
	expectResult(@"(null)");
}

- (void)testMapExpression
{
	evaluate(@"print ([1, 2, 3] map x : x * 2) == [2, 4, 6] ? 'YES' : 'NO';");
	expectOutput(@"YES\n");
	expectResult(@"(null)");
}

- (void)testDictionarySubscript
{
	evaluate(@"print ['1' : 1, '2' : 2, '3' : 3]['2'];");
	expectOutput(@"2\n");
	expectResult(@"(null)");
}

- (void)testWhileLoop
{
	evaluate(@"x := 0; while (x < 1000) x := x + 1; print x;");
	expectOutput(@"1000\n");
	expectResult(@"(null)");
}

- (void)testFunctionDefinitionAndCall
{
	evaluate(@"foo() {} foo();");
	expectOutput(@"");
	expectResult(@"(null)");
}

- (void)testFunctionWithArguments
{
	evaluate(@"foo(a, b) { return a + b; } print foo(\"answer: \", \"42\");");
	expectOutput(@"answer: 42\n");
	expectResult(@"(null)");
}

- (void)testRecursiveFunction
{
	evaluate(@"fac(v) { return v == 0 ? 1 : fac(v - 1) * v; } return fac(5);");
	expectOutput(@"");
	expectResult(@"120");
}

- (void)testTryCatch
{
	evaluate(@"try {\n a := 1 / 0;\n} catch (e) {\n return e;\n}");
	expectOutput(@"");
	expectResult(@"MathError: division by zero");
}

- (void)testMandelbrot
{
	NSString *result =
	@"++++++++++\n"
	@"++++%%++++\n"
	@"++      ++\n"
	@"++ %%%% ++\n"
	@"  %%%%%%  \n"
	@"  +%%%%+  \n"
	@"+  ++++  +\n"
	@"+   ++   +\n"
	@"++      ++\n"
	@"++++  ++++\n";

	NSString *source = @"// mandelbrot\n"
	@"complex_abs(c)\n"
	@"{\n"
	@"    return c[0] * c[0] + c[1] * c[1];\n"
	@"}\n"
	@"\n"
	@"complex_mult(a, b)\n"
	@"{\n"
	@"    return [a[0] * b[0] - a[1] * b[1], a[1] * b[0] + a[0] * b[1]];\n"
	@"}\n"
	@"\n"
	@"complex_add(a, b)\n"
	@"{\n"
	@"    return [a[0] + b[0], a[1] + b[1]];\n"
	@"}\n"
	@"\n"
	@"mandel(c)\n"
	@"{\n"
	@"        z := [0, 0];\n"
	@"        h := 0;\n"
	@"        while (h < 20) {\n"
	@"            z := complex_add(complex_mult(z, z), c);\n"
	@"            if (complex_abs(z) > 2)\n"
	@"                return  (h % 2) != 0 ? \" \" : \"+\";\n"
	@"            h := h + 1;\n"
	@"        }\n"
	@"\n"
	@"        return \"%\";\n"
	@"}\n"
	@"\n"
	@"\n"
	@"\n"
	@"width  := 10;\n"
	@"height := 10;\n"
	@"\n"
	@"x := 0.5;\n"
	@"while (x < width)\n"
	@"{\n"
	@"    line := \"\";\n"
	@"    real := 3 * (x / width - 0.5);\n"
	@"\n"
	@"    y := 0.5;\n"
	@"    while (y < height)\n"
	@"    {\n"
	@"        img := 3 * (y / height - 0.5);\n"
	@"        line := line + mandel([real, img]);\n"
	@"        y := y + 1;\n"
	@"    }\n"
	@"    x := x + 1;\n"
	@"    print line;\n"
	@"}\n";

	evaluate(source);
	expectOutput(result);
	expectResult(@"(null)");
}
@end
