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
    inline Eigen::Map<Matrix<T, Dynamic, Dynamic>> toDump(T * A, int rows, int columns)
    {
        Eigen::Map<Matrix<T, Dynamic, Dynamic>> DATA(A, rows, columns);
        return DATA;
    }
    
    inline Matrix<int32_t, Dynamic, Dynamic> toDump(int8_t * A, int rows, int columns)
    {
        Eigen::Map<Matrix<int8_t, Dynamic, Dynamic>> CDATA(A, rows, columns);
        Matrix<int32_t, Dynamic, Dynamic> DATA(CDATA.cast<int32_t>());
        return DATA;
    }
    
    inline Matrix<uint32_t, Dynamic, Dynamic> toDump(uint8_t * A, int rows, int columns)
    {
        Eigen::Map<Matrix<uint8_t, Dynamic, Dynamic>> CDATA(A, rows, columns);
        Matrix<uint32_t, Dynamic, Dynamic> DATA(CDATA.cast<uint32_t>());
        return DATA;
    }
    
    template <typename T>
    NSString *
    dump(NSString * prefix, T * A, vMAT_Size sizeA)
    {
        NSMutableString * dump = [NSMutableString stringWithString:prefix];
        [dump appendString:@" = \n"];
        stringstream out;
        out << toDump(A, sizeA[0], sizeA[1]) << endl;
        [dump appendFormat:@"%s", out.str().c_str()];
        return dump;
    }
#if 0
    template <> // Specialized so elements print as numbers instead of chars
    NSString *
    dump(NSString * prefix, int8_t * A, vMAT_Size sizeA)
    {
        NSMutableString * dump = [NSMutableString stringWithString:prefix];
        [dump appendString:@" = \n"];
        Eigen::Map<Matrix<int8_t, Dynamic, Dynamic>> DATA(A, sizeA[0], sizeA[1]);
        stringstream out;
        out << DATA.cast<int32_t>() << endl;
        [dump appendFormat:@"%s", out.str().c_str()];
        return dump;
    }
    
    template <> // Specialized so elements print as numbers instead of chars
    NSString *
    dump(NSString * prefix, uint8_t * A, vMAT_Size sizeA)
    {
        NSMutableString * dump = [NSMutableString stringWithString:prefix];
        [dump appendString:@" = \n"];
        Eigen::Map<Matrix<uint8_t, Dynamic, Dynamic>> DATA(A, sizeA[0], sizeA[1]);
        stringstream out;
        out << DATA.cast<uint32_t>() << endl;
        [dump appendFormat:@"%s", out.str().c_str()];
        return dump;
    }
#endif
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
