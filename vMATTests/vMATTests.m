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
    vMAT_Array * matE = nil;
    const double * E = NULL;
    matE = vMAT_eye(vMAT_MakeSize(1));
    {
        E = matE.data.bytes;
        STAssertNotNil(matE, nil);
        STAssertEquals(matE.data.length, sizeof(double), nil);
        STAssertEquals(E[0], 1.0, nil);
    }
    matE = vMAT_eye(vMAT_MakeSize(3));
    {
        const double EYE[] = {
            1, 0, 0,
            0, 1, 0,
            0, 0, 1,
        };
        E = matE.data.bytes;
        STAssertNotNil(matE, nil);
        STAssertEquals(matE.data.length, sizeof(EYE), nil);
        for (int i = 0; i < sizeof(EYE) / sizeof(*EYE); i++) {
            STAssertEquals(E[i], EYE[i], nil);
        }
    }
    matE = vMAT_eye(vMAT_MakeSize(3, 5));
    {
        const double EYE[] = {
            1, 0, 0,
            0, 1, 0,
            0, 0, 1,
            0, 0, 0,
            0, 0, 0,
        };
        E = matE.data.bytes;
        STAssertNotNil(matE, nil);
        STAssertEquals(matE.data.length, sizeof(EYE), nil);
        for (int i = 0; i < sizeof(EYE) / sizeof(*EYE); i++) {
            STAssertEquals(E[i], EYE[i], nil);
        }
    }
    matE = vMAT_eye(vMAT_MakeSize(3, 2));
    {
        const double EYE[] = {
            1, 0, 0,
            0, 1, 0,
        };
        E = matE.data.bytes;
        STAssertNotNil(matE, nil);
        STAssertEquals(matE.data.length, sizeof(EYE), nil);
        for (int i = 0; i < sizeof(EYE) / sizeof(*EYE); i++) {
            STAssertEquals(E[i], EYE[i], nil);
        }
    }
}

- (void)test_vMAT_fread;
{
    float identity = 1.f;
    NSInputStream * stream = [NSInputStream inputStreamWithData:[NSData dataWithBytes:&identity
                                                                               length:sizeof(identity)]];
    [stream open];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    vMAT_Array * matI = [vMAT_Array arrayWithSize:vMAT_MakeSize(1, 1) type:miSINGLE];
    vMAT_fread(stream, matI, nil, ^(vMAT_Array * matI, NSError * error) {
        const float * I = matI.data.bytes;
        STAssertNotNil(matI, nil);
        STAssertNil(error, nil);
        STAssertEqualObjects(vMAT_StringFromSize(matI.size), @"[1 1]", nil);
        STAssertEquals(I[0], identity, nil);
        [stream close];
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
    vMAT_Array * matI = [vMAT_Array arrayWithSize:vMAT_MakeSize(1) type:miSINGLE];
    vMAT_fread(stream, matI, nil, ^(vMAT_Array * matI, NSError * error) {
        const float * I = matI.data.bytes;
        STAssertNotNil(matI, nil);
        STAssertNil(error, nil);
        STAssertEqualObjects(vMAT_StringFromSize(matI.size), @"[1 1]", nil);
        STAssertEquals(I[0], identity, nil);
        [stream close];
        dispatch_semaphore_signal(semaphore);
    });
    long timedout = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW,
                                                                     1 * NSEC_PER_SEC));
    STAssertFalse(timedout, @"Timed out waiting for completion (1s)");
}

