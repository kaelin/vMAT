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
vMAT_API vMAT_Array *
vMAT_eye(vMAT_Size mxn);

/*!
 @brief Read matrix data asynchronously from a stream.
 @discussion
 This function reads data from an open <code>NSInputStream</code> into a pre-specified <code>vMAT_Array</code> matrix.
 The matrix is populated with elements from the stream in column-major order.
 The type and size of the matrix determine how much data will be read from the stream, and how it will be interpreted.
 It is possible to read into a matrix with only the m dimension of the size specified (e.g. n and all subsequent
 dimensions equal to zeros). In this case, the matrix data will be read one column at a time, until the end of the
 input stream is encountered (or until an error occurs).
 
 The caller-provided <code>asyncOutputBlock</code> is invoked either when the matrix had been fully read, or when an
 error occurs. As the block name implies, input from the stream will be handled asynchronously, and the block will be
 invoked from a global GCD work queue when the operation is finished.
 
 The stream passed to this function should be closed only after the completion block has been invoked. Closing it
 prematurely will result in undefined behavior.
 @param stream An <code>NSInputStream</code> (must already be opened).
 @param matrix A <code>vMAT_Array</code> specifying the type and dimensions of the input matrix data.
 @param options A dictionary of options (not presently implemented; must be nil).
 @param asyncOutputBlock A block to be called asynchronously once the data is available.
 */
vMAT_API void
vMAT_fread(NSInputStream * stream,
           vMAT_Array * matrix,
           NSDictionary * options,
           void (^asyncOutputBlock)(vMAT_Array * matrix,
                                    NSError * error));

/*
 @brief Write matrix data asynchronously to a stream.
 @discussion
 This functions writes the matrix data from a <code>vMAT_Array</code> to an open <code>NSOutputStream</code>.
 The elements of the matrix are written to the stream in column-major order.
 The type and size of the matrix determine how much data will be written to the stream.
 
 The called-provided <code>asyncCompletionBlock</code> is invoked either when the matrix data has been fully written,
 or when an error occurs. As the block name implies, output to the stream will be handled asynchronously, and the
 block will be invoked from a global GCD work queue when the operation is finished.
 
 The stream passed to this function should be closed only after the completion block has been invoked. Closing it
 prematurely will result in undefined behavior.
 @param stream An <code>NSOutputStream</code> (must already be opened).
 @param matrix A <code>vMAT_Array</code> containing the matrix data to be output.
 @param options A dictionary of options (not presently implemented; must be nil).
 @param asyncCompletionBlock A block to be called asynchronously once the data is written.
 */
vMAT_API void
vMAT_fwrite(NSOutputStream * stream,
            vMAT_Array * matrix,
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
 This functions reads saved workspace variables from the MAT (v5) file format. The MAT elements are read sequentially
 from the open <code>NSInputStream</code> provided by the caller. Only the workspace variables designated in the
 <code>variableNames</code> array are loaded; other variables are skipped without being loaded into memory.
 
 At present, only a subset of the MAT (v5) file specification is supported. Of particular note, <code>miCOMPRESSED</code>
 elements are *not* yet handled; consequently, it is usually necessary to specify the <code>'-v6'</code> option
 when saving variables from a MATLAB session to file intended to be read by <code>vMAT_load</code>.
 
 The called-provided <code>asyncCompletionBlock</code> is invoked either when the MAT file has been fully read,
 or when an error occurs. As the block name implies, input from the stream will be handled asynchronously, and the
 block will be invoked from a global GCD work queue when the operation is finished.
 
 The stream passed to this function should be closed only after the completion block has been invoked. Closing it
 prematurely will result in undefined behavior.
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

vMAT_API vMAT_Array *
vMAT_double(vMAT_Array * matrix);

vMAT_API vMAT_Array *
vMAT_single(vMAT_Array * matrix);

#endif // vMAT_H
