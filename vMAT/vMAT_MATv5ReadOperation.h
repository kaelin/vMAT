//
//  vMAT_MATv5ReadOperation.h
//  vMAT
//
//  Created by Kaelin Colclasure on 3/27/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT.h"


@class vMAT_MATv5ReadOperation;

@protocol vMAT_MATv5ReadOperationDelegate <NSObject>
@required

- (void)operation:(vMAT_MATv5ReadOperation *)operation
      handleError:(NSError *)error;

@optional

- (void)operation:(vMAT_MATv5ReadOperation *)operation
     handleHeader:(NSData *)descriptiveData
          version:(int16_t)version
        byteOrder:(int32_t)byteOrder;

- (void)operation:(vMAT_MATv5ReadOperation *)operation
    handleElement:(vMAT_MIType)type
             data:(NSData *)data;

- (void)operation:(vMAT_MATv5ReadOperation *)operation
    handleElement:(vMAT_MIType)type
           length:(uint32_t)byteLength
           stream:(NSInputStream *)stream;

@end

@interface vMAT_MATv5ReadOperation : NSOperation

@property (weak) id<vMAT_MATv5ReadOperationDelegate> delegate;
@property (assign, nonatomic) BOOL isFinished;
@property (readonly, retain) NSInputStream * stream;
@property (readonly) int32_t byteOrder;
@property (readonly) BOOL swapBytes;
@property (readonly) BOOL hasSubsystemOffset;
@property (readonly) int64_t subsystemOffset;

- (id)initWithInputStream:(NSInputStream *)stream;

@end
