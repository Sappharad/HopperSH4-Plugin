//
//  M68kCtx.h
//  M68kCPU
//
//  Created by copy/pasting an example on 2015-10-26
//  Copyright (c) 2015 PK and others. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Hopper/Hopper.h>

@class SH4CPU;

@interface SH4Ctx : NSObject<CPUContext>

- (instancetype)initWithCPU:(SH4CPU *)cpu andFile:(NSObject<HPDisassembledFile> *)file;

@end
