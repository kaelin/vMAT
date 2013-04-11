//
//  vMAT_Array+UnaryOps.mm
//  vMAT
//
//  Created by Kaelin Colclasure on 4/5/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_PrivateArray.h"

#import <algorithm>
#import <sstream>
#import <vector>


@implementation vMAT_Array (UnaryOps)

- (NSString *)dump;
{
    return [self description];
}

- (vMAT_Array *)mtrans;
{
    return nil; // Subclass responsibility
}

@end

namespace {
    
    using namespace Eigen;
    using namespace std;
    using namespace vMAT;
    
    template <typename T>
    NSString *
    dump(NSString * prefix, T * A, vMAT_Size sizeA)
    {
        NSMutableString * dump = [NSMutableString stringWithString:prefix];
        [dump appendString:@" = \n"];
        Eigen::Map<Matrix<T, Dynamic, Dynamic>> DATA(A, sizeA[0], sizeA[1]);
        stringstream out;
        out << DATA << endl;
        [dump appendFormat:@"%s", out.str().c_str()];
        return dump;
    }
    
}

@implementation vMAT_DoubleArray (UnaryOps)

- (NSString *)dump;
{
    return dump([self description], (double *)self.data.bytes, self.size);
}

- (vMAT_Array *)mtrans;
{
    vMAT_Array * array = [vMAT_Array arrayWithSize:vMAT_MakeSize(self.size[1], self.size[0]) type:self.type];
    double * A = (double *)self.data.mutableBytes;
    double * C = (double *)array.data.mutableBytes;
    vDSP_mtransD(A, 1, C, 1, self.size[0], self.size[1]);
    return array;
}

@end

@implementation vMAT_SingleArray (UnaryOps)

- (NSString *)dump;
{
    return dump([self description], (float *)self.data.bytes, self.size);
}

- (vMAT_Array *)mtrans;
{
    vMAT_Array * array = [vMAT_Array arrayWithSize:vMAT_MakeSize(self.size[1], self.size[0]) type:self.type];
    float * A = (float *)self.data.mutableBytes;
    float * C = (float *)array.data.mutableBytes;
    vDSP_mtrans(A, 1, C, 1, self.size[0], self.size[1]);
    return array;
}

@end

@implementation vMAT_Int8Array (UnaryOps)

- (NSString *)dump;
{
    return dump([self description], (int8_t *)self.data.bytes, self.size);
}

- (vMAT_Array *)mtrans;
{
    Mat<int8_t, Dynamic, Dynamic> A = self;
    Matrix<int8_t, Dynamic, Dynamic> B = A.transpose();
    return vMAT_cast(B);
}

@end

@implementation vMAT_Int32Array (UnaryOps)

- (NSString *)dump;
{
    return dump([self description], (int32_t *)self.data.bytes, self.size);
}

- (vMAT_Array *)mtrans;
{
    vMAT_Array * array = [vMAT_Array arrayWithSize:vMAT_MakeSize(self.size[1], self.size[0]) type:self.type];
    float * A = (float *)self.data.mutableBytes;
    float * C = (float *)array.data.mutableBytes;
    vDSP_mtrans(A, 1, C, 1, self.size[0], self.size[1]);
    return array;
}

@end
