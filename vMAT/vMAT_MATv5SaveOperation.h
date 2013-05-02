//
//  vMAT_MATv5SaveOperation.h
//  vMAT
//
//  Created by Kaelin Colclasure on 5/1/13.
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


@class vMAT_MATv5SaveOperation;

@class vMAT_MATv5Variable;

@protocol vMAT_MATv5SaveOperationDataSource <NSObject>
@required

- (NSUInteger)numberOfVariablesForOperation:(vMAT_MATv5SaveOperation *)operation;

- (vMAT_MATv5Variable *)operation:(vMAT_MATv5SaveOperation *)operation
                  variableAtIndex:(NSUInteger)index;

@optional

- (NSString *)headerDescriptionForOperation:(vMAT_MATv5SaveOperation *)operation;

@end

@protocol vMAT_MATv5SaveOperationDelegate <NSObject>
@required

- (void)operation:(vMAT_MATv5SaveOperation *)operation
      handleError:(NSError *)error;

@optional

- (void)operation:(vMAT_MATv5SaveOperation *)operation
  didSaveVariable:(vMAT_MATv5Variable *)variable;

@end

@interface vMAT_MATv5SaveOperation : NSOperation

@property (weak, nonatomic) id<vMAT_MATv5SaveOperationDataSource> dataSource;
@property (weak, nonatomic) id<vMAT_MATv5SaveOperationDelegate> delegate;
@property (assign, nonatomic) BOOL isFinished;
@property (assign, nonatomic) NSUInteger numberOfVariables;
@property (assign, nonatomic) NSUInteger numberOfVariablesRemaining;
@property (readonly, retain) NSOutputStream * stream;

- (id)initWithOutputStream:(NSOutputStream *)stream;

@end

@interface vMAT_MATv5SaveOperationDelegate : NSObject <vMAT_MATv5SaveOperationDataSource, vMAT_MATv5SaveOperationDelegate>

@property (readonly) vMAT_MATv5SaveOperation * operation;
@property (retain, nonatomic) NSDictionary * workspace;
@property (copy) void (^ completionBlock)(NSDictionary * workspace, NSError * error);

- (id)initWithSaveOperation:(vMAT_MATv5SaveOperation *)operation;

- (void)start;

@end
