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

@end
