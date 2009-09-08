; Test program for ADuC841 development board.
; 2009 Nathan Blythe
;
; The on-board LED blinks slowly.  Pressing the INT0/ button
; speeds up the blinking (and wraps to a slow blink eventually).
;

$INCLUDE (ADuC841.mcu)


; Reset vector.
;
CSEG at 00000H
  VecReset:
    ljmp Main


; External interrupt 0 vector.
;
; Decrement R1 by 0x08.  If we reach 0, reset to 0x40.  Wait
; until the INT0/ button is released before returning.
;
CSEG at 00003H
  Button:
    push ACC
    mov A, R1
    clr C
    subb A, #008H
    jnz Button_0
    mov A, #040H
  Button_0:
    mov R1, A
    pop ACC
  Button_1:
    jnb P3.2, Button_1
    reti


; Main entry point.
;
; Initialize R1 to 0x40 (see the Delay routine) and enable
; external interrupt 0 (and no others).  Loop, toggling the
; LED with a call to Delay after each toggle.
;
CSEG at 00100H
  Main:
    mov R1, #040H
    mov IE, #10000001b
  Loop:
    clr  P3.4
    call Delay
    setb P3.4
    call Delay
    sjmp Loop


; Delay some human-detectable amount of time.
;
; Takes:
;   R1: some general approximation of time to delay.
;
; Returns:
;   Nothing
;
; Mangles:
;   A, B, R0
;
  Delay:
    mov A, R1
    mov R0, A
  Delay_0:
    mov B, #0FFH
  Delay_1:
    mov  A, #0FFH
  Delay_2:
    djnz ACC, Delay_2
    djnz B, Delay_1
    dec R0
    mov A, R0
    jnz Delay_0
    ret


END

