*******************************************************************************
* Routine for USR0 to program a 4K bank in the flash rom                      *
* USR2 must be called to set the proper bank before USR0 is called            *
* Call from BASIC with:                                                       *
* CLEAR 200,&H3FFF                                                            *
* BANKADD=positon in rom to program                                           *
* A=USR2(BANKADD)                                                             *
* ADDRESS=address with data to program                                        *
* ADDRESS=ADDRESS+(ADDRESS>32767)*65536                                       *
* A=USR0(ADDRESS)                                                             *
*******************************************************************************
*Copyright (C) 2016 Barry Nelson
*
*This program is free software; you can redistribute it and/or
*modify it under the terms of the GNU General Public License
*as published by the Free Software Foundation; either version 2
*of the License, or (at your option) any later version.
*
*This program is distributed in the hope that it will be useful,
*but WITHOUT ANY WARRANTY; without even the implied warranty of
*MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*GNU General Public License for more details.
*
*You should have received a copy of the GNU General Public License
*along with this program; if not, write to the Free Software
*Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*
* Set base address of program registers
        ORG        $FF64
FCNTRL  RMB        1
FLOWA   RMB        1
FHIGHA  RMB        1
        ORG        $B0
USRPTR  RMB        2
        ORG        $3E00
* USR0 program a 4K block
USR0    JSR        $B3ED  Get argument to A=USR0(ADDRESS)
        TFR        D,X    Save address in X
        LDY        #$C000 Set target address
        ORCC       #$50   Disable interrupts
        STA        $FFDE  Enable ROM in memory map
* Set error count to 0
        CLRB
LOOP    CMPY       #$D000 Have we finished a 4K chunk?
        BEQ        EXIT   Yes, exit loop
        INCB
        CMPB       #$FF   Pass # 255?
        BEQ        FAIL   Too many attempts, fail
        LDA        #$81   Set bits for LED on and write enable
        STA        FCNTRL Send to flash card control register
        LBSR       PREAMB Set up write sequence
        LDA        #$A0
        STA        $CAAA
        LDA        ,X     Get data to write to flash
        STA        ,Y     Write to flash
PPOLL   LDA        $C000  Poll the operation status
        EORA       $C000
        ANDA       #$40   Bits toggling?
        BNE        PPOLL  Yes, keep polling
        CLRA
        STA        FCNTRL Turns off LED and disables write mode
        PSHS       B
        CLRB
DELAY   NOP
        INCB
        CMPB       #100
        BLE        DELAY
        PULS       B
        LDA        ,Y     Load data back
        CMPA       ,X     Does it match?
        BNE        RESET  Try again
        CLRB
        LEAX       1,X    Increment source address
        LEAY       1,Y    Increment destination address
        BRA        LOOP   Next byte
RESET   LDA        #$F0   Reset command
        STA        $C000  Send reset
PPOLL2  LDA        $C000  Poll the operation status
        EORA       $C000
        ANDA       #$40   Bits toggling?
        BNE        PPOLL2 Yes, keep polling
        BRA        LOOP   Go try again
EXIT    STA        $FFDF  Disable ROM in memory map
        ANDCC      #$AF   Enable interrupts
        CLRA
        STA        FCNTRL Turn off write access and LED
        LDA        FHIGHA Load bank #
        LDB        FLOWA
        ANDA       #$07   Mask unused bits
        ADDD       #1     Increment bank #
        STA        FHIGHA Store new bank #
        STB        FLOWA
        JMP        $B4F4  Return next bank number
FAIL    STA        $FFDF  Disable ROM in memory map
        ANDCC      #$AF   Enable interrupts
        CLRA
        STA        FCNTRL Turn off write access and LED
        TFR        Y,D
        JMP        $B4F4  Return negative number representing the address
* USR1 get bank adress
USR1    LDA        FHIGHA Load bank #
        LDB        FLOWA
        ANDA       #$07   Mask unused bits
        JMP        $B4F4  Return bank number
* USR2 set bank address
USR2    JSR        $B3ED  Get argument to A=USR2(BANK)
        ANDA       #$07   Mask unused bits
        STA        FHIGHA High bits
        STB        FLOWA  Low bits
        JMP        $B4F4  Return bank number
* USR3 set bank address and erase chip
USR3    JSR        $B3ED  Get argument to A=USR3(BANK)
        ANDA       #$07   Mask unused bits
        STA        FHIGHA High bits
        STB        FLOWA  Save page offset
        ORCC       #$50   Disable interrupts
        STA        $FFDE  Enable ROM in memory map
        LDA        #$81   Set bits for LED on and write enable
        STA        FCNTRL Send to flash card control register
        LBSR       PREAMB Send erase instruction
        LDA        #$80
        STA        $CAAA
        LBSR       PREAMB
        LDA        #$30
        STA        $C000
