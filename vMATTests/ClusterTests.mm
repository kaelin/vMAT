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

- (void)test_vMAT_linkage;
{
    NSURL * URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"cluster-normaldata-10x3-13"
                                                           withExtension:@"mat"];
    NSInputStream * stream = [NSInputStream inputStreamWithURL:URL];
    [stream open];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block vMAT_Array * matX = nil;
    __block vMAT_Array * matYv = nil;
    __block vMAT_Array * matZv = nil;
    vMAT_load(stream, @[@"X", @"Y", @"Zv"], ^(NSDictionary * workspace, NSError * error) {
        // NSLog(@"%@", workspace);
        matX =  [workspace variable:@"X"].matrix.mtrans;  // Transposed for vMAT_pdist
        matYv = [workspace variable:@"Y"].matrix.mtrans;  // Transposed for vMAT_pdist
        matZv = [workspace variable:@"Zv"].matrix.mtrans; // Transposed for vMAT_linkage
        STAssertNotNil(matX, nil);
        STAssertNotNil(matYv, nil);
        STAssertNotNil(matZv, nil);
        [stream close];
        dispatch_semaphore_signal(semaphore);
    });
    long timedout = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW,
                                                                     1 * NSEC_PER_SEC));
    STAssertFalse(timedout, @"Timed out waiting for completion (1s)");
    // NSLog(@"X  = %@", matX);
    // NSLog(@"Yv = %@", matYv);
    // NSLog(@"Zv = %@", matZv.dump);
    vMAT_Array * matY = vMAT_pdist(matX);
    NSLog(@"Y  = %@", matY);
    STAssertTrue([matY isEqual:matYv epsilon:0.0001], @"vMAT_pdist results don't match expected output");
    vMAT_Array * matZ = vMAT_linkage(matY);
    NSLog(@"Z  = %@", matZ.dump);
    STAssertTrue([matZ isEqual:matZv epsilon:0.0001], @"vMAT_linkage results don't match expected output");
}

@end
