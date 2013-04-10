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

- (void)test_Mat;
{
    Mat<double, 3, Dynamic> I = vMAT_eye(vMAT_MakeSize(3, 5));
    std::cout << I << std::endl;
}

- (void)test_Mat_indexing;
{
    Mat<double> D = vMAT_zeros((vMAT_Size){ 10, 3, 2 }, @[ @"double" ]);
    {
        int seq = 1;
        for (int p = 0; p < 2; p++) {
            for (int n = 0; n < 3; n++) {
                for (int m = 0; m < 10; m++) {
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
        int seq = 1;
        for (int p = 0; p < 2; p++) {
            for (int n = 0; n < 3; n++) {
                for (int m = 0; m < 10; m++) {
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
