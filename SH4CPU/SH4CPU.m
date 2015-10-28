//
//  SH4CPU.m
//  SH4CPU
//
//  Created by copy/pasting an example on 2015-10-26
//  Copyright (c) 2015 PK and others. All rights reserved.
//

#import "SH4CPU.h"
#import "SH4Ctx.h"

@implementation SH4CPU {
    NSObject<HPHopperServices> *_services;
}

- (instancetype)initWithHopperServices:(NSObject<HPHopperServices> *)services {
    if (self = [super init]) {
        _services = services;
    }
    return self;
}

- (NSObject<CPUContext> *)buildCPUContextForFile:(NSObject<HPDisassembledFile> *)file {
    return [[SH4Ctx alloc] initWithCPU:self andFile:file];
}

- (HopperUUID *)pluginUUID {
    return [_services UUIDWithString:@"5e674a29-23c1-4635-abb4-bfee36ce924b"];
}

- (HopperPluginType)pluginType {
    return Plugin_CPU;
}

- (NSString *)pluginName {
    return @"Hitachi SH-4";
}

- (NSString *)pluginDescription {
    return @"Hitachi SH-4 CPU support";
}

- (NSString *)pluginAuthor {
    return @"Paul Kratt, based on dcdis by Lars Olsson";
}

- (NSString *)pluginCopyright {
    return @"©2015 - PK and Others";
}

- (NSArray *)cpuFamilies {
    return @[@"hitachi"];
}

- (NSString *)pluginVersion {
    return @"0.0.1";
}

- (NSArray *)cpuSubFamiliesForFamily:(NSString *)family {
    if ([family isEqualToString:@"hitachi"]) return @[@"sh4"];
    return nil;
}

- (int)addressSpaceWidthInBitsForCPUFamily:(NSString *)family andSubFamily:(NSString *)subFamily {
    if ([family isEqualToString:@"hitachi"] && [subFamily isEqualToString:@"sh4"]) return 32;
    return 0;
}

- (CPUEndianess)endianess {
    return CPUEndianess_Little; //Can actually be either, but Dreamcast uses Little.
}

- (NSUInteger)syntaxVariantCount {
    return 1;
}

- (NSUInteger)cpuModeCount {
    return 1;
}

- (NSArray *)syntaxVariantNames {
    return @[@"generic"];
}

- (NSArray *)cpuModeNames {
    return @[@"generic"];
}

- (NSString *)framePointerRegisterNameForFile:(NSObject<HPDisassembledFile> *)file {
    return nil;
}

- (NSUInteger)registerClassCount {
    return RegClass_SH4_Cnt;
}

- (NSUInteger)registerCountForClass:(RegClass)reg_class {
    switch (reg_class) {
        case RegClass_CPUState: return 1;
        case RegClass_PseudoRegisterSTACK: return 32;
        case RegClass_GeneralPurposeRegister: return 8;
        case RegClass_AddressRegister: return 8;
        default: break;
    }
    return 0;
}

- (BOOL)registerIndexIsStackPointer:(uint32_t)reg ofClass:(RegClass)reg_class {
    return reg_class == RegClass_AddressRegister && reg == 7;
}

- (BOOL)registerIndexIsFrameBasePointer:(uint32_t)reg ofClass:(RegClass)reg_class {
    return NO;
}

- (BOOL)registerIndexIsProgramCounter:(uint32_t)reg {
    return NO;
}

- (NSString *)registerIndexToString:(int)reg ofClass:(RegClass)reg_class withBitSize:(int)size andPosition:(DisasmPosition)position {
    switch (reg_class) {
        case RegClass_CPUState: return @"CCR";
        case RegClass_PseudoRegisterSTACK: return [NSString stringWithFormat:@"STK%d", reg];
        case RegClass_GeneralPurposeRegister: return [NSString stringWithFormat:@"d%d", reg];
        case RegClass_AddressRegister: return [NSString stringWithFormat:@"a%d", reg];
        default: break;
    }
    return nil;
}

- (NSString *)cpuRegisterStateMaskToString:(uint32_t)cpuState {
    return @"";
}

- (NSUInteger)translateOperandIndex:(NSUInteger)index operandCount:(NSUInteger)count accordingToSyntax:(uint8_t)syntaxIndex {
    return index;
}

- (NSAttributedString *)colorizeInstructionString:(NSAttributedString *)string {
    NSMutableAttributedString *colorized = [string mutableCopy];
    [_services colorizeASMString:colorized
               operatorPredicate:^BOOL(unichar c) {
                   return (c == '#' || c == '$');
               }
           languageWordPredicate:^BOOL(NSString *s) {
               return [s isEqualToString:@"r0"] || [s isEqualToString:@"r1"] || [s isEqualToString:@"r2"] || [s isEqualToString:@"r3"]
               || [s isEqualToString:@"r4"] || [s isEqualToString:@"r5"] || [s isEqualToString:@"r6"] || [s isEqualToString:@"r7"]
               || [s isEqualToString:@"r8"] || [s isEqualToString:@"r9"] || [s isEqualToString:@"r10"] || [s isEqualToString:@"r11"]
               || [s isEqualToString:@"r12"] || [s isEqualToString:@"r13"] || [s isEqualToString:@"r14"] || [s isEqualToString:@"r15"]
               || [s isEqualToString:@"fr0"] || [s isEqualToString:@"fr1"] || [s isEqualToString:@"fr2"] || [s isEqualToString:@"fr3"]
               || [s isEqualToString:@"fr4"] || [s isEqualToString:@"fr5"] || [s isEqualToString:@"fr6"] || [s isEqualToString:@"fr7"]
               || [s isEqualToString:@"fr8"] || [s isEqualToString:@"fr9"] || [s isEqualToString:@"fr10"] || [s isEqualToString:@"fr11"]
               || [s isEqualToString:@"fr12"] || [s isEqualToString:@"fr13"] || [s isEqualToString:@"fr14"] || [s isEqualToString:@"fr15"];
           }
        subLanguageWordPredicate:^BOOL(NSString *s) {
            return NO;
        }];
    return colorized;
}

- (NSData *)nopWithSize:(NSUInteger)size andMode:(NSUInteger)cpuMode forFile:(NSObject<HPDisassembledFile> *)file {
    // Instruction size is always a multiple of 2
    if (size & 1) return nil;
    NSMutableData *nopArray = [[NSMutableData alloc] initWithCapacity:size];
    [nopArray setLength:size];
    uint16_t *ptr = (uint16_t *)[nopArray mutableBytes];
    for (NSUInteger i=0; i<size; i+=2) {
        OSWriteLittleInt16(ptr, i, 0x0009);
    }
    return [NSData dataWithData:nopArray];
}

- (BOOL)canAssembleInstructionsForCPUFamily:(NSString *)family andSubFamily:(NSString *)subFamily {
    return NO;
}

- (BOOL)canDecompileProceduresForCPUFamily:(NSString *)family andSubFamily:(NSString *)subFamily {
    return NO;
}

@end