CHKERA  LDA        $C000  Get a test data byte
        CMPA       #$FF   Is it erased?
        BNE        CHKERA No, wait
        STA        $FFDF  Disable ROM in memory map
        ANDCC      #$AF   Enable interrupts
        CLRA
        STA        FCNTRL Turn off write access and LED
        LDA        FHIGHA Load bank #
        LDB        FLOWA
        ANDA       #$07   Mask unused bits
        JMP        $B4F4  Return start bank number
* USR4 read byte from EEPROM
USR4    JSR        $B3ED  Get argument to A=USR4(ADDRESS)
        TFR        D,X    Save address in X
        CLRA
        STA        FCNTRL Turn off write, cart interupt and LED.
        ORCC       #$50   Disable interrupts
        STA        $FFDE  Enable ROM in memory map
        LDB        ,X     Get byte at address in rom
        STA        $FFDF  Disable ROM in memory map
        ANDCC      #$AF   Enable interrupts
        JMP        $B4F4  Return the byte read from the ROM
* USR5 activate bank
USR5    JSR        $B3ED  Get argument to A=USR5(FLAGS)
        ORCC       #$50   Disable interrupts
        CLRA
        STA        $FFDE  Enable ROM in memory map
        STA        $71    Poke 113,0 cold start
        STB        FCNTRL Set CART/LED etc on/off
        ANDCC      #$AF   Enable interrupts
        JMP        [$FFFE] Restart
* USR6 check if bank is erased
USR6    LBSR       USR2   Set the bank registers to the passed value
        CLRA
        STA        FCNTRL Turn off write, cart interupt and LED.
        ORCC       #$50   Disable interrupts
        STA        $FFDE  Enable ROM in memory map
        LDX        #$C000 Set address to test
ERACHK  CMPX       #$D000 Done testing?
        BEQ        ISERA  Exit and return 1
        LDA        ,X+    Get next byte
        CMPA       #$FF   Is it FF?
        BNE        NOTERA Exit and return 0
        BRA        ERACHK Check next address
ISERA   LDB        #1     Status is erased
RETERA  CLRA
        STA        $FFDF  Disable ROM in memory map
        ANDCC      #$AF   Enable interrupts
        JMP        $B4F4  Return erase status
NOTERA  CLRB
        BRA        RETERA Return 0, not erased
USR7    CLRA
        STA        FHIGHA High bits
        STA        FLOWA  Save page offset
        ORCC       #$50   Disable interrupts
        STA        $FFDE  Enable ROM in memory map
        LDA        #$81   Set bits for LED on and write enable
        STA        FCNTRL Send to flash card control register
        LBSR       PREAMB Send erase instruction
        LDA        #$80
        STA        $CAAA
        LBSR       PREAMB
        LDA        #$10
        STA        $CAAA
CHPERA  LDA        $C000  Get a test data byte
        CMPA       #$FF   Is it erased?
        BNE        CHPERA No, wait
        STA        $FFDF  Disable ROM in memory map
        ANDCC      #$AF   Enable interrupts
        CLRA
        STA        FCNTRL Turn off write access and LED
        CLRA
        CLRB
        JMP        $B4F4  Return start bank number
SETRAM  LDX        USRPTR Address of USR table
        LEAY       USR0,PCR
        STY        ,X++   DEFUSR0
        LEAY       USR1,PCR
        STY        ,X++   DEFUSR1
        LEAY       USR2,PCR
        STY        ,X++   DEFUSR2
        LEAY       USR3,PCR
        STY        ,X++   DEFUSR3
        LEAY       USR4,PCR
        STY        ,X++   DEFUSR4
        LEAY       USR5,PCR
        STY        ,X++   DEFUSR5
        LEAY       USR6,PCR
        STY        ,X++   DEFUSR6
        LEAY       USR7,PCR
        STY        ,X++   DEFUSR7
        LDA        $FFFE  Get first byte of the reset vector
        CMPA       #$8C   Is this a CoCo 3?
        BNE        COCO12 No, so we need to setup RAM mode
* For CoCo 3, just clear ram from the end of this program to $7FFF
        BRA        FFSTART
COCO12  ORCC       #$50   Disable interrupts
        LDX        #$8000 Start of ROM
        LDA        ,X     Save value
        CLR        ,X     Test for RAM
        LDB        ,X     Get value
        CMPB       #0     Are we currently in all RAM mode?
        BNE        RAMLOOP No, go to RAM mode
        STA        ,X     Put original value back
        BRA        FFSTART
RAMLOOP STA        $FFDE  Enable ROM in memory map
        LDA        ,X
        STA        $FFDF  Enable RAM in memory map
        STA        ,X+
        CMPX       #$FF00 Done copying ROM to RAM?
        BNE        RAMLOOP
FFSTART LDA        #$FF   Clear ram to $FF up to adress $7FFF
	LEAX       ENDPROG,PCR
FFLOOP	CMPX       #$8000
        BEQ        FFDONE
        STA        ,X+
        BRA        FFLOOP
FFDONE  ANDCC      #$AF   Enable interrupts
        RTS
PREAMB  LDA        #$AA
        STA        $CAAA
        LDA        #$55
        STA        $C555
        RTS
ENDPROG END        SETRAM
