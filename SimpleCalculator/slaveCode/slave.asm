
;--------------------------------------------------------------------------------------;
;	  Sample Calculator                  Authors                   Instructor
;        15/2/2024                Sondos Farrah 1200905         Dr. Hanna Bullata
;     Birzeit University        Mohammad Makhamreh 1200227        
;	  Code2: Co-Proccesor CPU	 Jana Abu Nasser 1201110         
;--------------------------------------------------------------------------------------;

	PROCESSOR 16F877A
	INCLUDE "P16F877A.INC"	; including the PIC library to make it easy of calling the Reg by names.

	__CONFIG 0x3731

; ----------------------------- Define the used registers for our purposes -------------;
tensTemp EQU 0x22
tenTimes EQU 0x27
onesTimes EQU 0x28
reciveTurn EQU 0x29 ; to see the recived shoot turn from the pic1.
onesTemp2 EQU 0x30
CarryCount EQU 0x31 ; to save the carry. in multiple operations.
ResultH EQU 0x32
ResultL EQU 0x33
onesTempT EQU 0x34
Number1 EQU 0x35
CarryCount2 EQU 0x36 ; to save the carry2. in multiple operations.


; The instructions should start from here
	ORG 0x00
	GOTO init


;	ORG 0x04
;	GOTO ISR


; The init for our program, to set the initial configurations.
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
	CLRF tenTimes
	BANKSEL TRISD
	CLRF TRISD ;Sets TRISD as an output (LCD)
	
	BANKSEL PORTD ; Bank0, PortD 
	CALL inid ; the initial configuration of the LCD.
	CALL xms
	CALL xms
