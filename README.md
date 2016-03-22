# HopperSH4-Plugin
A plugin for Hopper Disassembler which adds support for Hitachi SH4. (Sega Dreamcast, SuperMicro BMC, etc)
Plugin thrown together by Paul Kratt and updated by Trammell Hudson.

The SH4 disassembly code is based on dcdis v0.3.3a by Lars Olsson.
There was no license associated with that code, so I guess there's no license for this Plug-in either.

#To install
1. Checkout or download this repository.
2. Copy the `include/Hopper` directory from the Hopper SDK to `SH4Cpu/Hopper`
2. Open the XCode Project.
3. Build the XCode Project.

That's it. Building the project installs it into the plugins directory.

This is very early / incomplete at the moment and you'll need to know where procedures are to disassemble them. The initial check-in was thrown together in 2 days. This has only been tested on the OS X version of Hopper 3.11.13.

#Known issues
1. You'll need to mark all of the procedures yourself. Jumping to a subroutine always occurs using a register value, and we don't know what's in the register when we're diassembling the instruction. This can be somewhat solved by looking at previous instructions, and I'll probably end up doing that.
2. Some formatting / syntax might not be correct for Hopper.
3. Strings aren't found automatically.
