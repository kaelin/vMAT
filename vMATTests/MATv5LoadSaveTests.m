//
//  MATv5LoadSaveTests.m
//  vMAT
//
//  Created by Kaelin Colclasure on 3/29/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "MATv5LoadSaveTests.h"

#import "vMAT.h"


@implementation MATv5LoadSaveTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)test_vMAT_load_async_single_55x57_v6;
{
    NSURL * URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-single-55x57-v6"
                                                           withExtension:@"mat"];
    NSInputStream * stream = [NSInputStream inputStreamWithURL:URL];
    [stream open];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    vMAT_load_async(stream, @[@"I"], ^(NSDictionary *workspace, NSError *error) {
        vMAT_MATv5NumericArray * varM = [workspace objectForKey:@"I"];
        vMAT_Array * matM = varM.matrix;
        STAssertNotNil(varM, nil);
        STAssertNil(error, nil);
        STAssertEquals(varM.size, vMAT_MakeSize(55, 57), nil);
        STAssertEquals(matM.size, varM.size, nil);
        [stream close];
        dispatch_semaphore_signal(semaphore);
    });
    long timedout = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW,
                                                                     1 * NSEC_PER_SEC));
    STAssertFalse(timedout, @"Timed out waiting for completion (1s)");
}

- (void)test_vMAT_load_async_single_55x57_v6_no_variables;
{
    NSURL * URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-single-55x57-v6"
                                                           withExtension:@"mat"];
    NSInputStream * stream = [NSInputStream inputStreamWithURL:URL];
    [stream open];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    vMAT_load_async(stream, @[], ^(NSDictionary *workspace, NSError *error) {
        STAssertEqualObjects(workspace, @{ }, nil);
        STAssertNil(error, nil);
        [stream close];
        dispatch_semaphore_signal(semaphore);
    });
    long timedout = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW,
                                                                     1 * NSEC_PER_SEC));
    STAssertFalse(timedout, @"Timed out waiting for completion (1s)");
}

- (void)test_vMAT_load_async_magic_4x4_v6;
{
    NSURL * URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-magic-4x4-v6"
                                                           withExtension:@"mat"];
    NSInputStream * stream = [NSInputStream inputStreamWithURL:URL];
    [stream open];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    vMAT_load_async(stream, @[ @"M" ], ^(NSDictionary *workspace, NSError *error) {
        const double M[] = {
            16,   5,   9,   4,
             2,  11,   7,  14,
             3,  10,   6,  15,
            13,   8,  12,   1,
        };
        vMAT_MATv5NumericArray * varM = [workspace variable:@"M"].toNumericArray;
        double * matM = varM.array.data.mutableBytes;
        STAssertNotNil(varM, nil);
        STAssertNil(error, nil);
        STAssertEquals(varM.size, vMAT_MakeSize(4, 4), nil);
        for (int i = 0; i < sizeof(M) / sizeof(*M); i++) {
            STAssertEqualsWithAccuracy(matM[i], M[i], 0.0001, nil);
        }
        [stream close];
        dispatch_semaphore_signal(semaphore);
    });
    long timedout = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW,
                                                                     1 * NSEC_PER_SEC));
    STAssertFalse(timedout, @"Timed out waiting for completion (1s)");
}

- (void)test_vMAT_load_async_magic_4x4_v6_no_variables;
{
    NSURL * URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-magic-4x4-v6"
                                                           withExtension:@"mat"];
    NSInputStream * stream = [NSInputStream inputStreamWithURL:URL];
    [stream open];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    vMAT_load_async(stream, @[], ^(NSDictionary *workspace, NSError *error) {
        STAssertEqualObjects(workspace, @{ }, nil);
        STAssertNil(error, nil);
        [stream close];
        dispatch_semaphore_signal(semaphore);
    });
    long timedout = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW,
                                                                     1 * NSEC_PER_SEC));
    STAssertFalse(timedout, @"Timed out waiting for completion (1s)");
}

- (void)test_vMAT_load_async_multiple_variables;
{
    NSURL * URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"cluster-normaldata-10x3-13"
                                                           withExtension:@"mat"];
    NSInputStream * stream = [NSInputStream inputStreamWithURL:URL];
    [stream open];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    vMAT_load_async(stream, @[@"X", @"Y", @"Zv"], ^(NSDictionary * workspace, NSError * error) {
        // NSLog(@"%@", workspace);
        STAssertNotNil([workspace objectForKey:@"X"], nil);
        STAssertNotNil([workspace objectForKey:@"Y"], nil);
        STAssertNotNil([workspace objectForKey:@"Zv"], nil);
        [stream close];
        dispatch_semaphore_signal(semaphore);
    });
    long timedout = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW,
                                                                     1 * NSEC_PER_SEC));
    STAssertFalse(timedout, @"Timed out waiting for completion (1s)");
}

