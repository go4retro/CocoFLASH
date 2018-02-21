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
BASLOD  EQU        $C800    BASIC PROGRAM  DATA STARTS AT BASLOD
ADDRSS  EQU        9728     RAM LOCATION FOR BASIC PROGRAM
USR0DST EQU        $600
TEMP1   EQU        $700
TEMP2   EQU        $701
TEMP3   EQU        $702
TEMP4   EQU        $703
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
BASIN   LDX        #BASLOD
        LDY        #ADDRSS  THIS IS LOAD ADDRESS OF BASIC (S-1) 
        STY        25       SAVE IT IN BASIC START 
        INC        26       CORRECT THE ACTUAL START VALUE
TNSFER  CLRB                SET END COUNTER TO  ZERO
TNSFR2  LDA        ,X+      GET FIRST BYTE FROM ROMPAK
        STA        ,Y+      TRANSFER BYTE TO BASIC RAM
        BNE        TNSFR2   NON ZERO DATA, KEEP TRANSFERRING
ENDCHK  INCB                ZERO DATA DETECTED, INCREMENT "0" COUNTER
        CMPB #4             IS THERE 4 CONSECUTIVE ZERO'S?
        BEQ        LODDON   IF YES, STOP TRANSFER
        LDA        ,X+      LOAD NEXT ROMPAK BYTE AFTER ZERO
        STA        ,Y+      TRANSFER BYTE TO BASIC RAM
        BNE        TNSFER   NON ZERO DATA, RETURN TO MAIN LOOP
        BRA        ENDCHK   ZERO DATA, INCREMENT COUNTER, STAY IN ZERO LOOP
LODDON  LEAY       -1,Y     CORRECT BASIC END ADDRESS
        STY        27       SAVE END ADDRESS FOR BASIC
UTRUN   LDX        #733     BASIC LINE INPUT BUFFER 
        LDD        #21077   LOAD LETTERS "RU" 
        STD        ,X++
        LDD        #19968   LOAD "N" AND END 
        STD        ,X++
        LDB        #4       INDICATE 4 CHARACTERS 
        CLRA
        STA        112      SET CONSOLE IN BUFFER FLAG 
        LEAX       USR0,PCR Setup to copy USR0 routine
        LDY        #USR0DST Destination
USR0CPY LDA        ,X+
        STA        ,Y+
        CMPY       #USR0DST+USR0END-USR0
        BLE        USR0CPY
        LDX        #732     POINT TO LINE INPUT BUFFER 
        JMP        44159    START MAIN BASIC LOOP 
* Routine which returns characters at a hex address as a string
* String is terminated by any character with an ascii code <$20 or >$7E
USR0    LDA        $FFFE
        LDA        ,X        Get the length of the parameter string
        CMPA       #4        Compare with 4
        BEQ        LEN4      4 character string
EXIT0   CLRA
        STA        ,X        Invalid address, set length of string to 0
        RTS
LEN4    PSHS       X         Save pointer to the string descriptor block
        LDY        2,X       Get start of string address in Y
        LDX        #TEMP1    Point X to the first temp storage byte
* Convert four character hex number
NEXTDGT LDB        ,Y+       Get character in B
        SUBB       #$30      Subtract 48, giving 0-9 for 0-9 characters
        CMPB       #9        Compare result with 9
        BLE        GOODNUM   Result was 0-9
        SUBB       #7        Greater than 9, so subtract 7
        CMPB       #10       A=10
        BGE        GOODNUM
        CMPB       #15       A=15
        BLE        GOODNUM
        PULS       X         Invalid hex digit found
        BRA        EXIT0     Return zero length string
GOODNUM STB        ,X+       Save the conversion of this digit in temp storage
        DECA
        CMPA       #0        Converted all 4 digits?
        BGT        NEXTDGT   No, so convert next digit
        CLRA
        CLRB
        ORB        TEMP1     Load most significant 4 bits and shift it over
        LSLB
        LSLB
        LSLB
        LSLB
        ORB        TEMP2     Load next 4 bits and shift it over
        ROLB
        ROLA
        ROLB
        ROLA
        ROLB
        ROLA
        ROLB
        ROLA
        ORB        TEMP3     Load next 4 bits and shift it over
        ROLB
        ROLA
        ROLB
        ROLA
        ROLB
        ROLA
        ROLB
        ROLA
        ORB        TEMP4     Load least significant 4 bits
        PULS       X         Retrieve pointer to the string descriptor block
        TFR        D,Y       Put converted address in Y
        LDU        #TEMP1    Address to copy string to
        STU        2,X       Point string at cassette data area
        CLRB
FINDLEN LDA        ,Y+       Get next character in string
        CMPA       #$20      Compare with a space character
        BLO        EXITLEN   Less than a space, set the end of the string
        CMPA       #$7E      Compare with a ~ character
        BHI        EXITLEN   Greater than a ~, set the end of the string
        STA        ,U+       Copy string to location in ram
	INCB
        CMPB       #$FF      String max length=254
        BNE        FINDLEN   Check next character
EXITLEN STB        ,X        Save length of string
        RTS
USR0END EQU        *
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
        END        LOADER
