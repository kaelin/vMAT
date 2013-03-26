//
//  vMATTests.m
//  vMATTests
//
//  Created by Kaelin Colclasure on 3/24/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMATTests.h"

#import <sys/types.h>
#import <sys/stat.h>

#import "vMAT.h"


@implementation vMATTests

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

- (void)test_vMAT_eye;
{
    vMAT_eye(1, 1, ^(float * output,
                     vDSP_Length outputLength,
                     bool * keepOutput) {
        STAssertTrue(output != NULL, nil);
        STAssertEquals(outputLength, (vDSP_Length)1, nil);
        STAssertEquals(output[0], 1.f, nil);
    });
    vMAT_eye(3, 3, ^(float * output,
                     vDSP_Length outputLength,
                     bool * keepOutput) {
        STAssertTrue(output != NULL, nil);
        const float EYE[] = {
            1.00000,   0.00000,   0.00000,
            0.00000,   1.00000,   0.00000,
            0.00000,   0.00000,   1.00000,
        };
        STAssertEquals(outputLength, (vDSP_Length)(sizeof(EYE) / sizeof(float)), nil);
        for (int i = 0; i < sizeof(EYE) / sizeof(float); i++) {
            STAssertEquals(output[i], EYE[i], nil);
        }
    });
    vMAT_eye(3, 5, ^(float * output,
                     vDSP_Length outputLength,
                     bool * keepOutput) {
        STAssertTrue(output != NULL, nil);
        const float EYE[] = {
            1.00000,   0.00000,   0.00000,   0.00000,   0.00000,
            0.00000,   1.00000,   0.00000,   0.00000,   0.00000,
            0.00000,   0.00000,   1.00000,   0.00000,   0.00000,
        };
        STAssertEquals(outputLength, (vDSP_Length)(sizeof(EYE) / sizeof(float)), nil);
        for (int i = 0; i < sizeof(EYE) / sizeof(float); i++) {
            STAssertEquals(output[i], EYE[i], nil);
        }
    });
    vMAT_eye(3, 2, ^(float * output,
                     vDSP_Length outputLength,
                     bool * keepOutput) {
        STAssertTrue(output != NULL, nil);
        const float EYE[] = {
            1.00000,   0.00000,
            0.00000,   1.00000,
            0.00000,   0.00000,
        };
        STAssertEquals(outputLength, (vDSP_Length)(sizeof(EYE) / sizeof(float)), nil);
        for (int i = 0; i < sizeof(EYE) / sizeof(float); i++) {
            STAssertEquals(output[i], EYE[i], nil);
        }
    });
}

- (void)test_vMAT_fread;
{
    float identity = 1.f;
    NSInputStream * stream = [NSInputStream inputStreamWithData:[NSData dataWithBytes:&identity
                                                                               length:sizeof(identity)]];
    [stream open];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    vMAT_fread(stream, 1, 1, nil, ^(float *output,
                                    vDSP_Length outputLength,
                                    NSData *outputData,
                                    NSError *error) {
        STAssertTrue(output != NULL, nil);
        STAssertEquals(outputLength, (vDSP_Length)1, nil);
        STAssertNotNil(outputData, nil);
        STAssertNil(error, nil);
        STAssertEquals(output[0], identity, nil);
        dispatch_semaphore_signal(semaphore);
        sleep(3); // Tie up one concurrent vMATStreamWorker worker slot…
    });
    long timedout = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW,
                                                                     1 * NSEC_PER_SEC));
    STAssertFalse(timedout, @"Timed out waiting for completion (1s)");
}

- (void)test_vMAT_fread_again;
{
    float identity = 1.f;
    NSInputStream * stream = [NSInputStream inputStreamWithData:[NSData dataWithBytes:&identity
                                                                               length:sizeof(identity)]];
    [stream open];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    vMAT_fread(stream, 1, 1, nil, ^(float *output,
                                    vDSP_Length outputLength,
                                    NSData *outputData,
                                    NSError *error) {
        STAssertTrue(output != NULL, nil);
        STAssertEquals(outputLength, (vDSP_Length)1, nil);
        STAssertNotNil(outputData, nil);
        STAssertNil(error, nil);
        STAssertEquals(output[0], identity, nil);
        dispatch_semaphore_signal(semaphore);
    });
    long timedout = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW,
                                                                     1 * NSEC_PER_SEC));
    STAssertFalse(timedout, @"Timed out waiting for completion (1s)");
}

