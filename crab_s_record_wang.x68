*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
	ORG	$015000

start2
	* print starting crab
	movem.l d0-d3/a1,-(sp)
	lea     crab,a1
	bsr	printStr

	* starting delay
	move.l	#$f0000,d2

.delayLoop sub.l	#1,d2
	cmp.l	#0,d2
	bne	.delayLoop

	* shift crab many times
	move.b	#50,d2

.shiftLoop lea     shiftCrab,a1
	bsr	printStr

	* short delay
	move.w	#$2000,d3

.delayLoop2	sub.w	#1,d3
	cmp.w	#0,d3
	bne	.delayLoop2

	sub.b	#1,d2
	cmp.b	#0,d2
	bne	.shiftLoop

	* print end message
	lea     dest,a1
	bsr	printStr

	movem.l  (sp)+,d0-d3/a1
	
	rts
	*simhalt

* print null-terminated string starting at A1
printStr move.l  d1,-(sp)

.loop   move.b  (a1)+,d1        ; store byte at A1 in D1 to be displayed (then increment A1)
        
        jsr     putCharH

        cmp.b   #0,d1
        bne     .loop           ; if haven't reached end of string, keep printing characters
        
        move.l  (sp)+,d1
        rts

* subroutine to output byte in D1
putCharH MOVem.l D2/a0,-(SP)       * Push registers modified
        LEA     DUART, A0
OUT_POLL MOVE.B SRA(A0),D2
        BTST    #TxRDY, D2
        BEQ     OUT_POLL
        MOVE.B  D1,TBA(A0)
        MOVEm.l  (SP)+, D2/a0       * Pull registers modified
        rts

DUART   EQU	$020000 ; loaded in A0 when needed, regs are offsets
SRA    	EQU   	3       ; Status Register (read)
TBA	EQU   	7       ; Transfer Holding Register
TxRDY	EQU	2	; Transmit ready bit position


cr      equ     $0d
lf      equ     $0a

* backspace and space
bs	equ	$08
sp	equ	$20

sqm     equ     $27

crab	dc.b	cr,lf,cr,lf,cr,lf,cr,lf,'Bernie the Crab wants to go to Joe',sqm,'s Crab Shack',cr,lf,cr,lf
	dc.b	'                                                     ______',cr,lf
	dc.b	'                                                    /|JOES|\',cr,lf
	dc.b	'                                                     |____| ',cr,lf,cr,lf
	dc.b	'(\/)!_!(\/)',0

shiftCrab dc.b	bs,bs,bs,bs,bs,bs,bs,bs,bs,bs,bs,'.(\/)!_!(\/)',0

dest	dc.b	cr,lf,cr,lf,cr,lf,'Yay Bernie!!',0

	end	start2