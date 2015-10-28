//
//  SH4CPU.h
//  SH4CPU
//
//  Created by copy/pasting an example on 2015-10-26
//  Copyright (c) 2015 PK and others. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Hopper/Hopper.h>

typedef NS_ENUM(NSUInteger, SH4RegClass) {
    RegClass_AddressRegister = RegClass_FirstUserClass,
    RegClass_SH4_Cnt
};

@interface SH4CPU : NSObject<CPUDefinition>

@end
