
	PROCESSOR 16F877A
	INCLUDE "P16F877A.INC"	

	__CONFIG 0x3731


Char EQU 0x21
tensTemp EQU 0x22
tenTimes EQU 0x27
onesTimes EQU 0x28
reciveTurn EQU 0x29
onesTemp2 EQU 0x30
CarryCount EQU 0x31
ResultH EQU 0x32
ResultL EQU 0x33
onesTempT EQU 0x34
Number1 EQU 0x35
CarryCount2 EQU 0x36
;NUM EQU 0x25

; The instructions should start from here
	ORG 0x00
	GOTO init


	ORG 0x04
	GOTO ISR


; The init for our program
init:
	CLRF Number1
	CLRF CarryCount
	CLRF CarryCount2
	CLRF onesTempT
	CLRF ResultH
	CLRF ResultL 
	CLRF reciveTurn
	CLRF onesTemp2
	CLRF tensTemp
	;CLRF onesTimes 
	;MOVLW D'9'
	CLRF tenTimes
	BANKSEL TRISD
	CLRF TRISD
	
	BANKSEL PORTD
	CALL inid
	CALL xms
	CALL xms

	BCF STATUS,6
	BSF STATUS,5

	BCF TRISC,6
	BSF TRISC,7


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
	
	BSF INTCON,7
	BSF INTCON,6 


	BCF STATUS,6
	BCF STATUS,5

	BCF PIR1,5
	
	GOTO start

; When intruput happend the program will enter here
ISR:
	BANKSEL INTCON
	BCF INTCON, INTE
	BCF INTCON, INTF
	;DECF Char
;	INCF Char
;	CALL sayHi
	; TASK

	; END TASK
	
;	BANKSEL INTCON
;	BSF INTCON, INTE
;	BANKSEL PORTD
BACK:
	BANKSEL INTCON
	BSF INTCON, INTE
	BSF INTCON, GIE
;	BANKSEL PORTD
;	GOTO loop	


	retfie


;INCLUDE "LCDIS_PORTD.INC" ; IF U WANT TO USE LCD ON PORT D
;INCLUDE "LCDIS_PORTA.INC" ; IF U WANT TO USE LCD ON PORT A
	INCLUDE "LCDIS.INC" 
; The main code for our program
start:

	CALL RXCHECK

loop: 
	CALL xms
	CALL xms
	CALL xms
	CALL xms
	GOTO loop



RXCHECK:
	BTFSC PIR1,5
	CALL RECIVED
	BTFSC reciveTurn,1
	GOTO Mul
	GOTO RXCHECK
	RETURN
TRANSMIT:
	BTFSS PIR1,4
	GOTO TRANSMIT
	RETURN

RECIVED:
	MOVF RCREG,0
	BTFSC reciveTurn,0
	GOTO secondNumCame
	BSF reciveTurn,0
;	MOVWF Number1 ; we store the value to multiplicate.
;	MOVFW Number1
	MOVWF tensTemp ; this just to separate to review in the LCD
	BCF STATUS,Z
num1Separate:
	MOVLW D'10'
	SUBWF tensTemp ; adpin
	INCF tenTimes  ; tens
	BTFSC STATUS,C ; status
	GOTO num1Separate  ; goto 
	ADDWF tensTemp ; adpin
	DECF tenTimes ; tens
	MOVFW tensTemp ;,W ; adpin
	MOVWF onesTimes ; ones
	BSF Select,RS ;;9
	MOVFW tenTimes
	ADDLW D'48'
	CALL send
	BSF Select,RS
	MOVFW onesTimes
	ADDLW D'48'
	CALL send
	GOTO ReturnFlag
	

	;----- second number came : 
secondNumCame:
	MOVWF onesTemp2
	BSF Select,RS 
	MOVFW onesTemp2
	ADDLW D'48'
	CALL send 	
	BSF reciveTurn,1



ReturnFlag:
	
	BCF PIR1,5
	
	RETURN

;------------ Multiplication -----------------;

Mul: 
	MOVFW onesTemp2
	MOVWF onesTempT
	BCF STATUS,Z
	;DECF onesTemp2 ; for the multiply the ones - units -
	;DECF onesTempT
; first we will multiply the num1 ones by the num2 ones
; and store the carry, then we will make the high 4 bits zeros 
; to make it one digit ( in the least sig. reg) 
	MOVLW D'0'
	XORWF onesTimes,W
	BTFSC STATUS, Z ; Check if Z flag is set (result is zero)
    GOTO  digitIsZero   ; If not zero, jump to notEqual
	
	MOVFW onesTimes
	CLRF onesTimes
;	MOVFW onesTempT
MulLoop:
	ADDWF onesTimes,F
	DECFSZ onesTempT;20
	GOTO MulLoop
	MOVFW onesTimes
	;MOVWF ResultL
CARRYLOOP
	MOVLW D'10'
	SUBWF onesTimes,F;10
	BTFSS STATUS,C
	GOTO DIGIT
	INCF CarryCount
	GOTO CARRYLOOP
DIGIT
;TO REMOVE -ONETIMES
	MOVFW onesTimes
	ADDLW D'10'
	MOVWF onesTimes
	MOVFW onesTimes
	MOVWF ResultL
	goto tenLoop
	

;--- if the ones digit of the first number is zero the mul result
;--- for the LOW SIG. REG will be zero without doing the mul.
digitIsZero:
	CLRF onesTimes
	CLRF CarryCount
	;GOTO numTensMul


;-- we must make it go to the tens* 2nd number one.
tenLoop
	CLRF ResultH
	MOVFW tenTimes
	;ADDWF ResultH,F
	
MulLoopTen:
	MOVFW tenTimes
	ADDWF ResultH,F
	MOVFW ResultH
	;BSF Select, RS
	;ADDLW D'48'
	;CALL send
	DECFSZ onesTemp2,F
	GOTO MulLoopTen
	MOVFW CarryCount
	ADDWF ResultH,F
;	MOVFW ResultH
	;BSF Select, RS
;	ADDLW D'48'
;	CALL send
	;GOTO loop
	GOTO SEP


PRINT
	BSF Select,RS
	MOVFW ResultL ;ONES
	MOVWF TXREG
	CALL TRANSMIT
	MOVFW ResultL
	ADDLW D'48'
	CALL send
	MOVFW CarryCount;Carry
	ADDLW D'48'
	CALL send



	return


;------------------------------------------------	
SEP
	CLRF tenTimes
	CLRF onesTimes
	CLRF tensTemp
	
	
	BCF STATUS,C
	CALL xms
	CALL xms
	CALL xms
	CALL xms
	CALL xms
	CALL xms
	MOVFW ResultH
	MOVWF TXREG
	CALL TRANSMIT
	MOVFW ResultH
	BSF Select , RS
	ADDLW D'48'
	CALL send
	;GOTO loop
	MOVFW ResultH
	MOVWF tensTemp
	BSF STATUS,C
num1Separate2:
	MOVLW D'10'
	SUBWF tensTemp
	INCF tenTimes  
	BTFSC STATUS,C 
	GOTO num1Separate2 
	ADDWF tensTemp 
	DECF tenTimes 
	MOVFW tensTemp 
	MOVWF onesTimes
	BSF Select,RS 
	MOVLW '='
	CALL send
	MOVFW tenTimes ;HUNS
	ADDLW D'48'
	CALL send
	BSF Select,RS
	MOVFW onesTimes;TENS
	ADDLW D'48'
	CALL send
	CALL PRINT



	GOTO loop33

loop33:

	GOTO loop33





	END