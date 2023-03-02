*-----------------------------------------------------------
* Title      : MCD Monitor Program
* Written by : Joseph Wang
* Date       : 3/4/2022
* Description: Monitor program for MCD, six functions (RW memory, RW register, load and run S-record)
*-----------------------------------------------------------

        org     $000000

        dc.l    stack           ; initialize stack pointer
        dc.l    start           ; initialize program counter with first instruction


* PROGRAM --------------------------------------------------
        org     $001000

sim     equ     $1       ; 0 is hardware, 1 is simulation

* initialize DUART
start   movem.l a0,-(sp)
        LEA  DUART,A0	; A0 points to base DUART address

        * software reset
      	MOVE.B	#$30,CRA(A0)	; Reset TxA
        MOVE.B	#$20,CRA(A0)	; Reset RxA
        MOVE.B	#$10,CRA(A0)	; Reset MRA pointer

        * initialization:
        MOVE.B  #$80,ACR(A0)	; selects baud rate set 2
        MOVE.B  #BAUD,CSRA(A0)  ; set 19.2k baud Rx/Tx
        MOVE.B  #$13,MR1A(A0)   ; 8-bits, no parity, 1 stop bit

        MOVE.B	#$07,MR2A(A0)	; $07 normal mode, $47 auto echo
        MOVE.B	#$05,CRA(A0)	; enable Tx and Rx

        * @@ ADDED THESE TWO
        MOVE.B	#$07, ($11, A0)	;$07 for normal, $47 for auto-echo
	MOVE.B	#$05, ($15, A0)	;Enable Tx and Rx

        movem.l (sp)+,a0


        lea     stack,sp        ; load stack pointer address


* print intro message
        move.l  #0,d0
        move.l  #0,d1
        move.l  #0,d2
        move.l  #0,d3
        move.l  #0,d4
        move.l  #0,d5
        move.l  #0,d6
        move.l  #0,d7

        move.l  #0,a0
        move.l  #0,a1
        move.l  #0,a2
        move.l  #0,a3
        move.l  #0,a4
        move.l  #0,a5
        move.l  #0,a6


        movem.l a1,-(sp)
        lea     intro,a1
        jsr     printStr
        movem.l (sp)+,a1


* print menu
menuLoop movem.l a1,-(sp)
        lea     menu,a1
        jsr     printStr
        movem.l (sp)+,a1

        * get character
        movem.l d1,-(sp)

        jsr     getChar

        * if select option 1 (ASCII $31), read from memory
        cmp.b   #$31,d1
        beq     readMem

        cmp.b   #$32,d1
        beq     writeMem

        cmp.b   #$33,d1
        beq     readReg

        cmp.b   #$34,d1
        beq     writeReg

        cmp.b   #$35,d1
        beq     loadSRec

        cmp.b   #$36,d1
        beq     runSRec

        bra     menuLoop

        * halt simulator
        move.b  #9,d0
        trap    #15

        simhalt


* code to read a long word from memory location given by user
        * restore D1 from stack
readMem movem.l (sp)+,d1
        movem.l d0-d2/a0-a1,-(sp)

        * print read from memory message
        lea     readMemMsg,a1
        jsr     printStr

        * get address from user (24 bits)
        move.l  #0,d2
        jsr     inA
        
        * move contents of memory location to D2
        move.l  d2,a0
        move.l  (a0),d2

        * print message
        lea     readMemMsg2,a1
        jsr     printStr

        * convert D2 hex to ASCII and print out
        jsr     outL

        lea     crlf,a1
        jsr     printStr

        movem.l (sp)+,d0-d2/a0-a1
        bra     menuLoop


writeMem movem.l (sp)+,d1
        movem.l d2/a0-a1,-(sp)

        * print initial message
        lea     writeMemMsg,a1
        jsr     printStr

        * get address from user (24 bits) and store in A0
        move.l  #0,d2
        jsr     inA
        move.l  d2,a0

        * print message to get longword
        lea     writeMemMsg2,a1
        jsr     printStr

        * get longword into D2
        jsr     inL

        * move longword into address
        move.l  d2,(a0)

        * print notification message
        lea     writeMemMsg3,a1
        jsr     printStr

        movem.l (sp)+,d2/a0-a1
        bra     menuLoop


