//
//  vMAT_MATv5Variable.h
//  vMAT
//
//  Created by Kaelin Colclasure on 3/31/13.
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
@class vMAT_MATv5NumericArray;

@interface vMAT_MATv5Variable : NSObject {
@protected
    BOOL _isComplex;
    BOOL _isGlobal;
    BOOL _isLogical;
    vMAT_MXClass _mxClass;
    vMAT_Size _size;
    NSString * _name;
}

@property (readonly) BOOL isComplex;
@property (readonly) BOOL isGlobal;
@property (readonly) BOOL isLogical;
@property (readonly) vMAT_MXClass mxClass;
@property (readonly) vMAT_Size size;
@property (readonly, retain) NSString * name;

+ (vMAT_MATv5Variable *)variableWithMXClass:(vMAT_MXClass)mxClass
                                 arrayFlags:(uint32_t)flags
                                 dimensions:(vMAT_Size)size
                                       name:(NSString *)name;

- (void)loadFromOperation:(vMAT_MATv5ReadOperation *)operation;

- (vMAT_MATv5NumericArray *)toNumericArray;

@end

@interface vMAT_MATv5NumericArray : vMAT_MATv5Variable

@property (readonly, retain) NSMutableData * arrayData;

- (void)loadFromOperation:(vMAT_MATv5ReadOperation *)operation
              withMXClass:(vMAT_MXClass)mxClass;

@end
