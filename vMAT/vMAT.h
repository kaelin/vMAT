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

#ifndef vMAT_H
#define vMAT_H

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

#import "vMAT_Types.h"

#import "vMAT_Array.h"
#import "vMAT_MATv5ReadOperation.h"
#import "vMAT_MATv5Variable.h"


/*!
 @brief Make an identity matrix.
 @discussion
 This function returns an identity matrix of the specified size.
 @param mxn Size specification (2D); if only the first dimension is provided, defaults to a square matrix.
 */
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

extern vMAT_Array *
vMAT_single(vMAT_Array * matrix);

extern void
vMAT_swapbytes(void * vector32,
               vDSP_Length vectorLength);

#endif // vMAT_H
