;/----------------------PROGRAM DESCRIPTION----------------------\;
	;CONTINUOUSLY SEND THE MESSAGE "Trix are for kids!"
    ;9600 BPS, 8 DATA BITS, 1 START BIT, 1 STOP BIT, NO PARITY
			;TTL SERIAL FORMAT
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
;/---------------SETUP FOR POWER UP AND INTERRUPTS---------------\;
	ORG 0x00
	GOTO START		;Go to beginning of program
	ORG 0x08
	RETFIE
	ORG 0x18
	RETFIE


;/--------------------START OF ACTUAL PROGRAM--------------------\;
START
;/SETUP
	;/Configure TXSTA register
	MOVLW B'00100000'	;Enable transmit, 8-bit transmission
	MOVWF TXSTA		;Asynchronous mode
	
	;/Configure baud rate settings
	MOVLW D'25'		;9600 bps. [(16 MHz / 64) / 9600] – 1 = 25.04 -> 25
	MOVWF SPBRG
	
	;/Make TX pin an output pin
	BCF TRISC, TX

	;/Enable Serial Port
	BSF RCSTA, SPEN
;/------------------------------MAIN-----------------------------\;
;/Continuously send “Trix are for kids!”	
;/Load table pointer with address where MESSAGE is stored
INIT	MOVLW upper(MESSAGE)	
	MOVWF TBLPTRU
	MOVLW high(MESSAGE)
	MOVWF TBLPTRH
	MOVLW low(MESSAGE)
	MOVWF TBLPTRL

	;/Read from table, increment pointer, then send character
NEXT	TBLRD*+
	MOVF TABLAT, W		;WREG = TABLAT
	BZ INIT			;Reinitialize TBLPTR when WREG = null
	RCALL SEND			;Transmit character
	BRA NEXT			;Repeat until null
;/--------------------------SUBROUTINES--------------------------\;	
SEND	
L1	BTFSS PIR1, TXIF		;Make sure the last bit of the previous frame has been sent
	BRA L1
	MOVWF TXREG			;Transmit character
	RETURN
;/-------------------------DECLARATIONS--------------------------\;	
;*This is intentionally placed at the bottom as opposed to the top 
;to let the assembler optimize program memory space and allow us
;to load the TBLPTR using the "upper", "high", and "low" commands
;on lines 82, 84, and 86 without having to know an actual memory address value
MESSAGE     DB "Trix are for kids!", 0
END
