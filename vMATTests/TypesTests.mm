//
//  TypesTests.m
//  vMAT
//
//  Created by Kaelin Colclasure on 4/7/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "TypesTests.h"

#import "vMAT.h"

#import <iostream>


namespace {
    
    using namespace Eigen;
    using namespace vMAT;
    
}

@implementation TypesTests

- (void)test_vMAT_manifesto;
{
    const float iniM[] = {
         2, 11,  7, 14,
         3, 10,  6, 15,
        13,  8, 12,  1,
    };
    vMAT_Array * matM = [vMAT_Array arrayWithSize:vMAT_MakeSize(4, 3)
                                             type:miSINGLE
                                             data:[NSData dataWithBytes:iniM length:sizeof(iniM)]];
    NSLog(@"%@", matM.dump);
    Mat<float> M = matM;
    Matrix<float, 4, 3> X = M.array() * M.array();
    vMAT_Array * matX = vMAT_cast(X);
    NSLog(@"%@", matX.dump);
    vMAT_Array * matXv = [vMAT_Array arrayWithSize:vMAT_MakeSize(4, 3)
                                              type:miSINGLE];
    Mat<float> Xv = matXv;
    Xv <<
      4,   9, 169,
    121, 100,  64,
     49,  36, 144,
    196, 225,   1;
    STAssertEqualObjects(matX, matXv, @"Ensure equal arrays");
}

- (void)test_Mat;
{
    Mat<double, 3, Dynamic> I = vMAT_eye(vMAT_MakeSize(3, 5), nil);
    std::cout << I << std::endl;
}

- (void)test_Mat_indexing;
{
    Mat<double> D = vMAT_zeros((vMAT_Size){ 10, 3, 2 }, @[ @"double" ]);
    {
        vMAT_idx_t seq = 1;
        for (vMAT_idx_t p = 0; p < 2; p++) {
            for (vMAT_idx_t n = 0; n < 3; n++) {
                for (vMAT_idx_t m = 0; m < 10; m++) {
                    D[{m,n,p}] = seq++;
                }
            }
        }
        float b = D[{2, 2}];
        float c = D[22];
        STAssertTrue(b == c && c == 23.0, nil);
        float d = D[{0, 0, 1}];
        float e = D[30];
        STAssertTrue(d == e && e == 31.0, nil);
        vMAT_Array * matD = D;
        NSLog(@"%@", matD.dump);
        STAssertNotNil(matD, nil);
    }
    vMAT_Array * matS = vMAT_zeros((vMAT_Size){ 10, 3, 2 }, @[ @"single" ]);
    Mat<float> S(matS);
    {
        vMAT_idx_t seq = 1;
        for (vMAT_idx_t p = 0; p < 2; p++) {
            for (vMAT_idx_t n = 0; n < 3; n++) {
                for (vMAT_idx_t m = 0; m < 10; m++) {
                    S[{m,n,p}] = seq++;
                }
            }
        }
        float b = S[{2, 2}];
        float c = S[22];
        STAssertTrue(b == c && c == 23.0, nil);
        float d = S[{0, 0, 1}];
        float e = S[30];
        STAssertTrue(d == e && e == 31.0, nil);
        NSLog(@"%@", matS.dump);
    }
}

@end
