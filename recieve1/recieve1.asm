
	PROCESSOR 16F877A
	INCLUDE "P16F877A.INC"	

	__CONFIG 0x3731



;CharZ EQU 0x26


Char EQU 0x21
tensTemp EQU 0x22
onesTemp EQU 0x23 
tensTemp2 EQU 0x24
onesTemp2 EQU 0x25 
count EQU 0x26 
tenTimes EQU 0x27

onesTimes EQU 0x28


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
	CLRF tensTemp2 
	CLRF onesTemp2
	MOVLW D'9'
	MOVWF tenTimes 
;	CLRF numberOneTens 
;	CLRF numberOneOnes 
;	CLRF numberTwoTens 
;	CLRF numberTwoOnes 
	CLRF count 
;	CLRF twoSecFlag ; new 99999999999999999999999999999999999999999999999999999
	
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
;	BSF Select,RS
;	MOVLW 'A'
;	CALL send
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
	MOVLW '0'
	CALL send
	MOVLW '0'
	CALL send
	MOVLW 'x'
	CALL send
	MOVLW '0'
	CALL send
	MOVLW '0'
	CALL send

; --- testing RX/TX ---- ;
	;MOVLW '0'
	;MOVWF Char
	;MOVFW Char
	;MOVWF TXREG
	;CALL TRANSMIT


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


; -------------------------- Number 1 Turn ------------------------------;
SetCursorNum1Tens:
	BCF Select,RS
	MOVLW 0xC0
	CALL send
	BSF Select,RS
ENTERNumber1Tens:
	BTFSC count,7
	GOTO SetCursorNum1Ones
	BTFSC PORTB,0
	GOTO ENTERNumber1Tens
	CALL xms
	CALL xms
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
	CALL resetTimer0
	BCF Select,RS
	MOVLW 0xC1
	CALL send 
	BSF Select,RS
ENTERNumber1Ones:
	BTFSC count,7
	GOTO MulSign ; go to put the operation cuz it passed 2 seconds.
	BTFSC PORTB,0
	GOTO ENTERNumber1Ones
	CALL xms
	CALL xms
	BTFSS PORTB,0
	GOTO ENTERNumber1Ones
	
INCREMENTONES:
	CALL resetTimer0
	INCF onesTemp
	BSF Select,RS
;	MOVFW tensTemp
;	CALL send
;	GOTO loop
MAXNineOne:
	MOVFW onesTemp
	SUBLW D'9'
	BTFSS STATUS,C
	CLRF onesTemp

	BSF Select,RS
	MOVFW onesTemp
	ADDLW D'48'
	
	CALL send
	GOTO SetCursorNum1Ones

;------------------ MUL SIGN --------------------------------;

MulSign:
	CALL resetTimer0
	BCF Select,RS
	MOVLW 0xC2
	CALL send 
	BSF Select,RS
	MOVLW 'x'
	CALL send
	BCF Select,RS
	MOVLW 0x87
	CALL send
	BSF Select,RS
	MOVLW '2'
	CALL send
	BCF Select,RS
	MOVLW 0xC2
	CALL send
	GOTO SetCursorNum2Tens

; ------------- Second Number Turn ;--------------------------

SetCursorNum2Tens:
	CALL resetTimer0
	BCF Select,RS
	MOVLW 0xC3
	CALL send
	BSF Select,RS
ENTERNumber2Tens:
	BTFSC count,7
	GOTO SetCursorNum2Ones
	BTFSC PORTB,0
	GOTO ENTERNumber2Tens
	CALL xms
	CALL xms
	BTFSS PORTB,0
	GOTO ENTERNumber2Tens
	
INCREMENTTENS2:
	CALL resetTimer0
	INCF tensTemp2
	BSF Select,RS
;	MOVFW tensTemp
;	CALL send
;	GOTO loop
MAXNine2:
	MOVFW tensTemp2
	SUBLW D'9'
	BTFSS STATUS,C
	CLRF tensTemp2

	BSF Select,RS
	MOVFW tensTemp2
	ADDLW D'48'
	
	CALL send
	GOTO SetCursorNum2Tens


SetCursorNum2Ones:
	CALL resetTimer0
	BCF Select,RS
	MOVLW 0xC4
	CALL send 
	BSF Select,RS
ENTERNumber2Ones:
	BTFSC count,7
	GOTO  EqualSign ; go to put do the calculation process.
	BTFSC PORTB,0
	GOTO ENTERNumber2Ones
	CALL xms
	CALL xms
	BTFSS PORTB,0
	GOTO ENTERNumber2Ones
	
INCREMENTONES2:
	CALL resetTimer0
	INCF onesTemp2
	BSF Select,RS
;	MOVFW tensTemp
;	CALL send
;	GOTO loop
MAXNineOne2:
	MOVFW onesTemp2
	SUBLW D'9'
	BTFSS STATUS,C
	CLRF onesTemp2

	BSF Select,RS
	MOVFW onesTemp2
	ADDLW D'48'
	
	CALL send
	GOTO SetCursorNum2Ones


; ----------------- EQUAL SIGN -------------------------------;
EqualSign:
	CALL resetTimer0
	BCF Select,RS
	MOVLW 0xC5 
	CALL send
	BSF Select,RS
	MOVLW '='
	CALL send
	;GOTO EqualSign
;-----------------------------------Concatination of Number 1------------------------;

Num1Concat:
	BCF STATUS,Z
	MOVFW tensTemp
MulLoop:
	ADDWF tensTemp,F
	DECFSZ tenTimes
	GOTO MulLoop 
	; here the tens digit now multiplied by 10 and stored at the same register
; now we must add the ones to the result number: 

	MOVFW onesTemp
	ADDWF tensTemp
; SENDING THE FIRST NUMBER TO THE SECOND PIC -----:
	MOVFW tensTemp
	MOVWF TXREG
	CALL TRANSMIT
; SENDING THE Second NUMBER unit - ones -  TO THE SECOND PIC -----
	MOVFW onesTemp2
	MOVWF TXREG
	CALL TRANSMIT
;	MOVLW tensTemp
;	MOVWF TXREG
;	CALL TRANSMIT


;	GOTO Num1Concat

; ---------- Function to separate the First Number into tens, and ones to preview it ---------;
	BCF STATUS,Z
num1Separate:
	MOVLW D'10'
	SUBWF tensTemp
	INCF tenTimes
	BTFSC STATUS,C
	GOTO num1Separate 
	ADDWF tensTemp
	DECF tenTimes
	MOVF tensTemp,W
	MOVWF onesTimes
	BSF Select,RS
	MOVFW tenTimes
	ADDLW D'48'
	CALL send
	BSF Select,RS
	MOVFW onesTimes
	ADDLW D'48'
	CALL send
; 







;	MOVLW 'Z'
	
;	MOVFW tenTimes
;	ADDLW D'48'
;	MOVWF TXREG
;	CALL TRANSMIT


	;MOVLW tenTimes
	;MOVWF TXREG
	;CALL TRANSMIT
	;MOVLW onesTimes
	;MOVWF TXREG
	;CALL TRANSMIT

	


	GOTO loop




	;CALL RXCHECK

loop: 
	CALL resetTimer0
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

