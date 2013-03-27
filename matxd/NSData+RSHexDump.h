//
//  NSData+RSHexDump.h
//  RSFoundation
//
//  Created by Daniel Jalkut on 2/14/07.
//  Copyright 2007 Red Sweater Software. All rights reserved.
//
//	Based on code from Dan Wood 
//	http://gigliwood.com/weblog/Cocoa/Better_description_.html
//
//  Modified by Kaelin Colclasure on 3/26/13. (See NSData+RSHexDump.m)
//

#import <Foundation/Foundation.h>


@interface NSData (RSHexDump)

- (NSString *)description;

// startOffset may be negative, indicating offset from end of data
- (NSString *)descriptionFromOffset:(NSInteger)startOffset;
- (NSString *)descriptionFromOffset:(NSInteger)startOffset limitingToByteCount:(NSUInteger)maxBytes;

@end