- (void)test_vMAT_fread_named_pipe;
{
    NSString * pipePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"otest-%d.fifo", getpid()]];
    int rc = mkfifo([pipePath UTF8String], 0600);
    STAssertTrue(rc == 0, @"mkfifo: %s", strerror(errno));
    if (rc != 0) return; // Can't really do anything more…
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^ {
        float I[] = { 1, 2, 3 };
        int ofd = open([pipePath UTF8String], O_WRONLY);
        STAssertTrue(ofd >= 0, @"open: %s", strerror(errno));
        for (int i = 0;
             i < 3;
             i++) {
            [NSThread sleepForTimeInterval:0.1];
            size_t lenw = write(ofd, &I[i], sizeof(float));
            STAssertEquals(lenw, (size_t)4, nil);
        }
        close(ofd);
        // NSLog(@"named pipe closed");
    });
    NSInputStream * stream = [NSInputStream inputStreamWithFileAtPath:pipePath];
    [stream open];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    vMAT_fread(stream, 1, 3, nil, ^(float *output,
                                    vDSP_Length outputLength,
                                    NSData *outputData,
                                    NSError *error) {
        const float O[] = { 1, 2, 3 };
        STAssertTrue(output != NULL, nil);
        STAssertEquals(outputLength, (vDSP_Length)(sizeof(O) / sizeof(float)), nil);
        STAssertNotNil(outputData, nil);
        STAssertNil(error, nil);
        for (int i = 0; i < sizeof(O) / sizeof(float); i++) {
            STAssertEqualsWithAccuracy(output[i], O[i], 0.00001, nil);
        }
        dispatch_semaphore_signal(semaphore);
    });
    long timedout = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW,
                                                                     3 * NSEC_PER_SEC));
    STAssertFalse(timedout, @"Timed out waiting for completion (3s)");
    unlink([pipePath UTF8String]);
}

// TODO: Make vMAT_linkage use pdist Y vector directly, with appropriate error checking...

- (void)test_vMAT_linkage;
{
    const float DX3[] = {
        0.00000,   0.35890,   0.37169,
        0.35890,   0.00000,   0.57118,
        0.37169,   0.57118,   0.00000,
    };
    vMAT_linkage(DX3, 3 * 3, ^void(float *outputMatrix,
                                   vDSP_Length outputMatrixLength,
                                   bool *keepOutput) {
        STAssertTrue(outputMatrix != NULL, nil);
        const float Z[] = {
            0.00000,   1.00000,   0.35890,
            2.00000,   3.00000,   0.37169,
        };
        for (int i = 0; i < sizeof(Z) / sizeof(float); i += 3) {
            STAssertEquals(outputMatrix[i], Z[i], nil);
        }
        for (int i = 2; i < sizeof(Z) / sizeof(float); i += 3) {
            STAssertEqualsWithAccuracy(outputMatrix[i], Z[i], 0.00001f, nil);
        }
    });
    const float DX5[] = {
        0.00000,   1.00653,   1.94386,   1.45824,   1.79334,
        1.00653,   0.00000,   1.70235,   1.05808,   1.43369,
        1.94386,   1.70235,   0.00000,   1.61046,   1.97345,
        1.45824,   1.05808,   1.61046,   0.00000,   0.60483,
        1.79334,   1.43369,   1.97345,   0.60483,   0.00000,
    };
    vMAT_linkage(DX5, 5 * 5, ^void(float *outputMatrix,
                                   vDSP_Length outputMatrixLength,
                                   bool *keepOutput) {
        STAssertTrue(outputMatrix != NULL, nil);
        const float Z[] = {
            3.00000,   4.00000,   0.60483,
            0.00000,   1.00000,   1.00653,
            5.00000,   6.00000,   1.05808,
            2.00000,   7.00000,   1.61046,
        };
        for (int i = 0; i < sizeof(Z) / sizeof(float); i += 3) {
            STAssertEquals(outputMatrix[i], Z[i], nil);
        }
        for (int i = 2; i < sizeof(Z) / sizeof(float); i += 3) {
            STAssertEqualsWithAccuracy(outputMatrix[i], Z[i], 0.00001f, nil);
        }
    });
    const float DX13[] = {
        0.00000,   2.45957,   3.69130,   0.60862,   2.42783,   2.03075,   1.66318,   2.66048,   2.10097,   2.07983,   1.72041,   4.74285,   0.72944,
        2.45957,   0.00000,   1.88828,   2.51504,   0.27222,   1.38048,   1.35989,   2.42891,   4.06210,   2.01967,   1.76342,   3.98824,   2.40666,
        3.69130,   1.88828,   0.00000,   3.97192,   2.04404,   3.12194,   3.00824,   2.92675,   4.55415,   3.58770,   3.59495,   2.39992,   3.72631,
        0.60862,   2.51504,   3.97192,   0.00000,   2.43099,   1.94613,   1.66238,   3.03596,   2.50275,   2.04774,   1.39413,   5.23165,   0.98100,
        2.42783,   0.27222,   2.04404,   2.43099,   0.00000,   1.41478,   1.40657,   2.65506,   4.04296,   2.09557,   1.66367,   4.14998,   2.42930,
        2.03075,   1.38048,   3.12194,   1.94613,   1.41478,   0.00000,   0.41539,   2.13220,   4.04957,   0.72692,   0.87677,   4.95117,   1.65543,
        1.66318,   1.35989,   3.00824,   1.66238,   1.40657,   0.41539,   0.00000,   1.93653,   3.65043,   0.78444,   0.91077,   4.69623,   1.30063,
        2.66048,   2.42891,   2.92675,   3.03596,   2.65506,   2.13220,   1.93653,   0.00000,   3.94957,   1.88279,   2.82975,   3.84346,   2.15811,
        2.10097,   4.06210,   4.55415,   2.50275,   4.04296,   4.04957,   3.65043,   3.94957,   0.00000,   4.08638,   3.77885,   4.60534,   2.63877,
        2.07983,   2.01967,   3.58770,   2.04774,   2.09557,   0.72692,   0.78444,   1.88279,   4.08638,   0.00000,   1.27421,   5.20319,   1.49068,
        1.72041,   1.76342,   3.59495,   1.39413,   1.66367,   0.87677,   0.91077,   2.82975,   3.77885,   1.27421,   0.00000,   5.38725,   1.56200,
        4.74285,   3.98824,   2.39992,   5.23165,   4.14998,   4.95117,   4.69623,   3.84346,   4.60534,   5.20319,   5.38725,   0.00000,   4.85512,
        0.72944,   2.40666,   3.72631,   0.98100,   2.42930,   1.65543,   1.30063,   2.15811,   2.63877,   1.49068,   1.56200,   4.85512,   0.00000,
    };
    vMAT_linkage(DX13, 13 * 13, ^void(float *outputMatrix,
                                      vDSP_Length outputMatrixLength,
                                      bool *keepOutput) {
        STAssertTrue(outputMatrix != NULL, nil);
        const float Z[] = {
             1.00000,   4.00000,   0.27222,
             5.00000,   6.00000,   0.41539,
             0.00000,   3.00000,   0.60862,
             9.00000,  14.00000,   0.72692,
            12.00000,  15.00000,   0.72944,
            10.00000,  16.00000,   0.87677,
            17.00000,  18.00000,   1.30063,
            13.00000,  19.00000,   1.35989,
             7.00000,  20.00000,   1.88279,
             2.00000,  21.00000,   1.88828,
             8.00000,  22.00000,   2.10097,
            11.00000,  23.00000,   2.39992,
        };
        for (int i = 0; i < sizeof(Z) / sizeof(float); i += 3) {
            STAssertEquals(outputMatrix[i], Z[i], nil);
        }
        for (int i = 2; i < sizeof(Z) / sizeof(float); i += 3) {
            STAssertEqualsWithAccuracy(outputMatrix[i], Z[i], 0.00001f, nil);
        }
    });
}

