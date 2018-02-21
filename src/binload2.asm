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
        ORG        $4000
ADDRSS  EQU        $02DD    RAM LOCATION LOADER
LOADER  LEAX       STARTLD,PCR Setup to copy to RAM
        LDY        #ADDRSS  Destination
RAMCPY  LDA        ,X+
        STA        ,Y+
        CMPY       #ADDRSS+LDEND-STARTLD
        BLE        RAMCPY
        JMP        ADDRSS
STARTLD CLRA
        STA        $FF40   SET ROM BANK TO 0
        STA        BANKN,PCR
* THIS SUBROUTINE STORES A ZEROS AT $C000 IN RAM
* THIS IS NEEDED FOR A COCO 3
	STA        $FFDF
        LDX        #$C000
CLRLOOP STA        ,X+
        CMPX       #$C0FF
        BLE        CLRLOOP
        STA        $FFDE
* Now setup basic
        LDA        #85      SET WARM RESET 
        STA        113 
        LDD        #32960   SET EXTENDED BASIC RESET VECTOR 
        STD        114 
        JSR        47452    SET UP PARAMETERS FOR BASIC 
        LDA        #53      RESTORE INTERRUPTS 
        STA        65283    THAT ARE 
        LDA        #52      DISABLED ON 
        STA        65315    CARTRIDGE AUTO START 
        PSHS       U
BASIN   LDU        #BINLOD+$8000
        LDY        3,U      TARGET ADDRESS
	LEAX       5,U      START OF ML
        LDD        1,U      LENGTH
        ADDD       3,U      CALCULATE END ADDRESS
        PULS       U
        STD        733      STORE END ADDRESS
MLCOPY  LDA        ,X+      COPY ML PROGRAM TO RAM
        STA        ,Y+
        CMPX       #$FE00
        BLT        NOTNXT
        LDA        BANKN,PCR
        INCA
        STA        BANKN,PCR CHANGE TO NEXT ROM BANK
        STA        $FF40    SET ROM BANK NUMBER
        LDX        #$C000   START AGAIN AT BEGINING OF ROM
NOTNXT  CMPY       733
        BLT        MLCOPY
        LDY        3,X      GET EXEC ADDRESS
        CLRA
        STA        112      SET CONSOLE IN BUFFER FLAG 
        JMP        ,Y
BANKN   FCB        0
LDEND   EQU        *
BINLOD  EQU        *
        END        LOADER