readReg movem.l (sp)+,d1
        movem.l d2/a1,-(sp)

        * print initial message
        lea     readRegMsg,a1
        jsr     printStr

        * get register as byte into D2
        jsr     inB

        * figure  out which register reading from
        cmp.b   #$d0,d2
        beq     .d0
        cmp.b   #$d1,d2
        beq     .d1
        cmp.b   #$d2,d2
        beq     .d2
        cmp.b   #$d3,d2
        beq     .d3
        cmp.b   #$d4,d2
        beq     .d4
        cmp.b   #$d5,d2
        beq     .d5
        cmp.b   #$d6,d2
        beq     .d6
        cmp.b   #$d7,d2
        beq     .d7

        cmp.b   #$a0,d2
        beq     .a0
        cmp.b   #$a1,d2
        beq     .a1
        cmp.b   #$a2,d2
        beq     .a2
        cmp.b   #$a3,d2
        beq     .a3
        cmp.b   #$a4,d2
        beq     .a4
        cmp.b   #$a5,d2
        beq     .a5
        cmp.b   #$a6,d2
        beq     .a6
        cmp.b   #$a7,d2
        beq     .a7

        * print message
.out    lea     readRegMsg2,a1
        jsr     printStr

        * print register contents
        jsr     outL

        lea     crlf,a1
        jsr     printStr

        movem.l (sp)+,d2/a1
        bra     menuLoop


* subroutines for reading from register, output to D2
.d0     move.l  d0,d2
        bra     .out

.d1     move.l  d1,d2
        bra     .out

        * read D2 from stack without modifying SP
.d2     movem.l (sp),d2
        bra     .out

.d3     move.l  d3,d2
        bra     .out

.d4     move.l  d4,d2
        bra     .out

.d5     move.l  d5,d2
        bra     .out

.d6     move.l  d6,d2
        bra     .out

.d7     move.l  d7,d2
        bra     .out

.a0     move.l  a0,d2
        bra     .out

        * read A1 from stack
.a1     movem.l (sp),d2/a1
        move.l  a1,d2
        bra     .out

.a2     move.l  a2,d2
        bra     .out

.a3     move.l  a3,d2
        bra     .out

.a4     move.l  a4,d2
        bra     .out

.a5     move.l  a5,d2
        bra     .out

.a6     move.l  a6,d2
        bra     .out

.a7     move.l  a7,d2
        bra     .out


writeReg movem.l (sp)+,d1

        * print initial message
        movem.l a1,-(sp)
        lea     writeRegMsg,a1
        jsr     printStr
        movem.l (sp)+,a1

        * get register as byte into D3
        movem.l d2-d3,-(sp)
        jsr     inB
        move.b  d2,d3
        movem.l (sp)+,d2

        * print message to get longword
        movem.l a1,-(sp)
        lea     writeRegMsg2,a1
        jsr     printStr
        movem.l (sp)+,a1

        * get longword into D2
        movem.l d2,-(sp)
        jsr     inL

        * figure out which register writing to
        cmp.b   #$d0,d3
        beq     .d0
        cmp.b   #$d1,d3
        beq     .d1
        cmp.b   #$d2,d3
        beq     .d2
        cmp.b   #$d3,d3
        beq     .d3
        cmp.b   #$d4,d3
        beq     .d4
        cmp.b   #$d5,d3
        beq     .d5
        cmp.b   #$d6,d3
        beq     .d6
        cmp.b   #$d7,d3
        beq     .d7

        cmp.b   #$a0,d3
        beq     .a0
        cmp.b   #$a1,d3
        beq     .a1
        cmp.b   #$a2,d3
        beq     .a2
        cmp.b   #$a3,d3
        beq     .a3
        cmp.b   #$a4,d3
        beq     .a4
        cmp.b   #$a5,d3
        beq     .a5
        cmp.b   #$a6,d3
        beq     .a6