- (void)test_vMAT_pdist;
{
    vMAT_eye(3, 2, ^(float * output, vDSP_Length outputLength, bool * keepOutput) {
        vMAT_pdist(output, 3, 2, ^(float * output, vDSP_Length outputLength, bool * keepOutput) {
            STAssertTrue(output != NULL, nil);
            const float Y[] = {
                1.41421,   1.00000,   1.00000,
            };
            STAssertEquals(outputLength, (vDSP_Length)(sizeof(Y) / sizeof(float)), nil);
            for (int i = 0; i < sizeof(Y) / sizeof(float); i++) {
                STAssertEqualsWithAccuracy(output[i], Y[i], 0.00001, nil);
            }
        });
    });
}

- (void)test_vMAT_pdist2;
{
    NSMutableData * samplesA = [NSMutableData data];
    NSMutableData * samplesB = [NSMutableData data];
    vMAT_eye(3, 2, ^(float * output, vDSP_Length outputLength, bool * keepOutput) {
        [samplesA appendBytes:output
                       length:outputLength * sizeof(*output)];
        [samplesB appendBytes:output
                       length:outputLength * sizeof(*output)];
        [samplesB appendBytes:output
                       length:outputLength * sizeof(*output)];
        [samplesB appendBytes:output
                       length:outputLength * sizeof(*output)];
        float * input = [samplesB mutableBytes];
        float * part2 = &input[1 * outputLength];
        float * part3 = &input[2 * outputLength];
        float k = 1.f;
        vDSP_vsadd(input, 1, &k, part2, 1, outputLength);
        k++;
        vDSP_vsadd(input, 1, &k, part3, 1, outputLength);
        k = 0.5f;
        vDSP_vsmul(part2, 1, &k, part2, 1, outputLength);
        k = -k;
        vDSP_vsmul(part3, 1, &k, part3, 1, outputLength);
    });
    STAssertTrue([samplesB length] == 3 * [samplesA length], nil);
    vMAT_pdist2([samplesA mutableBytes], 3, [samplesB mutableBytes], 3 * 3, 2, ^(float * output,
                                                                                 vDSP_Length outputLength,
                                                                                 bool *keepOutput) {
        STAssertTrue(output != NULL, nil);
        const float Y[] = {
            0.00000,   1.41421,   1.00000,   0.50000,   1.11803,   0.70711,   2.69258,   2.50000,   2.23607,
            1.41421,   0.00000,   1.00000,   1.11803,   0.50000,   0.70711,   2.50000,   2.69258,   2.23607,
            1.00000,   1.00000,   0.00000,   1.11803,   1.11803,   0.70711,   1.80278,   1.80278,   1.41421,
        };
        STAssertEquals(outputLength, (vDSP_Length)(sizeof(Y) / sizeof(float)), nil);
        for (int i = 0; i < sizeof(Y) / sizeof(float); i++) {
            STAssertEqualsWithAccuracy(output[i], Y[i], 0.00001, nil);
        }
    });
}

@end
