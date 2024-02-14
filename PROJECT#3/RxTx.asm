
	PROCESSOR 16F877A
	INCLUDE "P16F877A.INC"	

	__CONFIG 0x3731






Char EQU 0x21
tensTemp EQU 0x22
onesTemp EQU 0x23 
tensTemp2 EQU 0x24
onesTemp2 EQU 0x25 
count EQU 0x26 
tenTimes EQU 0x27
onesTimes EQU 0x28
RtensTemp EQU 0x29
RtensTemp2 EQU 0x30
CarryCount EQU 0x31
ResultL EQU 0x32
ResultH EQU 0x33
ReciveTurn EQU 0x34
ResultL2 EQU 0x35
ResultH2 EQU 0x36
THO EQU 0x37
HUN EQU 0x38



; The instructions should start from here
	ORG 0x00
	GOTO init


	ORG 0x04
	GOTO ISR


; The init for our program
init:
	CLRF RtensTemp
	CLRF tensTemp 
	CLRF onesTemp 
	CLRF tensTemp2 
	CLRF onesTemp2
	CLRF RtensTemp2
	CLRF CarryCount
	CLRF ResultL
	CLRF ResultH
	CLRF ResultL2
	CLRF ResultH2
	CLRF ReciveTurn
	CLRF THO
	CLRF HUN
	MOVLW D'9'
	MOVWF tenTimes 
	CLRF count 

	BCF STATUS,Z
	BANKSEL TRISB 
	BSF TRISB, 0 ;Sets TRISB0 as an input.
	
	BANKSEL INTCON
	BSF INTCON, GIE ; set Global interrupt

	BANKSEL TRISD
	CLRF TRISD;;Sets TRISD as an output.
	
	
	BANKSEL PORTD
	CALL inid
	CALL xms
	CALL xms
	
