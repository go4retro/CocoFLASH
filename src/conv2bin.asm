* Routines to assist copying raw data into RAM
* USR0 sets target address in hex.
*  Example R=USR0("4000")
*  The return value is the address, or -1 for failure.
* USR1 copies string data to the target address.
*  Example R=USR1(D$)
        ORG        $B0
USRPTR  RMB        2
        ORG        $3F00
* Set target address.
USR0    LDA        ,X        Get the length of the parameter string
        CMPA       #4        Compare with 4
        BEQ        LEN4      4 character string
EXIT0   LDD        #$FFFF
        JMP        $B4F4     Return negative number indicating error
        RTS
LEN4    PSHS       X         Save pointer to the string descriptor block
        LDY        2,X       Get start of string address in Y
        LEAX       TEMP1,PCR Point X to the first temp storage byte
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
        ORB        TEMP1,PCR Load most significant 4 bits and shift it over
        LSLB
        LSLB
        LSLB
        LSLB
        ORB        TEMP2,PCR Load next 4 bits and shift it over
        ROLB
        ROLA
        ROLB
        ROLA
        ROLB
        ROLA
        ROLB
        ROLA
        ORB        TEMP3,PCR Load next 4 bits and shift it over
        ROLB
        ROLA
        ROLB
        ROLA
        ROLB
        ROLA
        ROLB
        ROLA
        ORB        TEMP4,PCR Load least significant 4 bits
        PULS       X         Retrieve pointer to the string descriptor block
        STD        TARGADD,PCR Save targe address
        JMP        $B4F4     Return address to BASIC
* Copy string data to target address.
USR1    LDB        ,X        Get the length of the parameter string
        PSHS       B
        LDY        TARGADD,PCR Address to copy string to
        LDX        2,X       Point X at first byte of string data
COPYSTR LDA        ,X+       Get next character in string
        STA        ,Y+       Copy string to location in ram
        DECB
        BNE        COPYSTR   Keep copying
        PULS       B
        CLRA
        JMP        $B4F4     Return bytes copied to BASIC
SETUSR  LDX        USRPTR Address of USR table
        LEAY       USR0,PCR
        STY        ,X++   DEFUSR0
        LEAY       USR1,PCR
        STY        ,X++   DEFUSR1
        RTS
TARGADD FCB        00,00
TEMP1   FCB        00
TEMP2   FCB        00
TEMP3   FCB        00
TEMP4   FCB        00
        END        SETUSR
