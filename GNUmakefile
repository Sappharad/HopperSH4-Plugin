include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = SH4CPU
SH4CPU_OBJC_FILES = \
	SH4CPU/SH4CPU.m \
	SH4CPU/SH4Ctx.m

#NOWARN=-Wno-format -Wno-return-type -Wno-unused-value -Wno-unused-variable -Wno-self-assign
SH4CPU_OBJCFLAGS=$(NOWARN) \
	-I${HOME}/GNUstep/Library/ApplicationSupport/Hopper/HopperSDK/include \
	-I./SH4CPU/dcdis/ \
	-DLINUX

include $(GNUSTEP_MAKEFILES)/bundle.make
