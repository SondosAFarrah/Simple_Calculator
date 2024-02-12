
	PROCESSOR 16F877A
	INCLUDE "P16F877A.INC"	

	__CONFIG 0x3731


Char EQU 0x28
;CharZ EQU 0x26



tensTemp EQU 0x26
onesTemp EQU 0x27 
numberOneTens EQU 0x21
numberOneOnes EQU 0x22
numberTwoTens EQU 0x23
numberTwoOnes EQU 0x24
twoSecFlag EQU 0x28 ; new 9999999999999999999999999999999999999999999999999
count EQU 0x25 

;NUM EQU 0x25

; The instructions should start from here
	ORG 0x00
	GOTO init


	ORG 0x04
	GOTO ISR

;    ORG 0x08 ; Additional interrupt vectors (if needed)
;	GOTO ISR2
; The init for our program
init:
	;MOVLW '1'
	;MOVWF tensTemp
	CLRF tensTemp 
	CLRF onesTemp 
	CLRF numberOneTens 
	CLRF numberOneOnes 
	CLRF numberTwoTens 
	CLRF numberTwoOnes 
	CLRF count 
	CLRF twoSecFlag ; new 99999999999999999999999999999999999999999999999999999
	
	;MOVLW D'100' ; 2 seconds with timer0 4MHz and pre-scale 1:64.
	;CLRF count
	;MOVWF count ; counter to the timer0.
	BCF STATUS,Z
	BANKSEL TRISB 
	BSF TRISB, 0 ;Sets TRISB0 as an input.
	
	BANKSEL INTCON
	BSF INTCON, GIE ; set Global interrupt
	;BSF INTCON, TMR0IE  ; set the Timer0 enable
;	BANKSEL OPTION_REG 
;	MOVLW b'00000101' ; pre-sclae 1:64 for timer0
;	MOVWF OPTION_REG ; store the previous vlaue in optreg.
;	BSF INTCON, INTE
	BANKSEL TRISD
	CLRF TRISD
	
	
	BANKSEL PORTD
	CALL inid
	CALL xms
	CALL xms
	
