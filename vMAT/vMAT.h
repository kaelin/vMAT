//
//  vMAT.h
//  vMAT
//
//  Created by Kaelin Colclasure on 3/24/13.
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

#import <Accelerate/Accelerate.h>
#import <Foundation/Foundation.h>

/*!
 @header vMAT Library
 @encoding utf-8
 @copyright 2013 Kaelin Colclasure. All rights reserved.
 @updated 2013-04-01
 @abstract The vMAT library implements a grab-bag of mathematical functions inspired by MATLAB™.
 @discussion
 
 This library is being developed as part of a facial recognition project. As such, it
 contains a small (but growing) set of matrix functions and related utilities which that project happens to use. In its present
 state, there's probably not enough here to be of much interest to anyone outside of that effort, except perhaps as an
 example of how MATLAB™ code can be expressed in vectorized Objective-C.
 */

/*!
 @brief Type for array size (dimensions).
 */
typedef __v4si vMAT_Size;

/*!
 @brief This macro reflects the maximum number of dimensions that can be expressed using a <code>vMAT_Size</code>.
 @discussion
 This is effectively the limit of how many dimensions vMAT can handle. Four seems pretty reasonable,
 but if more were really needed it would be possible to increase this by using a wider vector type.
 */
#define vMAT_MAXDIMS (4)

/*!
 @brief Convenience macro for creating a <code>vMAT_Size</code>.
 */
#define vMAT_MakeSize(dims...) ((vMAT_Size){ dims })

extern NSString *
vMAT_StringFromSize(vMAT_Size size);

typedef enum {
    miINT8        = 1,
    miUINT8       = 2,
    miINT16       = 3,
    miUINT16      = 4,
    miINT32       = 5,
    miUINT32      = 6,
    miSINGLE      = 7,
    miDOUBLE      = 9,
    miINT64       = 12,
    miUINT64      = 13,
    miMATRIX      = 14,
    miCOMPRESSED  = 15,
    miUTF8        = 16,
    miUTF16       = 17,
    miUTF32       = 18,
    miRANGE_LIMIT
} vMAT_MIType;

extern NSString *
vMAT_MITypeDescription(vMAT_MIType type);

extern size_t
vMAT_MITypeSizeof(vMAT_MIType type);

typedef enum {
    mxCELL_CLASS   = 1,
    mxSTRUCT_CLASS = 2,
    mxOBJECT_CLASS = 3,
    mxCHAR_CLASS   = 4,
    mxSPARSE_CLASS = 5,
    mxDOUBLE_CLASS = 6,
    mxSINGLE_CLASS = 7,
    mxINT8_CLASS   = 8,
    mxUINT8_CLASS  = 9,
    mxINT16_CLASS  = 10,
    mxUINT16_CLASS = 11,
    mxINT32_CLASS  = 12,
    mxUINT32_CLASS = 13,
    mxINT64_CLASS  = 14,
    mxUINT64_CLASS = 15,
    mxRANGE_LIMIT
} vMAT_MXClass;

extern NSString *
vMAT_MXClassDescription(vMAT_MXClass class);

@interface vMAT_Array : NSObject

@property (readonly, retain) NSMutableData * data;
@property (readonly) vMAT_Size size;
@property (readonly) vMAT_MIType type;

+ (vMAT_Array *)arrayWithSize:(vMAT_Size)size
                         type:(vMAT_MIType)type;

- (id)initWithSize:(vMAT_Size)size
              type:(vMAT_MIType)type;

@end

/*!
 @brief Make a float identity matrix.
 @discussion
 This function outputs a float identity matrix of the specified size to the caller-provided output block.
 @param mxn Size specification (2D); if only the first dimension is provided, defaults to a square matrix.
 @param outputBlock A block for receiving the output identity matrix.
 */
extern void
vMAT_eye_(vMAT_Size mxn,
         void (^outputBlock)(float output[],
                             vDSP_Length outputLength,
                             bool * keepOutput));

extern vMAT_Array *
vMAT_eye(vMAT_Size mxn);

/*!
 @brief Read a float matrix asynchronously from a stream.
 @discussion
 TBD.
 @param stream An <code>NSInputStream</code> (must already be opened).
 @param rows The number of rows to be read.
 @param cols The number of columns to be read.
 @param options A dictionary of options (not presently implemented; must be nil).
 @param asyncOutputBlock A block to be called asynchronously once the data is available.
 
 */
