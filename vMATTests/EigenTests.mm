//
//  EigenTests.m
//  vMAT
//
//  Created by Kaelin Colclasure on 4/16/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "EigenTests.h"

#import "vMAT.h"


namespace {
    
    using namespace Eigen;
    using namespace vMAT;
    
}

@implementation EigenTests

- (void)test_vMAT_pick_logicalM;
{
    vMAT_Array * matA = vMAT_cast(VectorXd::LinSpaced(40, 1.0, 40.0).eval());
    [matA reshape:vMAT_MakeSize(5, 8)];
    Mat<double> A = matA;
    Array<bool, Dynamic, Dynamic> sel = A.unaryExpr([](double elt) { return (int)elt % 3 == 0; }).cast<bool>();
    vMAT_Array * vecN = vMAT_pick(matA, @[ vMAT_cast(sel) ]);
    NSLog(@"%@", vecN.dump);
    vMAT_Array * vecNv = vMAT_cast(VectorXd::LinSpaced(13, 3.0, 39.0).eval());
    STAssertEqualObjects(vecN, vecNv, @"Logical indexing broken");
}

- (void)test_vMAT_pick_scalarMarrayN;
{
    vMAT_Array * matA = vMAT_cast(VectorXd::LinSpaced(40, 1.0, 40.0).eval());
    [matA reshape:vMAT_MakeSize(5, 8)];
    vMAT_Array * vecN = vMAT_pick(matA, @[ @3, @[ @3, @7 ] ]);
    NSLog(@"%@", vecN.dump);
    Mat<double> vecNv = vMAT_zeros(vMAT_MakeSize(1, 2), nil);
    vecNv << 19, 39;
    STAssertEqualObjects(vecN, vecNv, @"Logical indexing broken");
}

- (void)test_vMAT_pick_scalarMlogicalN;
{
    vMAT_Array * matA = vMAT_cast(VectorXd::LinSpaced(40, 1.0, 40.0).eval());
    [matA reshape:vMAT_MakeSize(5, 8)];
    Mat<bool> S = vMAT_zeros(vMAT_MakeSize(8, 1), @[ @"logical" ]);
    S << 0, 0, 0, 1, 0, 0, 0, 1;
    vMAT_Array * vecN = vMAT_pick(matA, @[ @3, S ]);
    NSLog(@"%@", vecN.dump);
    Mat<double> vecNv = vMAT_zeros(vMAT_MakeSize(1, 2), nil);
    vecNv << 19, 39;
    STAssertEqualObjects(vecN, vecNv, @"Logical indexing broken");
}

- (void)test_vMAT_place_arraySource;
{
    vMAT_Array * matA = vMAT_cast(VectorXd::LinSpaced(40, 1.0, 40.0).eval());
    [matA reshape:vMAT_MakeSize(5, 8)];
    Mat<bool> S = vMAT_zeros(vMAT_MakeSize(8, 1), @[ @"logical" ]);
    S << 0, 0, 0, 1, 0, 0, 0, 1;
    vMAT_place(matA, @[ @3, S ], @[ @"10", @13 ]); // Mmm, Cocoa.
    NSLog(@"%@", matA.dump);
    vMAT_Array * vecN = vMAT_pick(matA, @[ @3, S ]);
    NSLog(@"%@", vecN.dump);
    Mat<double> vecNv = vMAT_zeros(vMAT_MakeSize(1, 2), nil);
    vecNv << 10, 13;
    STAssertEqualObjects(vecN, vecNv, @"Array place broken");
}

- (void)test_vMAT_place_matrixSource;
{
    vMAT_Array * matA = vMAT_cast(VectorXd::LinSpaced(40, 1.0, 40.0).eval());
    [matA reshape:vMAT_MakeSize(5, 8)];
    Mat<bool> S = vMAT_zeros(vMAT_MakeSize(8, 1), @[ @"logical" ]);
    S << 0, 0, 0, 1, 0, 0, 0, 1;
    vMAT_place(matA, @[ @3, S ], vMAT_pick(matA, @[ @1, S ]));
    NSLog(@"%@", matA.dump);
    vMAT_Array * vecN = vMAT_pick(matA, @[ @3, S ]);
    NSLog(@"%@", vecN.dump);
    Mat<double> vecNv = vMAT_zeros(vMAT_MakeSize(1, 2), nil);
    vecNv << 17, 37;
    STAssertEqualObjects(vecN, vecNv, @"Matrix place broken");
}

- (void)test_vMAT_place_scalarSource;
{
    vMAT_Array * matA = vMAT_cast(VectorXd::LinSpaced(40, 1.0, 40.0).eval());
    [matA reshape:vMAT_MakeSize(5, 8)];
    Mat<bool> S = vMAT_zeros(vMAT_MakeSize(8, 1), @[ @"logical" ]);
    S << 0, 0, 0, 1, 0, 0, 0, 1;
    vMAT_place(matA, @[ @3, S ], @3.14159);
    NSLog(@"%@", matA.dump);
    vMAT_Array * vecN = vMAT_pick(matA, @[ @3, S ]);
    NSLog(@"%@", vecN.dump);
    Mat<double> vecNv = vMAT_zeros(vMAT_MakeSize(1, 2), nil);
    vecNv << 3.14159, 3.14159;
    STAssertEqualObjects(vecN, vecNv, @"Scalar place broken");
}

- (void)test_vMAT_unique;
{
    Mat<vMAT_idx_t> M = vMAT_zeros(vMAT_MakeSize(10, 3), @[ @"index" ]);
    M <<
    13,  1, 13,
     9,  2,  1,
     8,  3,  2,
     7,  4,  3,
     6,  5,  4,
     5,  6,  5,
     4,  7,  6,
     3,  8,  7,
     2,  9,  8,
     1, 13,  9;
    NSLog(@"M = %@", M.matA.dump);
    NSArray * result = vMAT_unique(M, @[ @"-want:", @"[~,~,_]" ]);
    NSLog(@"%@", result);
    STAssertNotNil(result, @"Returns an array");
    Mat<vMAT_idx_t> ICv = vMAT_zeros(vMAT_MakeSize(10, 3), @[ @"index" ]);
    ICv <<
    9, 0, 9,
    8, 1, 0,
    7, 2, 1,
    6, 3, 2,
    5, 4, 3,
    4, 5, 4,
    3, 6, 5,
    2, 7, 6,
    1, 8, 7,
    0, 9, 8;
    STAssertEqualObjects(result[2], ICv, @"Expected IC?");
}

@end
