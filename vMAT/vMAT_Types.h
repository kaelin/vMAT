//
//  vMAT_Types.h
//  vMAT
//
//  Created by Kaelin Colclasure on 4/3/13.
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


#ifdef __cplusplus
#define vMAT_API extern "C"
#else
#define vMAT_API extern
#endif

@class vMAT_Array;

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

static inline int
vMAT_Size_cmp(vMAT_Size a,
              vMAT_Size b)
{
    if      (a[3] != b[3]) return a[3] - b[3];
    else if (a[2] != b[2]) return a[2] - b[2];
    else if (a[1] != b[1]) return a[1] - b[1];
    else                   return a[0] - b[0];
}

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

vMAT_API NSString *
vMAT_StringFromSize(vMAT_Size size);

typedef enum {
    miNONE        = 0,
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

vMAT_API NSString *
vMAT_MITypeDescription(vMAT_MIType type);

vMAT_API size_t
vMAT_MITypeSizeof(vMAT_MIType type);

typedef enum {
    mxNONE         = 0,
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

vMAT_API NSString *
vMAT_MXClassDescription(vMAT_MXClass mxClass);

vMAT_API vMAT_MIType
vMAT_MXClassType(vMAT_MXClass mxClass);

#ifdef __cplusplus

namespace vMAT {
    
    NSString *
    genericDescription(vMAT_MIType type);
    
    NSString *
    genericDescription(vMAT_MXClass mxClass);
    
    template <typename A>
    SEL
    genericCmd(NSString * format, A a);
    
    template <typename A, typename B>
    SEL
    genericCmd(NSString * format, A a, B b);
    
    extern double   DOUBLE;
    extern float    SINGLE;
    extern int8_t   INT8;
    extern uint8_t  UINT8;
    extern int16_t  INT16;
    extern uint16_t UINT16;
    extern int32_t  INT32;
    extern uint32_t UINT32;
    extern int64_t  INT64;
    extern uint64_t UINT64;

}

#endif