; ------------- This is for the RX/TX configuration (commmunication between pics --------------------;	
	BCF STATUS,6
	BSF STATUS,5
	
	BCF TRISC,6
	BSF TRISC,7
	
;	MOVLW b'00000000' ; to make D output
;	MOVWF TRISD

	MOVLW b'00100000'
	MOVWF TXSTA
	
	BCF STATUS,6
	BCF STATUS,5
	
	MOVLW b'10010000'
	MOVWF RCSTA
	
	BCF STATUS,6
	BSF STATUS,5
	MOVLW d'31'
	MOVWF SPBRG
; -------------- The end of RX/TX configuration ------------------------------------------;
;	BANKSEL INTCON
;	BSF INTCON,7
;	BSF INTCON,6
	BANKSEL PORTD ; go to bank 0 to make the lcd run.
	GOTO start

; When intruput happend the program will enter here
; The ISR will increment the count by 1 until to reach 100 for 2 seconds.
ISR:
	
	BANKSEL INTCON
	BCF INTCON, TMR0IF
	BCF INTCON, TMR0IE
	;BCF STATUS,Z ; -9999999999999999999999999999999999999999 new
	;DECF count
	INCF count
;	BTFSC STATUS,Z
;	BSF twoSecFlag,0
	BANKSEL PORTD
	;BSF Select,RS
	;MOVLW 'B'
	;CALL send
	
	;GOTO TEST

;------------ use them later in the button ---------------------------;
;;	INCF Char
;	MOVFW Char
;	CALL send
;	MOVFW Char
;	MOVWF TXREG
;	CALL TRANSMIT

BACK:
	BANKSEL TMR0
	CLRF TMR0
	BANKSEL INTCON
	BSF INTCON, TMR0IE
	BANKSEL PORTD
	;BSF INTCON, GIE
	;BCF INTCON,TMR0IF

	retfie



;INCLUDE "LCDIS_PORTD.INC" ; IF U WANT TO USE LCD ON PORT D
;INCLUDE "LCDIS_PORTA.INC" ; IF U WANT TO USE LCD ON PORT A
	INCLUDE "LCDIS.INC" 
; The main code for our program
start:
	BSF Select,RS
	MOVLW 'A'
	CALL send
	CALL welcomeString
	CALL xms
	CALL xms
	CALL xms
	CALL xms

	CALL welcomeString
;	MOVLW 0xff
	CALL xms
	CALL xms
	CALL xms
	CALL xms

	CALL welcomeString
	CALL xms
	CALL xms
	CALL xms
	CALL xms
	CALL xms

;Number1:	
	CALL Number1String
	BCF Select,RS
	MOVLW 0x0F
	CALL send 
	BSF Select,RS
Number1:
	;CALL inid
	BSF Select,RS
	MOVLW '1'
	CALL send
	MOVLW '1'
	MOVWF Char
	MOVFW Char
	MOVWF TXREG
	CALL TRANSMIT


	BANKSEL INTCON
	BSF INTCON, TMR0IE  ; set the Timer0 enable
	BANKSEL TMR0
	CLRF TMR0
	BANKSEL OPTION_REG 
	MOVLW b'00000101' ; pre-sclae 1:64 for timer0
	MOVWF OPTION_REG ; store the previous vlaue in optreg.
	BANKSEL PORTD

;loop11:
;	BTFSC STATUS,Z
;	GOTO PRINT
;	GOTO loop11

;PRINT:
;	BSF Select,RS
;	MOVLW '2'
;	CALL send
;	GOTO loop11

SetCursorNum1Tens:
	BCF Select,RS
	MOVLW 0xC0
	CALL send
	BSF Select,RS
ENTERNumber1Tens:
;	MOVLW D'0'
;	SUBLW count
;	BTFSC STATUS,Z
	BTFSC count,7
	GOTO SetCursorNum1Ones
	BTFSC PORTB,0
	GOTO ENTERNumber1Tens
	;CALL xms
	;CALL xms
	BTFSS PORTB,0
	GOTO ENTERNumber1Tens
	
INCREMENTTENS:
	CALL resetTimer0
	INCF tensTemp
	BSF Select,RS
;	MOVFW tensTemp
;	CALL send
;	GOTO loop
MAXNine:
	MOVFW tensTemp
	SUBLW D'9'
	BTFSS STATUS,C
	CLRF tensTemp

	BSF Select,RS
	MOVFW tensTemp
	ADDLW D'48'
	
	CALL send
	GOTO SetCursorNum1Tens


SetCursorNum1Ones:
	CLRF count
	BCF Select,RS
	MOVLW 0xC2
	CALL send 
	BSF Select,RS
	MOVLW 'Z'
	CALL send
	GOTO SetCursorNum1Ones
	;CALL RXCHECK

loop: 
	CALL xms
	CALL xms
	CALL xms
	CALL xms
	GOTO loop




; Routine for restarting the Timer0 

resetTimer0:
	BANKSEL TMR0
	CLRF TMR0
	CLRF count
;	MOVLW D'100'
;	MOVWF count
	BANKSEL INTCON
	BSF INTCON, TMR0IE
	BCF INTCON, TMR0IF
;	BSF INTCON, GIE	
	BANKSEL PORTD
	RETURN








;RXCHECK:
;	BTFSC PIR1,5
;	CALL RECIVED
;	GOTO RXCHECK
;	RETURN

RECIVED:
	MOVF RCREG,0
	MOVWF PORTD
	BCF PIR1,5
	RETURN

TRANSMIT:
	BTFSS PIR1,4
	GOTO TRANSMIT
	RETURN

TIMERINT:
	BANKSEL INTCON
	BCF INTCON, INTE
	BCF INTCON, INTF
	BSF Select,RS
	MOVLW 'H'
	CALL send
	BANKSEL PIR1
	BCF PIR1,2
	BANKSEL PIE1
	BCF PIE1,2

	GOTO BACK

welcomeString:
	CALL inid
	BSF Select,RS
	MOVLW 'W'
	CALL send
	MOVLW 'e'
	CALL send
	MOVLW 'l'
	CALL send
	MOVLW 'c'
	CALL send
	MOVLW 'o'
	CALL send
	MOVLW 'm'
	CALL send
	MOVLW 'e'
	CALL send
	MOVLW ' '
	CALL send
	MOVLW 't'
	CALL send
	MOVLW 'o'
	CALL send
	BCF Select,RS
	MOVLW 0xC0
	CALL send
	BSF Select,RS
	MOVLW 'M'
	CALL send
	MOVLW 'u'
	CALL send
	MOVLW 'l'
	CALL send
	MOVLW 't'
	CALL send
	MOVLW 'i'
	CALL send
	MOVLW 'p'
	CALL send
	MOVLW 'l'
	CALL send
	MOVLW 'i'
	CALL send 
	MOVLW 'c'
	CALL send 
	MOVLW 'a'
	CALL send
	MOVLW 't'
	CALL send
	MOVLW 'i'
	CALL send
	MOVLW 'o'
	CALL send 
	MOVLW 'n'
	CALL send 
	RETURN
Number1String:
	CALL inid
	BSF Select,RS
	MOVLW 'N'
	CALL send
	MOVLW 'u'
	CALL send
	MOVLW 'm'
	CALL send
	MOVLW 'b'
	CALL send
	MOVLW 'e'
	CALL send
	MOVLW 'r'
	CALL send
	MOVLW ' '
	CALL send
	MOVLW '1'
	CALL send
	BCF Select,RS
	MOVLW 0xC0
	CALL send
	RETURN
	





	END

