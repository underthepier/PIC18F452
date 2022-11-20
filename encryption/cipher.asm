;/----------------------PROGRAM DESCRIPTION----------------------\;
		;RECEIVE DATA FROM PC AND RETURN IT
    ;2400 BPS, 8 DATA BITS, 1 START BIT, 1 STOP BIT, NO PARITY
		    ;USES THE POLLING METHOD
;/------------------------------LIST------------------------------\;
LIST P=18F2420, MM=OFF, R=HEX, ST=OFF, X=OFF
;/--------------------------CONFIG BITS---------------------------\;
; CONFIG1H
  CONFIG  OSC = HS              ; Oscillator Selection bits (HS oscillator)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor disabled)
  CONFIG  IESO = OFF            ; Internal/External Oscillator Switchover bit (Oscillator Switchover mode disabled)

; CONFIG2L
  CONFIG  PWRT = OFF            ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  BOREN = OFF           ; Brown-out Reset Enable bits (Brown-out Reset disabled in hardware and software)
  CONFIG  BORV = 3              ; Brown Out Reset Voltage bits (Minimum setting)

; CONFIG2H
  CONFIG  WDT = OFF             ; Watchdog Timer Enable bit (WDT disabled (control is placed on the SWDTEN bit))
  CONFIG  WDTPS = 32768         ; Watchdog Timer Postscale Select bits (1:32768)

; CONFIG3H
  CONFIG  CCP2MX = PORTC        ; CCP2 MUX bit (CCP2 input/output is multiplexed with RC1)
  CONFIG  PBADEN = OFF          ; PORTB A/D Enable bit (PORTB<4:0> pins are configured as digital I/O on Reset)
  CONFIG  LPT1OSC = OFF         ; Low-Power Timer1 Oscillator Enable bit (Timer1 configured for higher power operation)
  CONFIG  MCLRE = ON            ; MCLR Pin Enable bit (MCLR pin enabled; RE3 input pin disabled)
; CONFIG4L
  CONFIG  STVREN = OFF          ; Stack Full/Underflow Reset Enable bit (Stack full/underflow will not cause Reset)
  CONFIG  LVP = OFF             ; Single-Supply ICSP Enable bit (Single-Supply ICSP disabled)
  CONFIG  XINST = OFF           ; Extended Instruction Set Enable bit (Instruction set extension and Indexed Addressing mode disabled (Legacy mode))

; CONFIG5L
  CONFIG  CP0 = OFF             ; Code Protection bit (Block 0 (000800-001FFFh) not code-protected)
  CONFIG  CP1 = OFF             ; Code Protection bit (Block 1 (002000-003FFFh) not code-protected)

; CONFIG5H
  CONFIG  CPB = OFF             ; Boot Block Code Protection bit (Boot block (000000-0007FFh) not code-protected)
  CONFIG  CPD = OFF             ; Data EEPROM Code Protection bit (Data EEPROM not code-protected)

; CONFIG6L
  CONFIG  WRT0 = OFF            ; Write Protection bit (Block 0 (000800-001FFFh) not write-protected)
  CONFIG  WRT1 = OFF            ; Write Protection bit (Block 1 (002000-003FFFh) not write-protected)

; CONFIG6H
  CONFIG  WRTC = OFF            ; Configuration Register Write Protection bit (Configuration registers (300000-3000FFh) not write-protected)
  CONFIG  WRTB = OFF            ; Boot Block Write Protection bit (Boot block (000000-0007FFh) not write-protected)
  CONFIG  WRTD = OFF            ; Data EEPROM Write Protection bit (Data EEPROM not write-protected)

; CONFIG7L
  CONFIG  EBTR0 = OFF           ; Table Read Protection bit (Block 0 (000800-001FFFh) not protected from table reads executed in other blocks)
  CONFIG  EBTR1 = OFF           ; Table Read Protection bit (Block 1 (002000-003FFFh) not protected from table reads executed in other blocks)

; CONFIG7H
  CONFIG  EBTRB = OFF           ; Boot Block Table Read Protection bit (Boot block (000000-0007FFh) not protected from table reads executed in other blocks)
