//
//  vMAT_Array.h
//  vMAT
//
//  Created by Kaelin Colclasure on 4/3/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions
//  are met:
//
//  • Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//  • Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
//  COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
//  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
//  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//

#import "vMAT_Types.h"


@interface vMAT_Array : NSObject

@property (readonly, retain) NSMutableData * data;
@property (readonly) vMAT_Size size;
@property (readonly) vMAT_MIType type;

+ (vMAT_Array *)arrayWithSize:(vMAT_Size)size
                         type:(vMAT_MIType)type;

+ (vMAT_Array *)arrayWithSize:(vMAT_Size)size
                         type:(vMAT_MIType)type
                         data:(NSData *)data;

- (id)initWithSize:(vMAT_Size)size
              type:(vMAT_MIType)type
              data:(NSMutableData *)data;

- (id)initWithSize:(vMAT_Size)size
              type:(vMAT_MIType)type;

- (void)reshape:(vMAT_Size)size;

@end

@interface vMAT_Array (BinaryOps)

- (BOOL)isEqual:(vMAT_Array *)array
        epsilon:(double)epsilon;

@end

@interface vMAT_Array (CopyFrom)

+ (SEL)copyCmdForType:(vMAT_MIType)typeA
             fromType:(vMAT_MIType)typeB;

- (void)copyFrom:(vMAT_Array *)matrix;

@end

@interface vMAT_Array (UnaryOps)

- (NSString *)dump;

- (vMAT_Array *)mtrans;

@end

#ifdef __cplusplus

#import <Eigen/Core>

namespace vMAT {
    
    // Why yes, this *does* resemble a burst of line noise!
    template <typename EigenObjectType, typename StrideType = Eigen::Stride<0, 0>>
    struct Map : Eigen::Map<EigenObjectType, Eigen::Aligned, StrideType> {
        typedef typename Eigen::Map<EigenObjectType, Eigen::Aligned, StrideType>::Scalar Scalar;
        
        vMAT_Array * matA;
        
        Map(vMAT_Array * matrix)
        : Eigen::Map<EigenObjectType, Eigen::Aligned, StrideType>
        ((Scalar *)matrix.data.mutableBytes, matrix.size[0], matrix.size[1]), matA(matrix) { }
        
        Map(EigenObjectType matrix)
        : Eigen::Map<EigenObjectType, Eigen::Aligned, StrideType>
        (NULL, matrix.rows(), matrix.cols())
        {
            typename EigenObjectType::Scalar exemplar = 0;
            matA = [vMAT_Array arrayWithSize:vMAT_MakeSize((int)matrix.rows(), (int)matrix.cols())
                                        type:MIType(exemplar)
                                        data:[NSMutableData dataWithBytes:matrix.data()
                                                                   length:matrix.size() * sizeof(exemplar)]];
            new (this) Eigen::Map<EigenObjectType, Eigen::Aligned, StrideType>
            ((typename EigenObjectType::Scalar *)matA.data.mutableBytes, matrix.rows(), matrix.cols());
        }

        inline operator vMAT_Array * () const { return matA; };
        
        inline const vMAT_Size size() const { return matA.size; }
        inline const int size(int dim) const { return matA.size[dim]; }
    };
    
    template <typename Scalar, int M = Eigen::Dynamic, int N = Eigen::Dynamic, int Options = 0>
    struct Mat : Map<Eigen::Matrix<Scalar, M, N, Options>> {
        Scalar * A;
        vDSP_Length lenA;
        vMAT_Size multiA;
        
        Mat(vMAT_Array * matrix)
        : Map<Eigen::Matrix<Scalar, M, N, Options>>(matrix) {
            A = static_cast<Scalar *>(matrix.data.mutableBytes);
            lenA = matrix.data.length / sizeof(*A);
            multiA = vMAT_MakeSize(1,
                                   matrix.size[0],
                                   matrix.size[0] * matrix.size[1],
                                   matrix.size[0] * matrix.size[1] * matrix.size[2]);
        }

        inline Scalar & operator[](vDSP_Length idx) { return A[idx]; } // A[idx]
        
        Scalar & operator[](vMAT_Index idxs)                           // A[{m,n,...}]
        {
            long idxA = vMAT_Index_dot(multiA, idxs);
            NSCParameterAssert(idxA >= 0 && idxA < lenA);
            return A[idxA];
        }
    };
    
    template <typename EigenObjectType>
    vMAT_Array * vMAT_cast(EigenObjectType matrix)
    {
        return Map<EigenObjectType>(matrix).matA;
    }
    
}

#endif
