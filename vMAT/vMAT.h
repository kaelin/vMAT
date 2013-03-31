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


/*! Make a float identity matrix.
 
 @param rows Number of rows.
 @param cols Number of columns.
 @param outputBlock A block for receiving the output identity matrix.
 
 */
extern void
vMAT_eye(vDSP_Length rows,
         vDSP_Length cols,
         void (^outputBlock)(float output[],
                             vDSP_Length outputLength,
                             bool * keepOutput));

/*! Read a float matrix asynchronously from a stream.
 
 @param stream An `NSInputStream` (must already be opened).
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

/* Write a float matrix asynchronously to a stream.
 
 @param stream An `NSOutputStream` (must already be opened).
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

/*! Compute a hierarchical cluster tree from a float distance matrix.
 
 @param pdistv A (square, for now) distance matrix.
 @param pdistvLength The number of elements in `pdistv`.
 @param outputBlock A block for receiving the output hierarchical cluster tree matrix.
 
 */
extern void
vMAT_linkage(const float pdistv[],
             vDSP_Length pdistvLength,
             void (^outputBlock)(float output[],
                                 vDSP_Length outputLength,
                                 bool * keepOutput));

/*! Load variables asynchronously from a MAT (v5) file into a workspace dictionary.

 @param stream An `NSInputStream` (must already be opened).
 @param variableNames An `NSArray` containing a list of the workspace variable names to be loaded.
 @param asyncCompletionBlock A block to be called asynchronously when the read operation completes.
 
 */
extern void
vMAT_load(NSInputStream * stream,
          NSArray * variableNames,
          void (^asyncCompletionBlock)(NSDictionary * workspace,
                                       NSError * error));

/*! Compute the pairwise distances between the samples in a float matrix.
 
 @param sample A 2D matrix with variables in columns and samples in rows.
 @param rows The number of samples.
 @param cols The number of variables in each sample.
 @param outputBlock A block for receiving the output distances vector.
 
 */
extern void
vMAT_pdist(const float sample[],
           vDSP_Length rows,
           vDSP_Length cols,
           void (^outputBlock)(float output[],
                               vDSP_Length outputLength,
                               bool * keepOutput));

/*! Compute the pairwise distances between two sets of float samples.
 
 @param sampleA A 2D matrix `A` with variables in columns and samples in rows.
 @param rowsA The number of samples in `A`.
 @param sampleB A 2D matrix `B` with variables in columns and samples in rows.
 @param rowsB The number of samples in `B`.
 @param cols The number of variables in each sample.
 @param outputBlock A block for receiving the output distances vector.
 
 */
extern void
vMAT_pdist2(const float sampleA[],
            vDSP_Length rowsA,
            const float sampleB[],
            vDSP_Length rowsB,
            vDSP_Length cols,
            void (^outputBlock)(float output[],
                                vDSP_Length outputLength,
                                bool * keepOutput));

extern void
vMAT_swapbytes(void * vector32,
               vDSP_Length vectorLength);

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

typedef enum {
    miINT8       = 1,
    miUINT8      = 2,
    miINT16      = 3,
    miUINT16     = 4,
    miINT32      = 5,
    miUINT32     = 6,
    miSINGLE     = 7,
    miDOUBLE     = 9,
    miINT64      = 12,
    miUINT64     = 13,
    miMATRIX     = 14,
    miCOMPRESSED = 15,
    miUTF8       = 16,
    miUTF16      = 17,
    miUTF32      = 18,
} vMAT_MIType;

extern NSString *
vMAT_MITypeDescription(vMAT_MIType type);

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
} vMAT_MXClass;

extern NSString *
vMAT_MXClassDescription(vMAT_MXClass class);

#import "vMAT_MATv5ReadOperation.h"