;/-----------------INCLUDE LIBRARY FOR PIC18F2420----------------\;
#include <p18f2420.inc>
VAR	EQU 0x0A
;/---------------SETUP FOR POWER UP AND INTERRUPTS---------------\;
	ORG 0x00
	GOTO START		;Go to beginning of program
	
	ORG 0x08
	BTFSC PIR1, RCIF	;Execute RX_ISR if received data
	BRA RX_ISR
	BTFSS INTCON, INT0IF	;Execute CIPHER_ISR if pushbutton was pressed
	RETFIE			
	BRA CIPHER_ISR

	ORG 0x18
	RETFIE
;/--------------------START OF ACTUAL PROGRAM--------------------\;
START
;/SETUP
	;/Clear RC0 pin
	BCF PORTC, 0
	
	;/Configure TXSTA register
	MOVLW B'00100000'	;Enable transmit, 8-bit transmission
	MOVWF TXSTA		;Asynchronous mode
	
	;/Configure RCSTA register
	MOVLW B'10010000'	;Enable serial port, continuously receive 8 bit data, no framing error bit, no overrun error bit
	MOVWF RCSTA
	
	;/Configure baud rate settings
	MOVLW D'25'		;9600 bps. [(16 MHz / 64) / 9600] - 1 = 25.04 -> 25
	MOVWF SPBRG
	
	;/Make TX pin an output pin
	BCF TRISC, TX
	
	;/Make RX pin an input pin
	BSF TRISC, RX
	
	;/Make RC0 pin an output pin for LED receive indicator
	BCF TRISC, 0
	
	;/Make INT0 an input pin to sense push button to send data
	BSF TRISB, INT0
	
	;/Enable interrupts
	BSF PIE1, RCIE		;RX interrupt
	BSF INTCON, INT0IE	;INT0 interrupt
	BSF INTCON, PEIE	;Peripheral interrupt for COM port
	BSF INTCON, GIE		;Officially allow interrupts to occur

	BRA $
;/------------------INTERRUPT SERVICE ROUTINES--------------------\;
RX_ISR	
	MOVFF RCREG, VAR
	BSF PORTC, 0
	RCALL MSG1
	RETFIE
	
CIPHER_ISR
	RCALL MSG2	
	BCF INTCON, INT0IF
	BCF PORTC, 0
	CLRF WREG
	RETFIE
;/--------------------------SUBROUTINES---------------------------\;
MSG1
;/Print "Plaintext: " message
	;/Load Table Pointer
	MOVLW upper(PLAINTEXT)
	MOVWF TBLPTRU
	MOVLW high(PLAINTEXT)
	MOVWF TBLPTRH
	MOVLW low(PLAINTEXT)
	MOVWF TBLPTRL
	
	;/Send "Plaintext: "
READ1	TBLRD*+
	MOVF TABLAT, WREG
	BZ SEND_PLAIN
	RCALL SEND
	BRA READ1
	
;/Send received character
SEND_PLAIN
	MOVF VAR, WREG	    ;Copy received character to WREG
	RCALL SEND	    ;Transmit received character
	RCALL LFCR	    ;Transmit Newline and Carriage Return
	RETURN		    ;Exit MSG1 subroutine
;/----------------------------------------------------------------\;	
MSG2
;/Print "Ciphertext: " message
	;/Load Table Pointer
	MOVLW upper(CIPHERTEXT)
	MOVWF TBLPTRU
	MOVLW high(CIPHERTEXT)
	MOVWF TBLPTRH
	MOVLW low(CIPHERTEXT)
	MOVWF TBLPTRL
	
	;/Send "Ciphertext: "
READ2	TBLRD*+
	MOVF TABLAT, WREG
	BZ SEND_CIPHER
	RCALL SEND
	BRA READ2

;/Send Ciphered character
SEND_CIPHER
	MOVF VAR, WREG
	XORLW B'01100111'
	RCALL SEND
	RCALL LFCR
	RETURN			;Exit MSG2 subroutine
;/---------------------------------------------------------------\;	
LFCR
;/Transmit Newline and Carriage Return
	MOVLW H'D'		;Transmit Newline/Line Feed
	RCALL SEND
	MOVLW H'A'		;Transmit Carriage Return
	RCALL SEND	
	RETURN
;/---------------------------------------------------------------\;
SEND
L1	BTFSS PIR1, TXIF
	BRA L1
	MOVWF TXREG
	RETURN
;/----------------------------------------------------------------\;	
PLAINTEXT  DB "Plaintext: ", 0
CIPHERTEXT DB "Ciphertext: ", 0
END