- (void)test_vMAT_fread_matlab_dat;
{
    NSURL * URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-single-4x3"
                                                           withExtension:@"dat"];
    NSInputStream * stream = [NSInputStream inputStreamWithURL:URL];
    [stream open];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    vMAT_Array * matI = [vMAT_Array arrayWithSize:vMAT_MakeSize(4) type:miSINGLE];
    
    vMAT_fread(stream, matI, nil, ^(vMAT_Array * matI, NSError * error) {
        const float M[] = {
             2, 11,  7, 14,
             3, 10,  6, 15,
            13,  8, 12,  1,
        };
        const float * I = matI.data.bytes;
        STAssertNotNil(matI, nil);
        STAssertNil(error, nil);
        STAssertEqualObjects(vMAT_StringFromSize(matI.size), @"[4 3]", nil);
        for (int i = 0; i < sizeof(M) / sizeof(*M); i++) {
            STAssertEqualsWithAccuracy(I[i], M[i], 0.0001, nil);
        }
        [stream close];
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
        float I[] = { 1, 3, 5 };
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
    vMAT_Array * matI = [vMAT_Array arrayWithSize:vMAT_MakeSize(3) type:miSINGLE];
    vMAT_fread(stream, matI, nil, ^(vMAT_Array * matI, NSError * error) {
        const float O[] = { 1, 3, 5 };
        const float * I = matI.data.bytes;
        STAssertNotNil(matI, nil);
        STAssertNil(error, nil);
        STAssertEqualObjects(vMAT_StringFromSize(matI.size), @"[3 1]", nil);
        for (int i = 0; i < sizeof(O) / sizeof(*O); i++) {
            STAssertEqualsWithAccuracy(I[i], O[i], 0.0001, nil);
        }
        [stream close];
        dispatch_semaphore_signal(semaphore);
    });
    long timedout = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW,
                                                                     3 * NSEC_PER_SEC));
    STAssertFalse(timedout, @"Timed out waiting for completion (3s)");
    unlink([pipePath UTF8String]);
}

- (void)test_vMAT_fread_nil_stream;
{
    vMAT_Array * matI = [vMAT_Array arrayWithSize:vMAT_MakeSize(1) type:miDOUBLE];
    STAssertThrowsSpecificNamed(vMAT_fread(nil, matI, nil, ^(vMAT_Array * matrix, NSError * error) {
    }), NSException, NSInternalInconsistencyException, nil);
}

- (void)test_vMAT_fread_short_pipe;
{
    NSString * pipePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"otest-%d.fifo", getpid()]];
    int rc = mkfifo([pipePath UTF8String], 0600);
    STAssertTrue(rc == 0, @"mkfifo: %s", strerror(errno));
    if (rc != 0) return; // Can't really do anything more…
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^ {
        float I[] = { 1, 3, 5 };
        int ofd = open([pipePath UTF8String], O_WRONLY);
        STAssertTrue(ofd >= 0, @"open: %s", strerror(errno));
        for (int i = 0;
             i < 2;
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
    vMAT_Array * matI = [vMAT_Array arrayWithSize:vMAT_MakeSize(3, 1) type:miSINGLE];
    vMAT_fread(stream, matI, nil, ^(vMAT_Array * matI, NSError * error) {
        STAssertNil(matI, nil);
        STAssertNotNil(error, nil);
        STAssertEqualObjects([error domain], vMAT_ErrorDomain, nil);
        STAssertEquals([error code], (NSInteger)vMAT_ErrorCodeEndOfStream, nil);
        // NSLog(@"%@", [error localizedDescription]);
        [stream close];
        dispatch_semaphore_signal(semaphore);
    });
    long timedout = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW,
                                                                     3 * NSEC_PER_SEC));
    STAssertFalse(timedout, @"Timed out waiting for completion (3s)");
    unlink([pipePath UTF8String]);
}

- (void)test_vMAT_fwrite;
{
    const float M[] = {
         2, 11,  7, 14,
         3, 10,  6, 15,
        13,  8, 12,  1,
    };
    vMAT_Array * matM = [vMAT_Array arrayWithSize:vMAT_MakeSize(4, 3)
                                             type:miSINGLE
                                             data:[NSData dataWithBytes:M length:sizeof(M)]];
    NSOutputStream * stream = [NSOutputStream outputStreamToMemory];
    [stream open];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    vMAT_fwrite(stream, matM, nil, ^(vDSP_Length outputLength,
                                     NSError *error) {
        const float M[] = {
             2, 11,  7, 14,
             3, 10,  6, 15,
            13,  8, 12,  1,
        };
        STAssertEquals(outputLength, (vDSP_Length)(sizeof(M) / sizeof(*M)), nil);
        STAssertNil(error, nil);
        float * output = (float *)[[stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey] bytes];
        for (int i = 0; i < outputLength; i++) {
            STAssertEqualsWithAccuracy(output[i], M[i], 0.0001, nil);
        }
        [stream close];
        dispatch_semaphore_signal(semaphore);
    });
    long timedout = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW,
                                                                     1 * NSEC_PER_SEC));
    STAssertFalse(timedout, @"Timed out waiting for completion (1s)");
}