extern void
vMAT_fread(NSInputStream * stream,
           vDSP_Length rows,
           vDSP_Length cols,
           NSDictionary * options,
           void (^asyncOutputBlock)(float output[],
                                    vDSP_Length outputLength,
                                    NSData * outputData,
                                    NSError * error));

/*
 @brief Write a float matrix asynchronously to a stream.
 @discussion
 TBD.
 @param stream An <code>NSOutputStream</code> (must already be opened).
 @param matrix A float matrix.
 @param rows The number of rows to be written.
 @param cols The number of columns to be written.
 @param options A dictionary of options (not presently implemented; must be nil).
 @param asyncCompletionBlock A block to be called asynchronously once the data is written.
 
 */
void
vMAT_fwrite(NSOutputStream * stream,
            const float matrix[],
            vDSP_Length rows,
            vDSP_Length cols,
            NSDictionary * options,
            void (^asyncCompletionBlock)(vDSP_Length outputLength,
                                         NSError * error));

/*!
 @brief Compute a hierarchical cluster tree from a float distance matrix.
 @discussion
 TBD.
 @param pdistv A (square, for now) distance matrix.
 @param pdistvLength The number of elements in <code>pdistv</code>.
 @param outputBlock A block for receiving the output hierarchical cluster tree matrix.
 
 */
extern void
vMAT_linkage(const float pdistv[],
             vDSP_Length pdistvLength,
             void (^outputBlock)(float output[],
                                 vDSP_Length outputLength,
                                 bool * keepOutput));

/*!
 @brief Load variables asynchronously from a MAT (v5) file into a workspace dictionary.
 @discussion
 TBD.
 @param stream An <code>NSInputStream</code> (must already be opened).
 @param variableNames An <code>NSArray</code> containing a list of the workspace variable names to be loaded.
 @param asyncCompletionBlock A block to be called asynchronously when the read operation completes.
 
 */
extern void
vMAT_load(NSInputStream * stream,
          NSArray * variableNames,
          void (^asyncCompletionBlock)(NSDictionary * workspace,
                                       NSError * error));

/*!
 @brief Compute the pairwise distances between the samples in a float matrix.
 @discussion
 TBD.
 @param sample A 2D matrix with m samples of n variables.
 @param mxn Size of <code>sample</code> matrix.
 @param outputBlock A block for receiving the output distances vector.
 
 */
extern void
vMAT_pdist(const float sample[],
           vMAT_Size mxn,
           void (^outputBlock)(float output[],
                               vDSP_Length outputLength,
                               bool * keepOutput));

/*!
 @brief Compute the pairwise distances between two sets of float samples.
 @discussion
 TBD.
 @param sampleA A 2D matrix with m samples of n variables.
 @param mxnA Size of <code>sampleA</code> matrix.
 @param sampleB A 2D comparison matrix with m samples of n variables.
 @param mxnB Size of <code>sampleB</code> matrix; <code>mxnA[1]</code> must be equal to <code>mxnB[1]</code>.
 @param outputBlock A block for receiving the output distances vector.
 
 */
extern void
vMAT_pdist2(const float sampleA[],
            vMAT_Size mxnA,
            const float sampleB[],
            vMAT_Size mxnB,
            void (^outputBlock)(float output[],
                                vDSP_Length outputLength,
                                bool * keepOutput));

extern void
vMAT_swapbytes(void * vector32,
               vDSP_Length vectorLength);

static inline long
vMAT_Size_dot(vMAT_Size a,
              vMAT_Size b)
{
    __v4si c = a * b;
    return (long)c[0] + c[1] + c[2] + c[3];
}

static inline long
vMAT_Size_prod(vMAT_Size size)
{
    long d2 = size[2] ? : 1;
    long d3 = size[3] ? : 1;
    return (long)size[0] * (long)size[1] * d2 * d3;
}

extern NSString * const vMAT_ErrorDomain;

enum {
    vMAT_ErrorCodeNone                    = 0,
    vMAT_ErrorCodeEndOfStream             = 1,
    vMAT_ErrorCodeOperationCancelled      = 2,
    
    vMAT_ErrorCodeInvalidMATv5Header      = 301,
    vMAT_ErrorCodeInvalidMATv5Tag         = 302,
    vMAT_ErrorCodeInvalidMATv5Element     = 303,
    vMAT_ErrorCodeUnsupportedMATv5Element = 304,
};

#import "vMAT_MATv5ReadOperation.h"
#import "vMAT_MATv5Variable.h"