.out    * print notification message
        movem.l (sp)+,d2-d3

        movem.l a1,-(sp)
        lea     writeRegMsg3,a1
        jsr     printStr
        movem.l (sp)+,a1

        bra     menuLoop


* subroutines for writing to registers, input from D2
.d0     move.l  d2,d0
        bra     .out

.d1     move.l  d2,d1
        bra     .out

        * increment stack pointer by 4 (longword), then push new D2 onto stack
.d2     add     #4,sp
        movem.l d2,-(sp)
        bra     .out

        * move D2 to D3, then restore D2 and skip D3 (increment stack pointer by 4, longword)
.d3     move.l  d2,d3
        movem.l (sp)+,d2
        add     #4,sp
        movem.l d2-d3,-(sp)
        bra     .out

.d4     move.l  d2,d4
        bra     .out

.d5     move.l  d2,d5
        bra     .out

.d6     move.l  d2,d6
        bra     .out

.d7     move.l  d2,d7
        bra     .out


.a0     move.l  d2,a0
        bra     .out

.a1     move.l  d2,a1
        bra     .out

.a2     move.l  d2,a2
        bra     .out

.a3     move.l  d2,a3
        bra     .out

.a4     move.l  d2,a4
        bra     .out

.a5     move.l  d2,a5
        bra     .out

.a6     move.l  d2,a6
        bra     .out


loadSRec movem.l (sp)+,d1

        movem.l d1-d4/a0-a1,-(sp)

        * print initial message
        lea     loadSRecMsg,a1
        jsr     printStr


        * start at address $00A000 (hardcoded)
        * @@@ MIGHT NEED TO CHANGE
        lea     sRecLoc,a0
        * sub.w   #1,a0     

        * get type into D4
.sRecLine jsr     getChar
        jsr     inN
        move.b  d1,d4

        * get count
        jsr     inB
        move.b  d2,d3

        * skip address
        jsr     inA

        * loop count minus 4 times, getting data
        sub.b   #4,d3

        * check type (skip S0 and S8 data)
        cmp.b   #0,d4
        beq     .skipData
        cmp.b   #8,d4
        beq     .skipData

        * get S1 data
.s1Loop jsr     inB
        move.b  d2,(a0)+

        sub.b   #1,d3
        cmp.b   #0,d3
        bne     .s1Loop
        bra     .checksum

        * skip S0 and S8 data
.skipData cmp.b   #0,d3
        beq     .checksum

.loop   jsr     inB
        sub.b   #1,d3
        cmp.b   #0,d3
        bne     .loop
        
        * skip checksum and CR and LF
.checksum jsr     inB
        jsr     getChar
        jsr     getChar

        * if S8, done
        cmp.b   #8,d4
        beq     .out

        * otherwise keep taking in S records
        bra     .sRecLine


        * print notification message
.out    lea     loadSRecMsg2,a1
        jsr     printStr

        movem.l (sp)+,d1-d4/a0-a1

        bra     menuLoop


runSRec movem.l (sp)+,d1
        jsr     sRecLoc

        movem.l a1,-(sp)
        lea     crlf,a1
        jsr     printStr
        movem.l (sp)+,a1

        bra     menuLoop

* SUBROUTINES ---------------------------------------------

* subroutine to get input byte and store in D1

* simulation
getChar move.l  d0,-(sp)

        * check if in simulation or hardware mode
        move.b  #sim,d0
        cmp.b   #0,d0           ; if equals 0, branch to hardware getChar
        beq     getCharH

        move.l  #5,d0           ; task to read single character into D1.B
        trap    #15

getCharR move.l  (sp)+,d0
        rts

* hardware
getCharH MOVEm.L D0/a0,-(SP)       ; store on stack
        LEA     DUART, A0
IN_POLL MOVE.B  SRA(A0),D1      * Get input
        BTST    #RxRDY, D1      * Check if input is null
        BEQ     IN_POLL         * If not, get next input           
