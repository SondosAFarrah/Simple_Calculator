
;------------------------------------------------------------------------;
;	  Sample Calculator                  Authors                   Instructor
;        15/2/2024                Sondos Farrah 1200905         Dr. Hanna Bullata
;     Birzeit University        Mohammad Makhamreh 1200227        
;	  Code1: Master CPU	    	 Jana Abu Nasser 1201110         
;--------------------------------------------------------------------------------------

;Our Proccessor.
	PROCESSOR 16F877A
	INCLUDE "P16F877A.INC" ; including the PIC library to make it easy of calling the Reg by names.	

	__CONFIG 0x3731


; ----------------------------- Define the used registers for our purposes -------------
tensTemp EQU 0x22 ; to store the first number tens digit
onesTemp EQU 0x23 ; to store the first number ones digit
tensTemp2 EQU 0x24 ;to store the second number tens digit
onesTemp2 EQU 0x25 ;to store the second number ones digit
count EQU 0x26 ; to count the timer0 interrupts times.
tenTimes EQU 0x27 ; used to splitting a mumber to take the tens digit.
onesTimes EQU 0x28 ; used to splitting a mumber to take the ones digit.
RtensTemp EQU 0x29 ; used to make a copy of the value of tensTemp, because the orignal value will multiply by 10 to concatinate.
RtensTemp2 EQU 0x30 ; used to make a copy of the value of tensTemp2, to make a decrement on the copy.
CarryCount EQU 0x31 ; to save the carry. in multiple operations.
ResultL EQU 0x32 ; to store the result multiplication -tens- in the first PIC, then reused to store the Final Tens digit.
ResultH EQU 0x33 ; to store the result multiplication of num1 tens and num2 tens, then we add to it a carry if there is, and the tenTimes
ReciveTurn EQU 0x34 ; to see the recived shoot turn from the pic2.
ResultL2 EQU 0x35; to store the second shoot from the pic2 (least significant digit)
ResultH2 EQU 0x36; to store the first shoot from the pic2 (most significant digit)
THO EQU 0x37; to store the value of the final thousands digit.
HUN EQU 0x38; to store the value of the final hundreds digit.



; The instructions should start from here
	ORG 0x00
	GOTO init


	ORG 0x04
	GOTO ISR


; The init for our program, to set the initial configurations.
init:
	;------------- Clearing the Registers ----------------------
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
	CLRF TRISD;;Sets TRISD as an output (LCD)
	
	BANKSEL PORTD ; Bank0,
	CALL inid ; the initial configuration of the LCD.
	CALL xms
	CALL xms
	
