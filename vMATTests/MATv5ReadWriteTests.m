//
//  MATv5ReadWriteTests.m
//  vMAT
//
//  Created by Kaelin Colclasure on 3/29/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "MATv5ReadWriteTests.h"

#import "vMAT.h"


@implementation MATv5ReadWriteTests

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

- (void)test_vMAT_load_float_55x57_v6;
{
    NSURL * URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-single-55x57-v6"
                                                           withExtension:@"mat"];
    NSInputStream * stream = [NSInputStream inputStreamWithURL:URL];
    [stream open];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    vMAT_load(stream, @[@"I"], ^(NSDictionary *workspace, NSError *error) {
        vMAT_MATv5NumericArray * varM = [workspace objectForKey:@"I"];
        float * matM = varM.arrayData.mutableBytes;
        STAssertNotNil(varM, nil);
        STAssertNil(error, nil);
        STAssertEquals(varM.size, vMAT_MakeSize(55, 57), nil);
        [stream close];
        dispatch_semaphore_signal(semaphore);
    });
    long timedout = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW,
                                                                     1 * NSEC_PER_SEC));
    STAssertFalse(timedout, @"Timed out waiting for completion (1s)");
}

- (void)test_vMAT_load_float_55x57_v6_no_variables;
{
    NSURL * URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-float-55x57-v6"
                                                           withExtension:@"mat"];
    NSInputStream * stream = [NSInputStream inputStreamWithURL:URL];
    [stream open];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    vMAT_load(stream, @[], ^(NSDictionary *workspace, NSError *error) {
        STAssertEqualObjects(workspace, @{ }, nil);
        STAssertNil(error, nil);
        [stream close];
        dispatch_semaphore_signal(semaphore);
    });
    long timedout = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW,
                                                                     1 * NSEC_PER_SEC));
    STAssertFalse(timedout, @"Timed out waiting for completion (1s)");
}

- (void)test_vMAT_load_magic_4x4_v6;
{
    NSURL * URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-magic-4x4-v6"
                                                           withExtension:@"mat"];
    NSInputStream * stream = [NSInputStream inputStreamWithURL:URL];
    [stream open];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    vMAT_load(stream, @[@"M"], ^(NSDictionary *workspace, NSError *error) {
        const double M[] = {
            16.00000,   5.00000,   9.00000,   4.00000,
             2.00000,  11.00000,   7.00000,  14.00000,
             3.00000,  10.00000,   6.00000,  15.00000,
            13.00000,   8.00000,  12.00000,   1.00000,
        };
        vMAT_MATv5NumericArray * varM = [workspace objectForKey:@"M"];
        double * matM = varM.arrayData.mutableBytes;
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

- (void)test_vMAT_load_magic_4x4_v6_no_variables;
{
    NSURL * URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-magic-4x4-v6"
                                                           withExtension:@"mat"];
    NSInputStream * stream = [NSInputStream inputStreamWithURL:URL];
    [stream open];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    vMAT_load(stream, @[], ^(NSDictionary *workspace, NSError *error) {
        STAssertEqualObjects(workspace, @{ }, nil);
        STAssertNil(error, nil);
        [stream close];
        dispatch_semaphore_signal(semaphore);
    });
    long timedout = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW,
                                                                     1 * NSEC_PER_SEC));
    STAssertFalse(timedout, @"Timed out waiting for completion (1s)");
}

- (void)test_vMAT_load_nil_stream;
{
    STAssertThrowsSpecificNamed(vMAT_load(nil, nil, ^(NSDictionary *workspace, NSError *error) {
    }), NSException, NSInternalInconsistencyException, nil);
}

- (void)test_vMAT_load_order_5x4x3x2_v6;
{
    NSURL * URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-order-5x4x3x2-v6"
                                                           withExtension:@"mat"];
    NSInputStream * stream = [NSInputStream inputStreamWithURL:URL];
    [stream open];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    vMAT_load(stream, @[@"ND4"], ^(NSDictionary *workspace, NSError *error) {
        vMAT_MATv5NumericArray * varM = [workspace objectForKey:@"ND4"];
        uint8_t * matM = varM.arrayData.mutableBytes;
        STAssertNotNil(varM, nil);
        STAssertNil(error, nil);
        STAssertEquals(varM.size, vMAT_MakeSize(5, 4, 3, 2), nil);
        STAssertEquals(varM.arrayData.length, (NSUInteger)120, nil);
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

@end