CLEAR_BUF MOVE.B RBA(A0),D1 
        MOVE.B  SRA(A0),D0      * Get input
        BTST    #RxRDY, D0      * Check if buffer is empty
        BNE     CLEAR_BUF                      
        JSR     putChar        * Display what you get everytime
        MOVEm.L  (SP)+,D0/a0
        bra     getCharR


* subroutine to output byte in D1

* simulation
putChar move.l  d0,-(sp)        ; store (push) D0 on stack

        * check if in simulation or hardware mode
        move.b  #sim,d0
        cmp.b   #0,d0           ; if equals 0, branch to hardware putChar
        beq     putCharH

        move.l  #6,d0           ; task to display single character in D1.B
        trap    #15
                
putCharR move.l  (sp)+,d0        ; restore (pop) D0 from stack
        rts

* hardware
putCharH MOVem.l D2/a0,-(SP)       * Push registers modified
        LEA     DUART, A0
OUT_POLL MOVE.B SRA(A0),D2
        BTST    #TxRDY, D2
        BEQ     OUT_POLL
        MOVE.B  D1,TBA(A0)
        MOVEm.l  (SP)+, D2/a0       * Pull registers modified
        bra     putCharR


* print null-terminated string starting at A1
printStr move.l  d1,-(sp)

.loop   move.b  (a1)+,d1        ; store byte at A1 in D1 to be displayed (then increment A1)
        
        jsr     putChar

        cmp.b   #0,d1
        bne     .loop           ; if haven't reached end of string, keep printing characters
        
        move.l  (sp)+,d1
        rts


* subroutine to get and convert nibble from ASCII (0-9, A-F, a-f) to hexadecimal, input from D1, output to D1
inN     jsr     getChar         ; get one byte from user (1 ASCII byte represents a nibble, 4 bits)

        cmp.b   #$30,d1         ; check $30-39 first, ASCII of 0-9  
        blt     menuLoop
        cmp.b   #$39,d1
        bgt     .upAtoF

        sub.b   #$30,d1         ; subtract $30 from D1 to convert to hexadecimal
        rts

.upAtoF cmp.b   #$41,d1        ; check $41 to $46, ASCII of A-F
        blt     menuLoop
        cmp.b   #$46,d1         ; if greater than $46 (F), branch to subroutine for evaluating ascii a-f
        bgt     .lowAtoF

        sub.b   #$37,d1         ; subtract $37 from D1 to convert to hexadecimal
        rts

.lowAtoF cmp.b #$61,d1       ; check $61-66, ASCII of a-f
        blt     menuLoop
        cmp.b   #$66,d1
        bgt     menuLoop

        sub.b   #$57,d1         ; subtract $57 from D1 to convert to hexadecimal
        rts


* subroutine to get and convert byte from ASCII to hex, input D1, output D1
inB     movem.l  d1,-(sp)

        jsr     inN             ; convert nibble from ASCII to hex
        move.b  d1,d2           ; move nibble from D1 to D2
        lsl.b   #4,d2           ; logical shift D2 left by 1 nibble

        jsr     inN
        or.b    d1,d2           ; OR nibble from D1 with nibble from D2

        movem.l  (sp)+,d1
        rts


* subroutine to get and convert word from ASCII to hex, input D1, output D1
inW     jsr     inB             ; get byte
        lsl.w   #8,d2

        jsr     inB
        rts


* subroutine to get and convert 24-bit address from ASCII to hex, input D1, output D1
inA     jsr     inB
        swap    d2

        jsr     inW
        rts


* subroutine to get and convert longword from ASCII to hex, input D1, output D1
inL     jsr     inW
        swap    d2              ; swap 16 bit (word) halves of D2

        jsr     inW
        rts


* subroutine to get and convert nibble from hex to ascii (0-9, A-F), input from D1, output to D1
outN    cmp.b   #$9,d1
        bgt     .upAtoF

        add.b   #$30,d1

        jsr     putChar
        rts


.upAtoF cmp.b   #$f,d1
        bgt     menuLoop

        add.b   #$37,d1

        jsr     putChar
        rts