- (void)test_vMAT_load_async_nil_stream;
{
    STAssertThrowsSpecificNamed(vMAT_load_async(nil, nil, ^(NSDictionary *workspace, NSError *error) {
    }), NSException, NSInternalInconsistencyException, nil);
}

- (void)test_vMAT_load_async_order_5x4x3x2_v6;
{
    NSURL * URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-order-5x4x3x2-v6"
                                                           withExtension:@"mat"];
    NSInputStream * stream = [NSInputStream inputStreamWithURL:URL];
    [stream open];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    vMAT_load_async(stream, @[@"ND4"], ^(NSDictionary *workspace, NSError *error) {
        vMAT_MATv5NumericArray * varM = [workspace objectForKey:@"ND4"];
        uint8_t * matM = varM.array.data.mutableBytes;
        STAssertNotNil(varM, nil);
        STAssertNil(error, nil);
        STAssertEquals(varM.size, vMAT_MakeSize(5, 4, 3, 2), nil);
        STAssertEquals(varM.array.data.length, (NSUInteger)120, nil);
        STAssertEquals(matM[0], (uint8_t)0, nil);
        STAssertEquals(matM[20], (uint8_t)20, nil);
        STAssertEquals(matM[40], (uint8_t)40, nil);
        STAssertEquals(matM[60], (uint8_t)60, nil);
        STAssertEquals(matM[80], (uint8_t)80, nil);
        STAssertEquals(matM[100], (uint8_t)100, nil);
        [stream close];
        dispatch_semaphore_signal(semaphore);
    });
    long timedout = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW,
                                                                     1 * NSEC_PER_SEC));
    STAssertFalse(timedout, @"Timed out waiting for completion (1s)");
}

- (void)test_vMAT_load_multiple_variables;
{
    NSURL * URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"cluster-normaldata-10x3-13"
                                                           withExtension:@"mat"];
    NSError * error = nil;
    NSDictionary * workspace = vMAT_load(URL, @[@"X", @"Y", @"Zv"], &error);
    // NSLog(@"%@", workspace);
    STAssertNil(error, nil);
    STAssertNotNil([workspace objectForKey:@"X"], nil);
    STAssertNotNil([workspace objectForKey:@"Y"], nil);
    STAssertNotNil([workspace objectForKey:@"Zv"], nil);
}

- (void)test_vMAT_load_nil_URL;
{
    STAssertThrowsSpecificNamed(vMAT_load(nil, nil, NULL), NSException, NSInternalInconsistencyException, nil);
}

- (void)test_vMAT_save_multiple_variables;
{
    NSURL * inputURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"cluster-normaldata-10x3-13"
                                                                withExtension:@"mat"];
    NSError * error = nil;
    NSDictionary * workspace = vMAT_load(inputURL, @[@"X", @"Y", @"Zv"], &error);
    STAssertNil(error, nil);
    NSString * tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"otest-%@-%d.mat",
                                                                                 @"cluster-normaldata-10x3-13", getpid()]];
    NSURL * outputURL = [NSURL fileURLWithPath:tmpPath isDirectory:NO];
    vMAT_save(outputURL, workspace, &error);
    // NSLog(@"%@", workspace);
    STAssertNil(error, nil);
    STAssertNotNil([workspace objectForKey:@"X"], nil);
    STAssertNotNil([workspace objectForKey:@"Y"], nil);
    STAssertNotNil([workspace objectForKey:@"Zv"], nil);
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSDictionary * attrs = [fileManager attributesOfItemAtPath:tmpPath error:&error];
    NSLog(@"attrs = %@", attrs);
    STAssertTrue([[attrs objectForKey:NSFileSize] longValue] > 0, nil);
    STAssertNil(error, nil);
    NSURL * trashURL = nil;
    [fileManager trashItemAtURL:outputURL resultingItemURL:&trashURL error:&error];
    STAssertNil(error, nil);
}

- (void)test_vMAT_save_nil_URL;
{
    STAssertThrowsSpecificNamed(vMAT_save(nil, nil, NULL), NSException, NSInternalInconsistencyException, nil);
}

- (void)test_vMAT_manifesto;
{
    NSURL * URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-magic-4x4-v6"
                                                           withExtension:@"mat"];
    NSError * error = nil;
    NSDictionary * workspace = vMAT_load(URL, @[ @"M" ], &error);
    NSLog(@"workspace = %@", workspace);
    vMAT_Array * matM = [workspace variable:@"M"].matrix;
    STAssertNotNil(matM, @"Failed to load M");
}

@end