; ------------- This is for the RX/TX configuration (commmunication between pics --------------------;	
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
; -------------- The end of RX/TX configuration ------------------------------------------;

	BANKSEL PORTD ; go to bank 0 to make the lcd run.
	GOTO start

; When intruput happend the program will enter here
; The ISR will increment the count by 1 until to reach 100 for 2 seconds.
ISR:
	
	BANKSEL INTCON
	BCF INTCON, TMR0IF
	BCF INTCON, TMR0IE

	INCF count

	BANKSEL PORTD


BACK:
	BANKSEL TMR0
	CLRF TMR0
	BANKSEL INTCON
	BSF INTCON, TMR0IE
	BANKSEL PORTD


	retfie


	INCLUDE "LCDIS.INC" 
; The main code for our program
start:

	CALL welcomeString
	CALL xms
	CALL xms
	CALL xms
	CALL xms

	CALL welcomeString
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
BeginEntering
	CALL Number1String
	BCF Select,RS
	MOVLW 0x0F
	CALL send 
	BSF Select,RS
Number1:
	BSF Select,RS
	MOVLW '0'
	CALL send
	MOVLW '0'
	CALL send

	BANKSEL INTCON
	BSF INTCON, TMR0IE  ; set the Timer0 enable
	BANKSEL TMR0
	CLRF TMR0
	BANKSEL OPTION_REG 
	MOVLW b'00000101' ; pre-sclae 1:64 for timer0
	MOVWF OPTION_REG ; store the previous vlaue in optreg.
	BANKSEL PORTD

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
	MOVLW '0'
	CALL send
	MOVLW '0'
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

;-----------------------------------Concatination of Number 1------------------------;

Num1Concat:
	BCF STATUS,Z
	MOVFW tensTemp
	MOVWF RtensTemp
	MOVFW tensTemp
MulLoop:
	ADDWF tensTemp,F
	DECFSZ tenTimes
	GOTO MulLoop 
	; here the tens digit now multiplied by 10 and stored at the same register
; now we must add the ones to the result number: 

	MOVFW onesTemp
	ADDWF tensTemp

	MOVFW tensTemp;number1
	MOVWF TXREG
	CALL TRANSMIT
	MOVFW onesTemp2;ones for number 2
	MOVWF TXREG
	CALL TRANSMIT


;----------------------------MUL Number1 * Tens of number2------------------------
MullPIC1
	MOVFW tensTemp2
	MOVWF RtensTemp2
	BCF STATUS,Z
	MOVLW D'0'
	XORWF onesTemp,W
	BTFSC STATUS,Z
	GOTO DigitIsZero
	MOVFW onesTemp
	CLRF onesTemp
MullOnesLoop
	ADDWF onesTemp,F
	DECFSZ RtensTemp2
	GOTO MullOnesLoop
CarryLoop
	MOVLW D'10'
	SUBWF onesTemp
	BTFSS STATUS,C
	GOTO digitOnes
	INCF CarryCount
	GOTO CarryLoop
digitOnes
	;REMOVE -
	MOVFW onesTemp
	ADDLW D'10'
	MOVWF onesTemp
	MOVFW onesTemp
	MOVWF ResultL
	GOTO MullTenLoop

DigitIsZero
	CLRF ResultL
	CLRF CarryCount
MullTenLoop
	MOVFW RtensTemp
	ADDWF ResultH,F
	MOVFW ResultH

	DECFSZ tensTemp2
	GOTO MullTenLoop
	MOVFW CarryCount
	ADDWF ResultH,F

	CALL RXCHECK

	BSF Select,RS
	MOVFW ResultH
	ADDLW D'48'
	CALL send
	MOVFW ResultL
	ADDLW D'48'
	CALL send
	

; ---------- Function to separate the First Number into tens, and ones to preview it ---------;
SepNumber1H:
	BCF STATUS,Z
	CLRF tenTimes
	CLRF onesTimes
num1Separate:
	MOVLW D'10'
	SUBWF ResultH2
	INCF tenTimes
	BTFSC STATUS,C
	GOTO num1Separate 
	ADDWF ResultH2
	DECF tenTimes
	MOVF ResultH2,W
	MOVWF onesTimes

	GOTO backFromSep  

;------------tensTimes = tens for number2 high  , onesTimes = ones for number2 high


	GOTO loop


loop: 

	BTFSS PORTB,0
	GOTO newMUL
	GOTO loop




; Routine for restarting the Timer0 

resetTimer0:
	BANKSEL TMR0
	CLRF TMR0
	CLRF count
	BANKSEL INTCON
	BSF INTCON, TMR0IE
	BCF INTCON, TMR0IF
	BANKSEL PORTD
	RETURN

RXCHECK:
	BTFSC PIR1,5
	CALL RECIVED
	BTFSC ReciveTurn,1
	GOTO ADDITION
	GOTO RXCHECK
	RETURN

RECIVED:
	MOVF RCREG,0
	BTFSC ReciveTurn,0
	GOTO SecondNumCame
	BSF ReciveTurn,0
	MOVWF ResultH2
	BCF STATUS,Z
	GOTO SepNumber1H
backFromSep	
	GOTO ReturnFlag
SecondNumCame
	CLRF ResultL2
	MOVWF ResultL2
	BSF ReciveTurn,1

ReturnFlag
	BCF PIR1,5
	RETURN

ADDITION

	CLRF CarryCount
	MOVFW onesTimes
	ADDWF ResultL  ;FINAL TENS
	MOVFW tenTimes
	ADDWF ResultH,F ;FINAL THOUSAND AND HUNDS 
tenDigitWithoutCarry
	MOVLW D'10'
	SUBWF ResultL,F
	INCF CarryCount
	BTFSS STATUS,C
	GOTO DDIGIT
	GOTO tenDigitWithoutCarry

DDIGIT
	DECF CarryCount
	MOVFW CarryCount
	ADDWF ResultH
	MOVFW ResultL
	ADDLW D'10'
	MOVWF ResultL

	BCF STATUS,Z
THOUSAND:
	MOVLW D'10'
	INCF THO
	SUBWF ResultH
	BTFSC STATUS,C
	GOTO THOUSAND
	ADDWF ResultH
	DECF THO
	MOVFW ResultH
	MOVWF HUN

	GOTO PrintFinal 



PrintFinal
	BCF Select, RS
	MOVLW 0x80
	CALL send
	BSF Select, RS
	MOVLW 'R'
	CALL send
	MOVLW 'e'
	CALL send
	MOVLW 's'
	CALL send
	MOVLW 'u'
	CALL send
	MOVLW 'l'
	CALL send
	MOVLW 't'
	CALL send
	MOVLW ' '
	CALL send
	MOVLW ' '
	CALL send
	BCF Select, RS
	MOVLW 0xC6
	CALL send
	BSF Select,RS
	MOVFW THO ;FINAL THOUSAND 
	ADDLW D'48'
	CALL send
	MOVFW HUN ;FINAL HUN
	ADDLW D'48'
	CALL send
	MOVFW ResultL  ;FINAL TENS 
	ADDLW D'48'
	CALL send
	MOVFW ResultL2 ;final one
	ADDLW D'48'
	CALL send
	GOTO loop

	

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
	

newMUL
	CLRF RtensTemp
	CLRF tensTemp 
	CLRF onesTemp 
	CLRF tensTemp2 
	CLRF onesTemp2
	CLRF RtensTemp2
	CLRF CarryCount
	CLRF ResultL
	CLRF ResultH
	CLRF ResultL2
	CLRF ResultH2
	CLRF ReciveTurn
	CLRF THO
	CLRF HUN
	MOVLW D'9'
	MOVWF tenTimes 
	CLRF count 

	BCF STATUS,Z

	BANKSEL INTCON
	BSF INTCON, GIE ; set Global interrupt

	
	
	BANKSEL PORTD
	CALL inid
	
; ------------- This is for the RX/TX configuration (commmunication between pics --------------------;	
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
; -------------- The end of RX/TX configuration ------------------------------------------;

	BANKSEL PORTD ; go to bank 0 to make the lcd run.
	GOTO BeginEntering	



	END