* subroutine to get and convert byte from hex to ascii, input D2 (don't change it)
outB    movem.l  d1-d3,-(sp)

        move.b  d2,d3
        rol.b   #4,d3
        move.b  d3,d1
        and.b   #$0f,d1         ; put D2 MSB in D1 LSB, using D3
        
        jsr     outN

        rol.b   #4,d3
        move.b  d3,d1
        and.b   #$0f,d1
        
        jsr     outN

        movem.l  (sp)+,d1-d3
        rts


* subroutine to get and convert word from hex to ascii, input D2 (don't change it)
outW    movem.l  d2,-(sp)

        rol.w   #8,d2
        jsr     outB
        
        rol.w   #8,d2
        jsr     outB

        movem.l  (sp)+,d2
        rts


* subroutine to get and convert longword from hex to ascii, input D2 (don't change it)
outL    movem.l  d2,-(sp)

        swap    d2
        jsr     outW
        
        swap    d2
        jsr     outW

        movem.l (sp)+,d2
        rts


* VARIABLES -----------------------------------------------


rom     equ     $000000
ram     equ     $010000
duart   equ     $020000

sRecLoc equ     $015000
stack   equ     $018000

MR1A   	EQU   	1	; Mode Register1
MR2A  	EQU   	1	; points here after MR1A is set
SRA    	EQU   	3       ; Status Register (read)
CSRA   	EQU   	3       ; Clock Select Register
CRA   	EQU   	5	; Command Register
TBA	EQU   	7       ; Transfer Holding Register
RBA	EQU   	7	; Receive Holding Register
ACR	EQU     9	; Auxiliary control register
RxRDY	EQU	0	; Recieve ready bit position
TxRDY	EQU	2	; Transmit ready bit position
BAUD	EQU	$CC     ; baud rate value = 19,200 baud

* carriage return, line feed, single quotation mark
cr      equ     $0d
lf      equ     $0a
sqm     equ     $27

crlf    dc.b    cr,lf,0

intro   dc.b    'Welcome to Joe',sqm,'s Crab Shack! (\/)!_!(\/)',cr,lf,0

menu    dc.b    cr,lf,cr,lf,'Joe',sqm,'s Menu:',cr,lf
        dc.b    '1. Read from memory',cr,lf
        dc.b    '2. Write to memory',cr,lf
        dc.b    '3. Read from a register',cr,lf
        dc.b    '4. Write to a register',cr,lf
        dc.b    '5. Load S-record',cr,lf
        dc.b    '6. Run S-record',cr,lf,cr,lf
        dc.b    'Please choose an option: ',0


readMemMsg dc.b cr,lf,cr,lf,'1. Read from memory',cr,lf
        dc.b 'Enter memory location to read from (010000-01FFFF): ',0

readMemMsg2 dc.b cr,lf,cr,lf,'Contents: ',0


writeMemMsg dc.b cr,lf,cr,lf,'2. Write to memory',cr,lf
        dc.b 'Enter memory location to write to (010000-01FFFF): ',0

writeMemMsg2 dc.b cr,lf,'Enter longword to write (00000000-FFFFFFFF): ',0

writeMemMsg3 dc.b cr,lf,cr,lf,'Data written successfully',cr,lf,0


readRegMsg dc.b cr,lf,cr,lf,'3. Read from a register',cr,lf
        dc.b 'Enter register to read from (D0-D7, A0-A7): ',0

readRegMsg2 dc.b cr,lf,cr,lf,'Contents: ',0


writeRegMsg dc.b cr,lf,cr,lf,'4. Write to a register',cr,lf
        dc.b 'Enter register to write to (D0-D7, A0-A6): ',0

writeRegMsg2 dc.b cr,lf,'Enter longword to write (00000000-FFFFFFFF): ',0

writeRegMsg3 dc.b cr,lf,cr,lf,'Data written successfully',cr,lf,0


loadSRecMsg dc.b cr,lf,cr,lf,'5. Load S-record',cr,lf
        dc.b    'Enter S-record: ',cr,lf,0

loadSRecMsg2 dc.b cr,lf,cr,lf,'S-record written successfully',cr,lf,0

        end    start        ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
