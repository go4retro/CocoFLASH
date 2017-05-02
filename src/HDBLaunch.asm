*******************************************************************************
* This program will determine which version of HDBDOS is launched depending on*
* if the computer using HDBDOS is a CoCo 1, 2, or 3.                          *
*                                                                             *
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
* Set base address of program registers
        ORG        $FF64
FCNTRL  RMB        1
FLOWA   RMB        1
FHIGHA  RMB        1
        ORG        $4000
START   CLRA
        STA        FCNTRL      Turn CART interupt off
        LDX        #$0602      Load X with target address in RAM
        LEAY       ENDDET,PCR  Load Y with the end address of a routine to detect which computer
        STY        $0600       Store end address
        LEAY       COMPDET,PCR Load Y with the start of a routine to detect which computer
LOOP    LDA        ,Y+         This will get a byte from the routine
        STA        ,X+         This will store A in RAM
        CMPY       $0600       Are we done?
        BLE        LOOP        Not done, getting next byte
        JMP        $0602       We are done, run from RAM
COMPDET LDB        FLOWA       Get current flash ROM bank
        LDA        $FFFE       Byte for CoCo Checking
        CMPA       #$8C        Is this a CoCo 3?
        BEQ        COCO3       Yes
        LDA        FHIGHA      Loads other half of bank number 
        ADDD       #1          Add 1 to bank number
        BRA        STRTHDB     Launch HDBDOS
COCO3   LDA        FHIGHA      Loads other half of bank number
        ADDD       #3          Add 3 to bank number
STRTHDB STA        FHIGHA      Put first part of bank number back
        STB        FLOWA       Put other half of bank number back
        CLR        $71         Set flag for cold start
        JMP        [$FFFE]     Resets computer
ENDDET  END        START