; ------------- This is for the RX/TX configuration (commmunication between pics --------------------;	
	BCF STATUS,6
	BSF STATUS,5 ; 01: Bank1.

	BCF TRISC,6 ; seting TX (BC6) output for transmiting.
	BSF TRISC,7 ; seting RX (BC7) output for transmiting.

	MOVLW b'00100000' 
	;bit7=0: clock from External Source.
	;bit6=0: select 8 bit transmition
	;bit5=1: transmit Enable.
	;bit4=0: Asyc. Mode.
	MOVWF TXSTA
	
	BCF STATUS,6
	BCF STATUS,5 ; 00 Bank0
	
	MOVLW b'10010000'
	;bit7=1: Serial Port Enable

	;bit6=0: 8 bit mode.
	;bit4=1: Enable continuous recive.
	MOVWF RCSTA
	
	BCF STATUS,6
	BSF STATUS,5 ; 01: Bank1.
	MOVLW d'6' ;to make BAUD Rate 9600 for Fosc = 4MHz 
	MOVWF SPBRG
; -------------- The end of RX/TX configuration ------------------------------------------;
;	BSF INTCON,7
;	BSF INTCON,6 
	BCF STATUS,6
	BCF STATUS,5
	BCF PIR1,5
	GOTO start

; When intruput happend the program will enter here
;ISR:
;	BANKSEL INTCON
;	BCF INTCON, INTE
;	BCF INTCON, INTF
;BACK:
;	BANKSEL INTCON
;	BSF INTCON, INTE
;	BSF INTCON, GIE

;	retfie

	INCLUDE "LCDIS.INC" 
; The main code for our progra
start:

	CALL RXCHECK ; the program will stay waiting in this function until he recive data.

loop: ; loop will not enterd, it was for testing lines.
	CALL xms
	CALL xms
	CALL xms
	CALL xms
	GOTO loop



RXCHECK: ; to check if there is data coming from the PIC1.
	BTFSC PIR1,5 ; check if the USART recive buffer is empty
	CALL RECIVED ; if there is data coming then go to recived to read it and store it.
	BTFSC reciveTurn,1 ; to check if the PIC recived 2 times the most sign. shoot and the least.
	GOTO Mul ; to check if the PIC recived 2 times: the num1 and num2 ones sign. then go multiply them.
	GOTO RXCHECK ; to check if the PIC recived 2 times the most sign. shoot and the least.
	RETURN
TRANSMIT:
	BTFSS PIR1,4
	GOTO TRANSMIT
	RETURN

RECIVED: 
	MOVF RCREG,0 ; Move the recived value from PIC1, 0: means mov it to the W register.
	BTFSC reciveTurn,0 ;check if the recived is the num1 (first shoot).
	GOTO secondNumCame ; if the recived is the num2 ones digit.
	BSF reciveTurn,0 ; if the recived is the num1. then make this flag1 to recive the num2 ones
	MOVWF tensTemp ; this just to separate to review in the LCD
	BCF STATUS,Z
num1Separate: ; separate the num1 into tens and ones to multiply it.
	MOVLW D'10'
	SUBWF tensTemp 
	INCF tenTimes  
	BTFSC STATUS,C 
	GOTO num1Separate  
	ADDWF tensTemp 
	DECF tenTimes 
	MOVFW tensTemp 
	MOVWF onesTimes 
	BSF Select,RS 
	MOVFW tenTimes
	ADDLW D'48' ; add the ascii to the ten digit of number1 to print it on the lcd.
	CALL send
	BSF Select,RS
	MOVFW onesTimes
	ADDLW D'48' ; add the ascii to the ones digit of number1 to print it on the lcd.
	CALL send
	MOVLW 'x' ; print x sign.
	CALL send
	GOTO ReturnFlag
	

	;----- second number came : 
secondNumCame:
	MOVWF onesTemp2
	BSF Select,RS 
	MOVFW onesTemp2
	ADDLW D'48' ; add the ascii to print it on the lcd.
	CALL send 	
	BSF reciveTurn,1 ; set this flag to tell that we recived all we need. go to multiply.

ReturnFlag: 
	BCF PIR1,5
	
	RETURN

;------------ Multiplication -----------------;

Mul: 
	MOVFW onesTemp2
	MOVWF onesTempT
	BCF STATUS,Z

; first we will multiply the num1 ones by the num2 ones
; and store the carry, then we will make the high 4 bits zeros 
; to make it one digit ( in the least sig. reg) 
	MOVLW D'31'
	XORWF onesTimes,W
	BTFSC STATUS, Z ; Check if Z flag is set (result is zero)
    GOTO  digitIsZero   ; If not zero, jump to notEqual
	
	MOVFW onesTimes
	CLRF onesTimes

MulLoop: ; start the multiplication, starting by multiply num1 ones digit by num2 ones digit.
	ADDWF onesTimes,F
	DECFSZ onesTempT;20
	GOTO MulLoop
	MOVFW onesTimes
	
CARRYLOOP ; this to extract the carry if there is carry.
	MOVLW D'10'
	SUBWF onesTimes,F
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
	MOVWF ResultL ; the final ones digit of PIC2 stored here.
	goto tenLoop
	

;--- if the ones digit of the first number is zero the mul result
;--- for the LOW SIG. REG will be zero without doing the mul.
digitIsZero:
	CLRF onesTimes
	CLRF CarryCount



;-- we must make it go to the tens* 2nd number one.
tenLoop
	CLRF ResultH
	MOVFW tenTimes

	
MulLoopTen:
	MOVFW tenTimes
	ADDWF ResultH,F
	MOVFW ResultH
	DECFSZ onesTemp2,F
	GOTO MulLoopTen
	MOVFW CarryCount
	ADDWF ResultH,F
	GOTO SEP ; go to separate it to print it on the lcd to check if the result corret.


PRINT ; this will print the ones digit, since the hundred and tens will be printed below in the separate function. 
	BSF Select,RS
	MOVFW ResultL ;ONES
	MOVWF TXREG ; here the ones digit of the mull (second shoot) will be sent to the PIC1
	CALL TRANSMIT
	MOVFW ResultL ; here will be printed to the lcd.
	ADDLW D'48'
	CALL send
	CALL xms
	CALL xms
	CALL xms
	CALL xms
	CALL xms 
	CALL xms
	GOTO init ; the result of mul PIC2 will be printed for some time and the pic will
			  ; start to configure its registers and clear the lcd to be ready for another operation.



	return


;------------------------------------------------	
SEP ; separating the Most Signeficant 2 bits to print them on the lcd.
	CLRF tenTimes
	CLRF onesTimes
	CLRF tensTemp
	BCF STATUS,C
	MOVFW ResultH ; most 2 sig. bits of mul result.
	MOVWF TXREG ; here the first shoot that contains the result 2 most sign. bits will be sent to the PIC2
	CALL TRANSMIT
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
;---------------------------- The END of the Co-Processor of Simple Calculator ----------------------

	END