$NOMOD51
$INCLUDE (8051.MCU)

;====================================================================
; DEFINITIONS
;====================================================================
	org 500H
	TBL:    DB 0C0H,0F9H,0A4H,0B0H,99H,92H,82H,0F8H,80H,90H    ;7seg data for comm. anode type
	org 600H		; KEYPAD
	KCODE0:	DB	0FFH, 01H, 02H, 03H		
	KCODE1:	DB	0FFH, 04H, 05H, 06H
	KCODE2:	DB	0FFH, 07H, 08H, 09H
	KCODE3:	DB	0FFH, 0AH, 00H, 0BH	
;====================================================================
; VARIABLES
;====================================================================

red equ 40H
yellow equ 43H
green equ 46H
key1 equ 50H
key2 equ 51H
number1 equ R0
number2 equ R1
count equ R2
mode equ R3
start_pause equ R4

KEYPAD_PORT	equ	P2
;====================================================================
; RESET and INTERRUPT VECTORS
;====================================================================

      ; Reset Vector
      org   0000h
      jmp   Start
	
	org 000BH
	ljmp TIMER0_ISR		; Interrupt Service Routine for Interrupt  Timer0
	org 0003H
	ljmp INT0_ISR			; Interrupt Service Routine for Interrupt 0
	org 0013H
	ljmp INT1_IST
;====================================================================
; CODE SEGMENT
;====================================================================

      org   0100h
Start:	
	mov P0, #0FFH

	mov DPTR, #TBL	
	clr A

	mov red, #14
	mov yellow, #2
	mov A, red
	subb A, yellow
	mov green, A

	mov number1, red
	mov number2, green
	mov mode, #0
	mov count, #20
	mov start_pause, #0

	mov TMOD,  #01H
	mov TH0, #3CH
	mov TL0, #0B0H
	clr TF0
	setb TR0
	mov IE, #87H	

	clr P0.0
	clr P0.5

Loop:

	mov A, number1
	mov B, #10
	div AB
	mov 41H, A
	mov 42H, B

	clr P3.4
	clr P3.5
	mov A, 41H
	movc A, @A+DPTR
	mov P1, A
	acall DELAY
	mov A, 42H
	movc A, @A+DPTR
	setb P3.4
	clr P3.5
	mov P1, A
	acall DELAY

	mov A, number2
	mov B, #10
	div AB
	mov 44H, A
	mov 45H, B

	clr P3.4
	setb P3.5
	mov A, 44H
	movc A, @A+DPTR
	mov P1, A
	acall DELAY
	setb P3.4
	setb P3.5
	mov A, 45H
	movc A, @A+DPTR
	mov P1, A
	acall DELAY

	ljmp Loop

; Change light
;**************RED_GREEN
RED_GREEN:
	cjne number2, #0, N1
	mov number2, yellow
	mov mode, #1
	setb P0.0
	setb P0.5
	clr P0.5
	clr P0.1
N1:
	ret
;**************RED_YELLOW
RED_YELLOW:
	cjne number1, #0, N2
	mov number1, green
N2:
	cjne number2, #0, N3
	mov number2, red
	mov mode, #2
	setb P0.5
	setb P0.1
	clr P0.3
	clr P0.2
N3:
	ret
;**************GREEN_RED
GREEN_RED:
	cjne number1, #0D, N4
	mov number1, yellow
	mov mode, #3
	setb P0.3
	setb P0.2
	clr P0.4
	clr P0.2
N4:
	ret
;**************YELLOW_RED
YELLOW_RED:
	cjne number1, #0, N5
	mov number1, red
N5:
	cjne number2, #0D, N6
	mov number2, green
	mov mode, #0
	setb P0.4
	setb P0.2
	clr P0.0
	clr P0.5
N6:
	ret
;**************DELAY
DELAY:  mov R6,#5
H2:	mov R7,#0FFH
H1:	djnz R7,H1
        djnz R6,H2
        ret
;**************TIMER0_ISR
TIMER0_ISR:
	mov TH0, #3CH
	mov TL0, #0B0H

	djnz count, break_timer0
	dec number1
	dec number2
	cjne mode, #0, O1
	acall RED_GREEN
	acall break_timer0
O1:
	cjne mode, #1, O2
	acall RED_YELLOW
	acall break_timer0
O2:
	cjne mode, #2, O3
	acall GREEN_RED
	acall break_timer0
O3:
	cjne mode, #3, O4
	acall YELLOW_RED
	acall break_timer0
O4:
	mov count, #20

	break_timer0:
	reti
;**************INT0_ISR
INT0_ISR:
	jnb P3.2, $
	cpl TR0
	clr TF0
	reti
;**************INT1_IST
INT1_IST:
	jnb P3.3, $
	mov count, #0
	mov P1, #0FFH

KEYSCAN:	clr P0.0
	mov	KEYPAD_PORT,  #00001111B
	mov	A, KEYPAD_PORT
	cjne	A, #00001111B, KEYSCAN

K2:	
	acall	DELAY		
	mov	A, KEYPAD_PORT
	cjne	A, #00001111B, OVER
	sjmp	K2

OVER:	
	acall	DELAY
	mov	A, KEYPAD_PORT
	cjne	A, #00001111B, OVER1
	sjmp	K2

OVER1:	
	mov	KEYPAD_PORT,  #11101111B
	mov	A, KEYPAD_PORT
	cjne	A, #11101111B, ROW_0

	mov	KEYPAD_PORT,  #11011111B
	mov	A,KEYPAD_PORT
	cjne	A, #11011111B,ROW_1

	mov	KEYPAD_PORT,  #10111111B
	mov	A,KEYPAD_PORT
	cjne	A, #10111111B,ROW_2

	mov	KEYPAD_PORT,  #01111111B
	mov	A,KEYPAD_PORT
	cjne	A, #01111111B,ROW_3
	sjmp	K2
	
ROW_0:	
	mov	DPTR, #KCODE0
	sjmp	FIND

ROW_1:	
	mov	DPTR, #KCODE1
	sjmp	FIND

ROW_2:	
	mov	DPTR, #KCODE2
	sjmp	FIND

ROW_3:	
	mov	DPTR, #KCODE3
	
FIND:	
	rrc	A
	jnc	MATCH
	inc	DPTR
	sjmp	FIND

MATCH:	
	clr	A
	movc	A,@A+DPTR

	cjne count, #0, XXX
	cjne A, #0BH, STORE_KEY1
	sjmp EXIT_INT1

STORE_KEY1:
	mov key1, A
	mov count, #1
	sjmp KEYSCAN

XXX:
	cjne A, #0BH, STORE_KEY2
	sjmp EXIT_INT1

STORE_KEY2:
	mov key2, A
	mov count, #0
	sjmp KEYSCAN

EXIT_INT1:
	cjne A, #0BH, KEYSCAN
	
	mov A, key1
	mov B, #10
	mul AB
	add A, key2

	mov red, A
	subb A, yellow
	mov green, A
	mov number1, red
	mov number2, green
	mov mode, #0
	mov count, #20
	mov start_pause, #0
	mov DPTR, #TBL
	reti
;************** END INT1_IST
;====================================================================
      END
