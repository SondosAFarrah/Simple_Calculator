
	PROCESSOR 16F877A
	INCLUDE "P16F877A.INC"	

	__CONFIG 0x3731

TimerY EQU 0x20 
Char EQU 0x25
CharZ EQU 0x26
DELAY_COUNT equ 800000
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
	BCF STATUS,Z
	BANKSEL TRISB 
	BSF TRISB, 0 ;Sets TRISB0 as an input.
	
	BANKSEL INTCON
	BSF INTCON, GIE
	BSF INTCON, INTE
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
	
	MOVLW b'00000000' ; to make D output
	MOVWF TRISD

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
	BANKSEL INTCON
	BSF INTCON,GIE
	BSF INTCON,PEIE
	

	GOTO start

; When intruput happend the program will enter here
ISR:
	BANKSEL INTCON
	BCF INTCON, INTE
	BCF INTCON, INTF
	;DECF Char
	INCF Char
	MOVFW Char
	CALL send
	MOVFW Char
	MOVWF TXREG
	CALL TRANSMIT
BACK:
	BANKSEL INTCON
	BSF INTCON, INTE
	BSF INTCON, GIE
	BANKSEL PIE1
	BCF PIE1,2
	retfie



;INCLUDE "LCDIS_PORTD.INC" ; IF U WANT TO USE LCD ON PORT D
;INCLUDE "LCDIS_PORTA.INC" ; IF U WANT TO USE LCD ON PORT A
	INCLUDE "LCDIS.INC" 
; The main code for our program
start:

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



	;CALL RXCHECK

loop: 
	CALL xms
	CALL xms
	CALL xms
	CALL xms
	GOTO loop



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
	MOVLW 0x81
	CALL send
	RETURN
	





	END