- (void)test_vMAT_fwrite_nil_stream;
{
    const float M[] = {
         2, 11,  7, 14,
         3, 10,  6, 15,
        13,  8, 12,  1,
    };
    vMAT_Array * matM = [vMAT_Array arrayWithSize:vMAT_MakeSize(4, 3)
                                             type:miSINGLE
                                             data:[NSData dataWithBytes:M length:sizeof(M)]];
    STAssertThrowsSpecificNamed(vMAT_fwrite(nil, matM, nil, ^(vDSP_Length outputLength, NSError * error) {
    }), NSException, NSInternalInconsistencyException, nil);
}

- (void)test_vMAT_pdist;
{
    vMAT_Array * matY = nil;
    const float * Y = NULL;
    vMAT_Array * matE = vMAT_single(vMAT_eye(vMAT_MakeSize(2, 3)));
    matY = vMAT_pdist(matE);
    {
        const float Z[] = {
            1.41421,   1.00000,   1.00000,
        };
        Y = matY.data.bytes;
        STAssertNotNil(matY, nil);
        STAssertEquals(matY.data.length, sizeof(Z), nil);
        STAssertEqualObjects(vMAT_StringFromSize(matY.size), @"[3 1]", nil);
        for (int i = 0; i < sizeof(Z) / sizeof(*Z); i++) {
            STAssertEqualsWithAccuracy(Y[i], Z[i], 0.0001, nil);
        }
    }
    const float X[] = { // Random 8x5
        0.21350,   0.37459,   0.17548,   0.69542,   0.10375,   0.31814,   0.25488,   0.12684,
        0.54601,   0.07173,   0.11765,   0.79231,   0.71214,   0.88801,   0.45643,   0.15090,
        0.89049,   0.15973,   0.37356,   0.42520,   0.17415,   0.49690,   0.63717,   0.52755,
        0.15159,   0.38467,   0.29949,   0.93501,   0.88486,   0.92916,   0.88510,   0.56326,
        0.43272,   0.73036,   0.55689,   0.59528,   0.77017,   0.78671,   0.07482,   0.91418,
    };
    vMAT_Array * matX = [vMAT_Array arrayWithSize:vMAT_MakeSize(8, 5)
                                             type:miSINGLE
                                             data:[NSData dataWithBytes:X length:sizeof(X)]];
    matY = vMAT_pdist(matX);
    {
        const float Z[] = {
            0.97525, 0.97998, 1.28368, 1.28301, 0.97138, 0.83201, 1.19173, 1.27148, 1.22583, 1.09240,
        };
        Y = matY.data.bytes;
        STAssertNotNil(matY, nil);
        STAssertEquals(matY.data.length, sizeof(Z), nil);
        STAssertEqualObjects(vMAT_StringFromSize(matY.size), @"[10 1]", nil);
        for (int i = 0; i < sizeof(Z) / sizeof(*Z); i++) {
            STAssertEqualsWithAccuracy(Y[i], Z[i], 0.0001, nil);
        }
    }
}

- (void)test_vMAT_pdist2;
{
    vMAT_Array * matD = nil;
    const float * D = NULL;
    const float A[] = { // Top two rows of magic(4)
        16,  5,
         2, 11,
         3, 10,
        13,  8,
    };
    const float B[] = { // Bottom two rows of magic(4)
         9,  4,
         7, 14,
         6, 15,
        12,  1,
    };
    vMAT_Array * matA = [vMAT_Array arrayWithSize:vMAT_MakeSize(2, 4)
                                             type:miSINGLE
                                             data:[NSData dataWithBytes:A length:sizeof(A)]];
    vMAT_Array * matB = [vMAT_Array arrayWithSize:vMAT_MakeSize(2, 4)
                                             type:miSINGLE
                                             data:[NSData dataWithBytes:B length:sizeof(B)]];
    matD = vMAT_pdist2(matA, matB);
    {
        const float E[] = {
             7.07107,   9.89949,   8.48528,   5.65685,
            12.72792,   5.83095,   5.65685,   8.48528,
            14.14214,   5.65685,   5.83095,   9.89949,
             5.65685,  14.14214,  12.72792,   7.07107,
        };
        D = matD.data.bytes;
        STAssertNotNil(matD, nil);
        STAssertEquals(matD.data.length, sizeof(E), nil);
        for (int i = 0; i < sizeof(E) / sizeof(*E); i++) {
            STAssertEqualsWithAccuracy(D[i], E[i], 0.0001, nil);
        }
    }
}

