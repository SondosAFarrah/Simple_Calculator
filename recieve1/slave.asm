
	PROCESSOR 16F877A
	INCLUDE "P16F877A.INC"	

	__CONFIG 0x3731


Char EQU 0x21
tensTemp EQU 0x22
tenTimes EQU 0x27
onesTimes EQU 0x28
reciveTurn EQU 0x29
onesTemp2 EQU 0x30
;NUM EQU 0x25

; The instructions should start from here
	ORG 0x00
	GOTO init


	ORG 0x04
	GOTO ISR


; The init for our program
init:
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
	GOTO RXCHECK
	RETURN

RECIVED:
	
	MOVF RCREG,0
	BTFSC reciveTurn,0
	GOTO secondNumCame
	BSF reciveTurn,0
	MOVWF tensTemp
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


ReturnFlag:
	
	BCF PIR1,5
	
	RETURN

	END