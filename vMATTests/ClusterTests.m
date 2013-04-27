//
//  ClusterTests.m
//  vMAT
//
//  Created by Kaelin Colclasure on 4/5/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "ClusterTests.h"

#import "vMAT.h"


@implementation ClusterTests

- (void)test_normaldata_10x3_13;
{
    NSURL * URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"cluster-normaldata-10x3-13"
                                                           withExtension:@"mat"];
    NSInputStream * stream = [NSInputStream inputStreamWithURL:URL];
    [stream open];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSDictionary * ws = nil;
    vMAT_load_async(stream, @[@"X", @"Y", @"Zv", @"W", @"Vcpt5", @"Vmax4"], ^(NSDictionary * workspace, NSError * error) {
        NSLog(@"%@", workspace);
        ws = workspace;
        [stream close];
        dispatch_semaphore_signal(semaphore);
    });
    long timedout = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW,
                                                                     1 * NSEC_PER_SEC));
    STAssertFalse(timedout, @"Timed out waiting for completion (1s)");
    vMAT_Array * matX =  [ws variable:@"X"].matrix.mtrans;  // Transposed for vMAT_pdist
    vMAT_Array * matYv = [ws variable:@"Y"].matrix.mtrans;  // Transposed for vMAT_pdist
    vMAT_Array * matZv = [ws variable:@"Zv"].matrix.mtrans; // Transposed for vMAT_linkage
    vMAT_Array * matWv = [ws variable:@"W"].matrix.mtrans;  // Transposed for vMAT_inconsistent
    STAssertNotNil(matX, nil);
    STAssertNotNil(matYv, nil);
    STAssertNotNil(matZv, nil);
    STAssertNotNil(matWv, nil);
    // NSLog(@"X  = %@", matX);
    vMAT_Array * matY = vMAT_pdist(matX);
    // NSLog(@"Yv = %@", matYv.dump);
    // NSLog(@"Y  = %@", matY.dump);
    STAssertTrue([matY isEqual:matYv epsilon:0.0001], @"vMAT_pdist results don't match expected output");
    vMAT_Array * matZ = vMAT_linkage(matY);
    // NSLog(@"Zv = %@", matZv.dump);
    NSLog(@"Z  = %@", matZ.dump);
    STAssertTrue([matZ isEqual:matZv epsilon:0.0001], @"vMAT_linkage results don't match expected output");
    vMAT_Array * matW = vMAT_inconsistent(matZ, 0);
    // NSLog(@"Wv = %@", matWv.dump);
    NSLog(@"W  = %@", matW.dump);
    STAssertTrue([matW isEqual:matWv epsilon:0.005], @"vMAT_inconsistent results don't match expected output");
    vMAT_Array * matV = nil;
    matV = vMAT_cluster(matZ, @[ @"cutoff:", @.5, @"criterion:", @"inconsistent" ]);
    NSLog(@"V  = %@", matV.dump);
    matV = vMAT_cluster(matZ, @[ @"maxclust:", @4 ]);
    NSLog(@"V  = %@", matV.dump);
}

@end
