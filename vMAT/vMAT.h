//
//  vMAT.h
//  vMAT
//
//  Created by Kaelin Colclasure on 3/24/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import <Accelerate/Accelerate.h>


extern void
vMAT_eye(vDSP_Length rows,
         vDSP_Length cols,
         void (^outputBlock)(float output[],
                             vDSP_Length outputLength,
                             bool * keepOutput));

/*! Compute a hierarchical cluster tree from a distance matrix.
 
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

/*! Compute the pairwise distances between the samples in a matrix.
 
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

/*! Compute the pairwise distances between two sets of samples.
 
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
