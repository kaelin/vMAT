//
//  vMAT_StreamDelegate.h
//  vMAT
//
//  Created by Kaelin Colclasure on 3/25/13.
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


#define vMAT_LIMIT_CONCURRENT_STREAMS (4)

@interface vMAT_StreamDelegate : NSObject <NSStreamDelegate> {
    long lenD;
    uint8_t * D;
    long idxD;
}

@property (readonly, retain) NSMutableData * bufferData;
@property (copy) void (^ completionBlock)(vDSP_Length outputLength, NSError * error);
@property (copy) void (^ outputBlock)(vMAT_Array * matrix, NSError * error);
@property (readonly, retain) NSStream * stream;
@property (readonly, retain) vMAT_Array * matrix;
@property (readonly, retain) NSDictionary * options;
@property (readonly) BOOL isGrowingMatrix;


- (id)initWithStream:(NSStream *)stream
                rows:(vDSP_Length)rows
                cols:(vDSP_Length)cols
             options:(NSDictionary *)options;

- (id)initWithStream:(NSStream *)stream
              matrix:(vMAT_Array *)matrix
             options:(NSDictionary *)options;

- (void)startReading;
- (void)startWriting;

@end
