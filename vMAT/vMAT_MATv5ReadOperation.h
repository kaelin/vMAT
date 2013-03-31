//
//  vMAT_MATv5ReadOperation.h
//  vMAT
//
//  Created by Kaelin Colclasure on 3/27/13.
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

#import "vMAT.h"


@class vMAT_MATv5ReadOperation;

@class vMAT_MATv5Variable;

@protocol vMAT_MATv5ReadOperationDelegate <NSObject>
@required

- (void)operation:(vMAT_MATv5ReadOperation *)operation
   handleVariable:(vMAT_MATv5Variable *)variable;

- (void)operation:(vMAT_MATv5ReadOperation *)operation
      handleError:(NSError *)error;

@optional

- (void)operation:(vMAT_MATv5ReadOperation *)operation
     handleHeader:(NSData *)descriptiveData
          version:(int16_t)version
        byteOrder:(int32_t)byteOrder;

- (void)operation:(vMAT_MATv5ReadOperation *)operation
    handleElement:(vMAT_MIType)type
           length:(uint32_t)byteLength
           stream:(NSInputStream *)stream;

@end

@interface vMAT_MATv5ReadOperation : NSOperation

@property (weak, nonatomic) id<vMAT_MATv5ReadOperationDelegate> delegate;
@property (assign, nonatomic) BOOL isFinished;
@property (readonly, retain) NSInputStream * stream;
@property (readonly) int32_t byteOrder;
@property (readonly) BOOL swapBytes;
@property (readonly) BOOL hasSubsystemOffset;
@property (readonly) int64_t subsystemOffset;
@property (readonly, weak) id elementHandler;
@property (readonly) long elementRemainingLength;
@property (readonly, retain) vMAT_MATv5Variable * variable;

- (id)initWithInputStream:(NSInputStream *)stream;

- (void)readComplete:(void *)buffer
              length:(long)length;
- (void)readElement;

@end

@interface vMAT_MATv5ReadOperationDelegate : NSObject <vMAT_MATv5ReadOperationDelegate>

@property (readonly) vMAT_MATv5ReadOperation * operation;
@property (copy) void (^ completionBlock)(NSDictionary * workspace, NSError * error);

- (id)initWithReadOperation:(vMAT_MATv5ReadOperation *)operation;

- (void)start;

@end

@interface vMAT_MATv5Variable : NSObject

@property (readonly, weak) vMAT_MATv5ReadOperation * operation;
@property (assign) BOOL isComplex;
@property (assign) BOOL isGlobal;
@property (assign) BOOL isLogical;
@property (assign) vMAT_MXClass mxClass;
@property (retain) NSArray * dimensions;
@property (retain) NSString * name;

- (id)initWithReadOperation:(vMAT_MATv5ReadOperation *)operation;

@end
