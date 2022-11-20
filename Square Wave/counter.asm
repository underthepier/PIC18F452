;/----------------------PROGRAM DESCRIPTION----------------------\;
	    ;COUNT THE NUMBER OF EDGES AT INPUT OF RA4
		    ;OUTPUT THE COUNT AT PORTC
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
	GOTO START			;Go to beginning of program
	ORG 0x08
	RETFIE
	ORG 0x18
	RETFIE
;/--------------------START OF ACTUAL PROGRAM--------------------\;
START
;/SETUP
	;/Configure PORT pins
	BSF TRISA, RA4		;Pin RA4 as clock input for Timer0 in counter mode
	CLRF TRISC			;PORTC as output
	
	;/Configure Timer0 as counter
MOVLW B'01101000'	
	MOVWF T0CON
;/MAIN
	;/Initialize Timer0
MAIN	CLRF TMR0L			;TMR0L = 0
	BCF INTCON, TMR0IF		;Clear Timer0 interrupt flag bit

	;/Start the loop
	BSF T0CON, TMR0ON		;Enable Timer0 to start counting the clock edges at RA4
AGAIN	MOVFF TMR0L, PORTC		;Output the number of counts at PORTB
	BTFSS INTCON, TMR0IF	;Keep counting until TMR0L overflows
	BRA AGAIN
	BCF T0CON, TMR0ON		;Stop Timer0
	BRA MAIN
END
