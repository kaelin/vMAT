//
//  vMAT_Array+BinaryOps.mm
//  vMAT
//
//  Created by Kaelin Colclasure on 4/6/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_PrivateArray.h"

#import <algorithm>
#import <cmath>
#import <vector>


@implementation vMAT_Array (BinaryOps)

- (BOOL)isEqual:(vMAT_Array *)array
        epsilon:(double)epsilon;
{
    return [self isEqual:array]; // Ignore epsilon for integral types
}

@end

namespace {
    
    using namespace std;
    using namespace vMAT;
    
    template <typename T>
    struct equal_w_epsilon {
        double epsilon;
        equal_w_epsilon(double epsilon) : epsilon(epsilon) { }
        bool operator()(T a, T b) const { return std::abs(a - b) < epsilon; }
    };
    
    template <typename T>
    BOOL
    isEqualEpsilon(T * A, vMAT_Size sizeA, T * B, vMAT_Size sizeB, double epsilon)
    {
        if (sizeA[0] == sizeB[0] &&
            sizeA[1] == sizeB[1] &&
            sizeA[2] == sizeB[2] &&
            sizeA[3] == sizeB[3]) {
            vector<T> vecA(A, A + vMAT_Size_prod(sizeA));
            vector<T> vecB(B, B + vMAT_Size_prod(sizeB));
            return equal(vecA.begin(), vecA.end(), vecB.begin(), equal_w_epsilon<T>(epsilon));
        }
        return NO;
    }
    
}

@implementation vMAT_DoubleArray (BinaryOps)

- (BOOL)isEqual:(vMAT_Array *)array
        epsilon:(double)epsilon;
{
    if (self.type != array.type) return NO;
    else return isEqualEpsilon((float *)self.data.bytes, self.size, (float *)array.data.bytes, array.size, epsilon);
}

@end

@implementation vMAT_SingleArray (BinaryOps)

- (BOOL)isEqual:(vMAT_Array *)array
        epsilon:(double)epsilon;
{
    if (self.type != array.type) return NO;
    else return isEqualEpsilon((float *)self.data.bytes, self.size, (float *)array.data.bytes, array.size, epsilon);
}

@end
