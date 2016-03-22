//
//  SH4Ctx.m
//  SH4CPU
//
//  Created by copy/pasting an example on 2015-10-26
//  Copyright (c) 2015 PK and others. All rights reserved.
//

#import "SH4Ctx.h"
#import "SH4CPU.h"
#import "sh7091.h"
#import <Hopper/CommonTypes.h>
#import <Hopper/CPUDefinition.h>
#import <Hopper/HPDisassembledFile.h>
#import "dcdis/decode.h"

@implementation SH4Ctx {
    SH4CPU *_cpu;
    NSObject<HPDisassembledFile> *_file;
}

- (instancetype)initWithCPU:(SH4CPU *)cpu andFile:(NSObject<HPDisassembledFile> *)file {
    if (self = [super init]) {
        _cpu = cpu;
        _file = file;
    }
    return self;
}

- (NSObject<CPUDefinition> *)cpuDefinition {
    return _cpu;
}

- (void)initDisasmStructure:(DisasmStruct *)disasm withSyntaxIndex:(NSUInteger)syntaxIndex {
    bzero(disasm, sizeof(DisasmStruct));
}

// Analysis

- (BOOL)displacementIsAnArgument:(int64_t)displacement forProcedure:(NSObject<HPProcedure> *)procedure {
    return NO;
}

- (NSUInteger)stackArgumentSlotForDisplacement:(int64_t)displacement inProcedure:(NSObject<HPProcedure> *)procedure {
    return -1;
}

- (int64_t)displacementForStackSlotIndex:(NSUInteger)slot inProcedure:(NSObject<HPProcedure> *)procedure {
    return 0;
}

- (Address)adjustCodeAddress:(Address)address {
    // Instructions are always aligned to a multiple of 2.
    return address & ~1;
}

- (uint8_t)cpuModeFromAddress:(Address)address {
    return 0;
}

- (BOOL)addressForcesACPUMode:(Address)address {
    return NO;
}

- (Address)nextAddressToTryIfInstructionFailedToDecodeAt:(Address)address forCPUMode:(uint8_t)mode {
    return ((address & ~1) + 2);
}

- (int)isNopAt:(Address)address {
    uint16_t word = [_file readUInt16AtVirtualAddress:address];
    return (word == 0x0009) ? 2 : 0;
}

- (BOOL)hasProcedurePrologAt:(Address)address {
    // procedures usually begins with a "mov.l R14, @-R15" instruction
    uint16_t word = [_file readUInt16AtVirtualAddress:address];
    return (word == 0x2fe6);
}

- (void)analysisBeginsAt:(Address)entryPoint {

}

- (void)analysisEnded {

}

- (void)procedureAnalysisBeginsForProcedure:(NSObject<HPProcedure> *)procedure atEntryPoint:(Address)entryPoint {

}

- (void)procedureAnalysisOfPrologForProcedure:(NSObject<HPProcedure> *)procedure atEntryPoint:(Address)entryPoint {

}

- (void)procedureAnalysisOfEpilogForProcedure:(NSObject<HPProcedure> *)procedure atEntryPoint:(Address)entryPoint {
}

- (void)procedureAnalysisEndedForProcedure:(NSObject<HPProcedure> *)procedure atEntryPoint:(Address)entryPoint {

}

- (void)procedureAnalysisContinuesOnBasicBlock:(NSObject<HPBasicBlock> *)basicBlock {

}

- (Address)getThunkDestinationForInstructionAt:(Address)address {
    return BAD_ADDRESS;
}

- (void)resetDisassembler {

}

- (uint8_t)estimateCPUModeAtVirtualAddress:(Address)address {
    return 0;
}

uint16_t memory_read_callback(uint32_t address, void* private) {
    SH4Ctx *ctx = (__bridge SH4Ctx *)private;
    return [ctx readWordAt:address];
}

- (uint16_t)readWordAt:(uint32_t)address {
    return [_file readUInt16AtVirtualAddress:address];
}