- (void)test_vMAT_pdist2_asymmetric;
{
    vMAT_Array * matD = nil;
    const float * D = NULL;
    const float A[] = { // rand(8, 2)
        0.89037, 0.52071, 0.49071, 0.56954, 0.59684, 0.30356, 0.72347, 0.49049,
        0.73432, 0.08783, 0.70805, 0.02771, 0.38930, 0.08482, 0.55180, 0.57436,
    };
    const float B[] = { // rand(8, 1)
        0.04508, 0.52524, 0.87503, 0.81947, 0.87245, 0.30698, 0.21590, 0.15737,
    };
    vMAT_Array * matA = [vMAT_Array arrayWithSize:vMAT_MakeSize(8, 2)
                                             type:miSINGLE
                                             data:[NSData dataWithBytes:A length:sizeof(A)]];
    vMAT_Array * matB = [vMAT_Array arrayWithSize:vMAT_MakeSize(8, 1)
                                             type:miSINGLE
                                             data:[NSData dataWithBytes:B length:sizeof(B)]];
    matD = vMAT_pdist2(matA, matB);
    {
        const float E[] = {
            1.17015, 1.37500,
        };
        D = matD.data.bytes;
        STAssertNotNil(matD, nil);
        STAssertEquals(matD.data.length, sizeof(E), nil);
        STAssertEqualObjects(vMAT_StringFromSize(matD.size), @"[1 2]", nil);
        for (int i = 0; i < sizeof(E) / sizeof(*E); i++) {
            STAssertEqualsWithAccuracy(D[i], E[i], 0.0001, nil);
        }
    }
    matD = vMAT_pdist2(matB, matA);
    {
        const float E[] = {
            1.17015, 1.37500,
        };
        D = matD.data.bytes;
        STAssertNotNil(matD, nil);
        STAssertEquals(matD.data.length, sizeof(E), nil);
        STAssertEqualObjects(vMAT_StringFromSize(matD.size), @"[2 1]", nil);
        for (int i = 0; i < sizeof(E) / sizeof(*E); i++) {
            STAssertEqualsWithAccuracy(D[i], E[i], 0.0001, nil);
        }
    }
}

- (void)test_vMAT_Size_cmp;
{
    vMAT_Size a, b;
    a = vMAT_MakeSize(0);
    b = vMAT_MakeSize(1);
    STAssertTrue(vMAT_Size_cmp(a, b) < 0, @"Sign of result points to smaller argument");
    a = vMAT_MakeSize(2);
    b = vMAT_MakeSize(2, 1);
    STAssertTrue(vMAT_Size_cmp(a, b) < 0, @"Sizes are not interpolated");
    a = vMAT_MakeSize(3, 1);
    b = vMAT_MakeSize(1, 3);
    STAssertTrue(vMAT_Size_cmp(a, b) < 0, @"Higher dimensions are more significant");
    a = vMAT_MakeSize(3, 9);
    b = vMAT_MakeSize(3, 9);
    STAssertTrue(vMAT_Size_cmp(a, b) == 0, @"Equal sizes return zero");
    a = vMAT_MakeSize(3, 3);
    b = vMAT_MakeSize(3, 2);
    STAssertTrue(vMAT_Size_cmp(a, b) > 0, @"All signs are go");
}

- (void)test_vMAT_Size_dot;
{
    // Let's try some index transposition computations for a 4x3x2 array.
    vMAT_Size ixmulC = { 1, 1 * 4, 1 * 4 * 3, 0 };
    vMAT_Size ixmulM = { 1 * 3, 1, 1 * 4 * 3, 0 };
    int C[4 * 3 * 2] = { -1 };
    int M[3 * 4 * 2] = { -1 };
    int count = 0;
    for (int p = 0; p < 1; p++) {
        for (int o = 0; o < 2; o++) {
            for (int n = 0; n < 3; n++) {
                for (int m = 0; m < 4; m++) {
                    __v4si ixvecD = { m, n, o, p };
                    long idxC = vMAT_Size_dot(ixmulC, ixvecD);
                    long idxM = vMAT_Size_dot(ixmulM, ixvecD);
                    C[idxC] = count;
                    M[idxM] = count;
                    ++count;
                }
            }
        }
    }
    
    long dotA = vMAT_Size_dot(vMAT_MakeSize(INT_MAX / 3, 1, 3), vMAT_MakeSize(3, 1, 1));
    STAssertEquals(dotA, (long)INT_MAX + 3, @"Result truncated?");
}

@end
