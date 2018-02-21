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
ADDRSS  EQU        9728     RAM LOCATION FOR CLRC000 ROUTINE
LOADER  LEAX       CLRC000,PCR Setup to copy CLRC000 routine
        LDY        #ADDRSS  Destination
CLRCPY  LDA        ,X+
        STA        ,Y+
        CMPY       #ADDRSS+CLREND-CLRC000
        BLE        CLRCPY
* STORE ZEROS AT $C000 IN RAM THEN SET ROM MODE AGAIN AND RETURN
        JSR        ADDRSS
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
BASIN   LEAU       BINLOD,PCR
        LDY        3,U      TARGET ADDRESS
	LEAX       5,U      START OF ML
        LDD        1,U      LENGTH
        ADDD       3,U      CALCULATE END ADDRESS
        PULS       U
        STD        733      STORE END ADDRESS
MLCOPY  LDA        ,X+      COPY ML PROGRAM TO RAM
        STA        ,Y+
        CMPY       733
        BLT        MLCOPY
        LDY        3,X      GET EXEC ADDRESS
        CLRA
        STA        112      SET CONSOLE IN BUFFER FLAG 
        JMP        ,Y
* THIS SUBROUTINE STORES A ZEROS AT $C000 IN RAM
* THIS IS NEEDED FOR A COCO 3
* IT IS COPIED TO RAM BEFORE BEING CALLED
CLRC000 CLRA
	STA        $FFDF
        LDX        #$C000
CLRLOOP STA        ,X+
        CMPX       #$C0FF
        BLE        CLRLOOP
        STA        $FFDE
        RTS
CLREND  EQU        *
BINLOD  EQU        *
        END        LOADER