-(uint32_t)extractTextToNumber:(char*)opperand{
    uint32_t retval = 0;
    NSString* text = [NSString stringWithCString:opperand encoding:NSASCIIStringEncoding];
    if([text rangeOfString:@"h'"].location != NSNotFound){
        //This is Hex
        NSCharacterSet* cs = [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdef"];
        NSString* hexa = [[text componentsSeparatedByCharactersInSet:[cs invertedSet]] componentsJoinedByString:@""];
        NSScanner* scanny = [NSScanner scannerWithString:hexa];
        [scanny scanHexInt:&retval];
    }
    else{
        //Just pull all of the numbers we can find and shove
        NSString* numbers = [[text componentsSeparatedByCharactersInSet:
                                [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                               componentsJoinedByString:@""];
        retval = [numbers intValue];
    }
    return retval;
}

- (int)disassembleSingleInstruction:(DisasmStruct *)disasm usingProcessorMode:(NSUInteger)mode {
    //char instr[1024];
    
    char* instr = decode((uint32_t)disasm->virtualAddr, memory_read_callback, (__bridge void*)self);
    //This is really shitty because I'm using memory that I shouldn't still have

    disasm->instruction.branchType = DISASM_BRANCH_NONE;
    disasm->instruction.addressValue = 0;
    for (int i=0; i<DISASM_MAX_OPERANDS; i++) disasm->operand[i].type = DISASM_OPERAND_NO_OPERAND;

    // Quick and dirty split of the instruction
    char *ptr = instr;
    char *instrPtr = disasm->instruction.mnemonic;
    while (*ptr && *ptr != ' ') *instrPtr++ = tolower(*ptr++);
    *instrPtr = 0;
    while (*ptr == ' ') ptr++;

    int operandIndex = 0;
    char *operand = disasm->operand[operandIndex].mnemonic;
    int p_level = 0;
    while (*ptr) {
        if (*ptr == ',' && p_level == 0) {
            *operand = 0;
            operand = disasm->operand[++operandIndex].mnemonic;
            ptr++;
            while (*ptr == ' ') ptr++;
        }
        else {
            if (*ptr == '(') p_level++;
            if (*ptr == ')') p_level--;
            *operand++ = tolower(*ptr++);
        }
    }
    *operand = 0;
    
    if(strncmp(disasm->instruction.mnemonic, "???", 3) == 0){
        return DISASM_UNKNOWN_OPCODE;
    }

    // In this early version, only branch instructions are analyzed in order to correctly
    // construct basic blocks of procedures.
    //
    // This is the strict minimum!
    //
    // You should also fill the "operand" description for every other instruction to take
    // advantage of the various analysis of Hopper.

    if (true) {
        if (strncmp(disasm->instruction.mnemonic, "jsr", 3) == 0
         || strncmp(disasm->instruction.mnemonic, "bsr", 3) == 0) {
            disasm->instruction.branchType = DISASM_BRANCH_CALL;
            disasm->instruction.addressValue = [self extractTextToNumber:disasm->operand[0].mnemonic];
            disasm->operand[0].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
            disasm->operand[0].immediateValue = disasm->instruction.addressValue;
            if(disasm->operand[0].mnemonic[0]=='@' && disasm->operand[0].mnemonic[1]=='r'){
                //This is pulling a value from a register. Check if the previous line populates that register. That happens a lot.
                uint32_t prev_PC = ((uint32_t)disasm->virtualAddr)-2;
                uint16_t opcode = memory_read_callback(prev_PC, (__bridge void*)self);
                if((opcode&0xf000) == MOVL0 && ((opcode>>8)&0xF)==disasm->instruction.addressValue){
                    uint32_t reference = (IMM*4+(prev_PC&0xfffffffc)+4);
                    uint32_t literal = ((memory_read_callback(reference+2, (__bridge void*)self) << 16) | memory_read_callback(reference, (__bridge void*)self));
                    disasm->instruction.addressValue = literal;
                }
            }
        }
        else if (strncmp(disasm->instruction.mnemonic, "rts", 3) == 0){
            disasm->instruction.branchType = DISASM_BRANCH_RET;
        }
        else {
            //Todo: There's a BRAF instruction too. Read about it.
            if (strncmp(disasm->instruction.mnemonic, "bra", 3) == 0) {
                disasm->instruction.branchType = DISASM_BRANCH_JMP;
                disasm->instruction.addressValue = [self extractTextToNumber:disasm->operand[0].mnemonic];
                disasm->operand[0].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                disasm->operand[0].immediateValue = disasm->instruction.addressValue;
            }
            if (strncmp(disasm->instruction.mnemonic, "bf", 2) == 0) {
                disasm->instruction.branchType = DISASM_BRANCH_JNE;
                disasm->instruction.addressValue = [self extractTextToNumber:disasm->operand[0].mnemonic];
                disasm->operand[0].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                disasm->operand[0].immediateValue = disasm->instruction.addressValue;
            }
            if (strncmp(disasm->instruction.mnemonic, "bt", 2) == 0) {
                disasm->instruction.branchType = DISASM_BRANCH_JE;
                disasm->instruction.addressValue = [self extractTextToNumber:disasm->operand[0].mnemonic];
                disasm->operand[0].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                disasm->operand[0].immediateValue = disasm->instruction.addressValue;
            }
        }
    }

    int len = 2; //Instructions are always 2 bytes
    return len;
}

- (BOOL)instructionHaltsExecutionFlow:(DisasmStruct *)disasm {
    return NO;
}

- (void)performBranchesAnalysis:(DisasmStruct *)disasm computingNextAddress:(Address *)next andBranches:(NSMutableArray *)branches forProcedure:(NSObject<HPProcedure> *)procedure basicBlock:(NSObject<HPBasicBlock> *)basicBlock ofSegment:(NSObject<HPSegment> *)segment calledAddresses:(NSMutableArray *)calledAddresses callsites:(NSMutableArray *)callSitesAddresses {

}

- (void)performInstructionSpecificAnalysis:(DisasmStruct *)disasm forProcedure:(NSObject<HPProcedure> *)procedure inSegment:(NSObject<HPSegment> *)segment {

}

- (void)performProcedureAnalysis:(NSObject<HPProcedure> *)procedure basicBlock:(NSObject<HPBasicBlock> *)basicBlock disasm:(DisasmStruct *)disasm {

}

- (void)updateProcedureAnalysis:(DisasmStruct *)disasm {

}

// Printing

- (NSString *)defaultFormattedVariableNameForDisplacement:(int64_t)displacement inProcedure:(NSObject<HPProcedure> *)procedure {
    return [NSString stringWithFormat:@"var%lld", displacement];
}

- (void)buildInstructionString:(DisasmStruct *)disasm forSegment:(NSObject<HPSegment> *)segment populatingInfo:(NSObject<HPFormattedInstructionInfo> *)formattedInstructionInfo {
    const char *spaces = "                ";
    strcpy(disasm->completeInstructionString, disasm->instruction.mnemonic);
    strcat(disasm->completeInstructionString, spaces + strlen(disasm->instruction.mnemonic));
    for (int i=0; i<DISASM_MAX_OPERANDS; i++) {
        if (disasm->operand[i].mnemonic[0] == 0) break;
        if (i) strcat(disasm->completeInstructionString, ", ");
        strcat(disasm->completeInstructionString, disasm->operand[i].mnemonic);
    }
}

// Decompiler

- (BOOL)canDecompileProcedure:(NSObject<HPProcedure> *)procedure {
    return NO;
}

- (Address)skipHeader:(NSObject<HPBasicBlock> *)basicBlock ofProcedure:(NSObject<HPProcedure> *)procedure {
    return basicBlock.from;
}

- (Address)skipFooter:(NSObject<HPBasicBlock> *)basicBlock ofProcedure:(NSObject<HPProcedure> *)procedure {
    return basicBlock.to;
}

- (ASTNode *)rawDecodeArgumentIndex:(int)argIndex
                           ofDisasm:(DisasmStruct *)disasm
                  ignoringWriteMode:(BOOL)ignoreWrite
                    usingDecompiler:(Decompiler *)decompiler {
    return nil;
}

- (ASTNode *)decompileInstructionAtAddress:(Address)a
                                    disasm:(DisasmStruct)d
                                 addNode_p:(BOOL *)addNode_p
                           usingDecompiler:(Decompiler *)decompiler {
    return nil;
}

// Assembler

- (NSData *)assembleRawInstruction:(NSString *)instr atAddress:(Address)addr forFile:(NSObject<HPDisassembledFile> *)file withCPUMode:(uint8_t)cpuMode usingSyntaxVariant:(NSUInteger)syntax error:(NSError **)error {
    return nil;
}

- (BOOL)instructionCanBeUsedToExtractDirectMemoryReferences:(DisasmStruct *)disasmStruct {
    return YES;
}

- (BOOL)instructionMayBeASwitchStatement:(DisasmStruct *)disasmStruct {
    return NO;
}

@end