; ------------- This is for the RX/TX configuration (commmunication between pics --------------------;	
	BCF STATUS,6
	BSF STATUS,5 ; 01: Bank1.
	
	BCF TRISC,6 ; seting TX (BC6) output for transmiting.
	BSF TRISC,7 ; seting RX (BC7) output for transmiting.

	MOVLW b'00100000' ; 
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

	BANKSEL PORTD ; go to bank 0 to make the lcd run.
	GOTO start

; When intruput happend the program will enter here
; The ISR will increment the count by 1 until to reach 100 for 2 seconds.
ISR:
	
	BANKSEL INTCON 
	BCF INTCON, TMR0IF ; Clear the Timer0 Flag
	BCF INTCON, TMR0IE ; Disable the Time0 Interrupt 

	INCF count ; increment the count.

	BANKSEL PORTD
	;Reset the timer0 and enable it again.
BACK: 
	BANKSEL TMR0 
	CLRF TMR0 ; 
	BANKSEL INTCON
	BSF INTCON, TMR0IE
	BANKSEL PORTD


	retfie


	INCLUDE "LCDIS.INC" ; including the LCD library with 4-bit mode -edited-
; The main code for our program
start:
	; Blinking Welcome Code
	CALL welcomeString
	CALL xms ; 4 times xms will give us 1 second delay.
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
	MOVLW 0x0F ; for blinking cursor
	CALL send 
	BSF Select,RS
Number1:
	BSF Select,RS
	MOVLW '0'
	CALL send
	MOVLW '0'
	CALL send
;	to start the timer0 after printing Eneter Number 1 : 
	BANKSEL INTCON
	BSF INTCON, TMR0IE  ; set the Timer0 enable
	BANKSEL TMR0
	CLRF TMR0
	BANKSEL OPTION_REG 
	MOVLW b'00000101' ; pre-sclae 1:64 for timer0.
	MOVWF OPTION_REG ; store the previous vlaue in optreg.
	BANKSEL PORTD

; -------------------------- Number 1 Turn ------------------------------;
SetCursorNum1Tens:
	BCF Select,RS ; command mode.
	MOVLW 0xC0 ;set the cursor in the second row, first column.
	CALL send
	BSF Select,RS ; data mode.
ENTERNumber1Tens:
	BTFSC count,7 ; check the counter is 128. (128 times interrupt)
	GOTO SetCursorNum1Ones
	BTFSC PORTB,0
	GOTO ENTERNumber1Tens
	CALL xms
	CALL xms
	BTFSS PORTB,0
	GOTO ENTERNumber1Tens
	
INCREMENTTENS:
	CALL resetTimer0 ; the button is clicked, so we will restart the timer zero.
	INCF tensTemp 
	BSF Select,RS

MAXNine: ; to make the digit go back to 0 if it reached 9 and then click again.
	MOVFW tensTemp
	SUBLW D'9'
	BTFSS STATUS,C
	CLRF tensTemp

	BSF Select,RS
	MOVFW tensTemp
	ADDLW D'48'
	
	CALL send
	GOTO SetCursorNum1Tens

SetCursorNum1Ones: ; the num1 ones digit.
	CALL resetTimer0 
	BCF Select,RS
	MOVLW 0xC1 ; the cursor position to the next digit.
	CALL send 
	BSF Select,RS
ENTERNumber1Ones:
	BTFSC count,7 ; skip it it didnt reach 2 second, 
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
	ADDLW D'48' ; to make the digit in asci to preview it on the lcd.
	
	CALL send
	GOTO SetCursorNum1Ones

;------------------ MUL SIGN --------------------------------;

MulSign:
	CALL resetTimer0
	BCF Select,RS ; comman mode
	MOVLW 0xC2 ; cursor position of the mul sign.
	CALL send 
	BSF Select,RS ; data mode.
	MOVLW 'x'
	CALL send
	MOVLW '0' ; to preview the digits zeros initially for num2.
	CALL send
	MOVLW '0'
	CALL send
	BCF Select,RS
	MOVLW 0x87 ; to edit the Number '1' and make it '2'
	CALL send
	BSF Select,RS
	MOVLW '2'
	CALL send
	BCF Select,RS
	MOVLW 0xC2 ; back to the x cursor position.
	CALL send
	GOTO SetCursorNum2Tens

; ------------- Second Number Turn ;--------------------------
; the same previous details of num1 is applied to num2.
SetCursorNum2Tens:
	CALL resetTimer0
	BCF Select,RS
	MOVLW 0xC3 ; num2 tens cursor position.
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
	MOVLW 0xC5  ; equal sign cursor position.
	CALL send
	BSF Select,RS
	MOVLW '='
	CALL send

;-----------------------------------Concatination of Number 1------------------------;
; here we concatinate the number1 as full number not separated to send it in one shoot to PIC2
Num1Concat:
	BCF STATUS,Z
	MOVFW tensTemp
	MOVWF RtensTemp ; to save the value of single tens digit to use it in the PIC1 multiplication.
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
	MOVWF TXREG ; here we will put the value that we need to set.
	CALL TRANSMIT ; number one send as full number tens+ones to PIC2. by checking that if the PIR1,4 is empty.
	MOVFW onesTemp2
	MOVWF TXREG
	CALL TRANSMIT; ones for number 2 send to PIC2.


;----------------------------MUL Number1 * Tens of number2------------------------
; After sending the num1 and number2's ones digit to PIC2, here the PIC one will do num1 x mum2's tens digit  
MullPIC1
	MOVFW tensTemp2 ; here to save the num2 tens digit to use it in multiplying the tens digit.
	MOVWF RtensTemp2
	BCF STATUS,Z
	MOVLW D'0'
	XORWF onesTemp,W
	BTFSC STATUS,Z
	GOTO DigitIsZero ; if the num1 ones digit is zero, there is no need to multiply it so skip and put the digit1 zero.
	MOVFW onesTemp
	CLRF onesTemp
MullOnesLoop
	ADDWF onesTemp,F ; here will multiply the num1 ones digit by the num2 tens digit by addition operation.
	DECFSZ RtensTemp2 ; assume num1 is 33 and num2 tens digit is 5, (33+33+33+33+33).
	GOTO MullOnesLoop
CarryLoop ; this to construct if there is a carry. 
	MOVLW D'10'
	SUBWF onesTemp
	BTFSS STATUS,C
	GOTO digitOnes
	INCF CarryCount
	GOTO CarryLoop
digitOnes ; from the carry loop the result will be in negative then we will add ten and we got the ones digit.
	;REMOVE -
	MOVFW onesTemp
	ADDLW D'10'
	MOVWF onesTemp
	MOVFW onesTemp
	MOVWF ResultL
	GOTO MullTenLoop

DigitIsZero ; if the digit is zero then the result digit is 0 and the carry 0
	CLRF ResultL 
	CLRF CarryCount

MullTenLoop ; num1 multiplication by the num2 tens.
	MOVFW RtensTemp ; we now take the value of the tens digit that saved and store it in the Working Register.
	ADDWF ResultH,F ; we do the same multiplication by addition as the ones digit above.
	MOVFW ResultH

	DECFSZ tensTemp2
	GOTO MullTenLoop
	MOVFW CarryCount ; we add the resultant carry from the ones multiplication (if there is carry) to the result. 
	ADDWF ResultH,F
;------------- Num1 now Multiplied by Num2 tens and we need to check if PIC2 send its Multiplication result ------


	CALL RXCHECK 


; ---------- Function to separate the  Most Significnts bits that came from PIC2 ---------;
; it work as the previous separate method.
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

RXCHECK: ; to check if there is data coming from the PIC2.
	BTFSC PIR1,5 ; check if the USART recive buffer is empty
	CALL RECIVED ; if there is data coming then go to recived to read it and store it.
	BTFSC ReciveTurn,1 ; to check if the PIC recived 2 times the most sign. shoot and the least.
	GOTO ADDITION; if it recived the two shoots it will go to the final addition operation of the 2 PICs results.
	GOTO RXCHECK ; if not keep checking.
	RETURN

RECIVED:
	MOVF RCREG,0 ; Move the recived value from PIC2, 0: means mov it to the W register.
	BTFSC ReciveTurn,0 ; check if the recived is the most significant digits.
	GOTO SecondNumCame ; if the recived is the least significant digit.
	BSF ReciveTurn,0 ; if the recived is the most sig. then make this flag1 to recive the least in the next time.
	MOVWF ResultH2 ; store the recived most sig digits here.
	BCF STATUS,Z 
	GOTO SepNumber1H ; after reciveing the two most sig. digit go and separate them to do the addition.
backFromSep	
	GOTO ReturnFlag ; to make the PIR1 digit 5 zero, USART buffer make it 0 to recive again.
SecondNumCame
	CLRF ResultL2 
	MOVWF ResultL2 ; put the RCREG contant in this register ( least significant ) it will be ready as the ones digit of final result.
	BSF ReciveTurn,1 ; make this flag 1 to say we are ready to addition with PIC1 result.

ReturnFlag
	BCF PIR1,5 ; make this digit 0, for reciving again.
	RETURN

ADDITION
;   now the PIC1 and PIC2 multiplications results are ready to addition to each other.
	CLRF CarryCount
	MOVFW onesTimes ; read the tens value of the result of the MUL tens in PIC2 and add it to the tens MUL result of PIC1  
	ADDWF ResultL  ;FINAL TENS
	MOVFW tenTimes ; read the hundreds digit of the MUL result from PIC2 and it to the most sig. of PIC1 MUL result
	ADDWF ResultH,F ;FINAL THOUSAND AND HUNDS  ( need to separate to be able to review them.
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
THOUSAND:  ; here we need to separate the result that contains the result of Hundreds and Thousands.
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

;-------------------------- Printing the Final Result Of the Multiplication ------------------------;

PrintFinal
	BCF Select, RS ; command mode.
	MOVLW 0x80 ; move the cursor to the first row of LCD. 
	CALL send 
	BSF Select, RS ; data mode. 
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
	BCF Select, RS ; command mode.
	MOVLW 0xC6 ; move the cursor after the = sign.
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
	GOTO loop ; this loop will keep the result and check if the button clicked again to do another MUL. operation.

;------------------| Transmit 

TRANSMIT:
	BTFSS PIR1,4 ; check if the Transmitt Buffer is Empty. so the data was sent by TXREG. 
	GOTO TRANSMIT
	RETURN


; --------------------| Print "Welcome Multiplication" on the LCD |------------------------------;
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
;-------------------| Print "Number 1" On the LCD |---------------------------------------;
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
	
;-----------| After Clicking the button after review a mul result we need to clear all the registers and go from printing "number1: " |-------------
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
	MOVLW d'6'
	MOVWF SPBRG
; -------------- The end of RX/TX configuration ------------------------------------------;
	BANKSEL PORTD ; go to bank 0 to make the lcd run.
	GOTO BeginEntering	

; ------------------------ The End of the Code --------------------------------------------;

	END