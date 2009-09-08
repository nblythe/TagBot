; PWM test
; 2009 Nathan Blythe
;


$INCLUDE (ADuC841.mcu)


; Interrupt vector table.
;
CSEG at 00000H
  ljmp Main             ; Reset
  ljmp Button           ; External interrupt 0
  ds   5
  ljmp Stub             ; Timer 0
  ds   5
  ljmp Stub             ; External interrupt 1
  ds   5
  ljmp Stub             ; Timer 1
  ds   5
  ljmp Stub             ; UART
  ds   5
  ljmp Stub             ; Timer 2
  ds   5
  ljmp Stub             ; ADC
  ds   5
  ljmp Stub             ; SPI, I2C
  ds   5
  ljmp Stub             ; Power supply monitor
  ds   5
  ljmp Stub             ; Timer interval counter
  ds   5
  ljmp Stub             ; Watchdog timer
Stub:
  reti


; Button is pressed.
;
; Decrement PWM0's DC by 18.  If we pass 0, reset to 180.
; Increment PWM1's DC by 18.  If we pass 180, reset to 0.
; Wait until the INT0/ button is released before returning.
;
Button:
  push ACC

  call PWM_getDC0
  clr C
  subb A, #18
  jnc Button_0
  mov A, #180
Button_0:
  call PWM_setDC0

  call PWM_getDC1
  add A, #18
  cjne A, #198, Button_1
  mov A, #000H
Button_1:
  call PWM_setDC1

  pop ACC

Button_2:
  jnb P3.2, Button_2
  reti



; Main entry point.
;
;
Main:
  mov IE, #10000001b

  call PWM_Init
  mov A, #180
  call PWM_setDC0
  mov A, #000H
  call PWM_setDC1

Main_0:
  sjmp Main_0



; Initialize the PWM outputs.
;
; Takes:
;   Nothing
;
; Returns:
;   Nothing
;
; Mangles:
;   Nothing
;
; Notes:
;   PWM mode 2 is used (8 bit twin PWMs).  PWM0 and PWM1
;   are synchronized to start at the same time.  Both PWMs
;   have a resolution of 1 / 180.
;
;   See page 43 of the documentation.
;
PWM_Init:
  mov PWM1L, #180         ; Period of both PWMs.
  mov PWM1H, #000H        ; Offset of PWM1's rising edge (PWM0 rises at 0).
  mov PWM0L, #000H        ; PWM0 has initial duty cycle 0.
  mov PWM0H, #000H        ; PWM1 has initial duty cycle 0.
  mov PWMCON, #00101111b  ; Mode 2, clock is fosc / 64.
  ret


; Set PWM0's duty cycle.
;
; Takes:
;   A: duty cycle is A / 180.
;
; Returns:
;   Nothing
;
; Mangles:
;   Nothing
;
PWM_setDC0:
  mov PWM0L, A
  ret


; Set PWM1's duty cycle.
;
; Takes:
;   A: duty cycle is A / 180.
;
; Returns:
;   Nothing
;
; Mangles:
;   Nothing
;
PWM_setDC1:
  mov PWM0H, A
  ret


; Get PWM0's duty cycle.
;
; Takes:
;   Nothing
;
; Returns:
;   A: duty cycle is A / 180.
;
; Mangles:
;   Nothing
;
PWM_getDC0:
  mov A, PWM0L
  ret


; Get PWM1's duty cycle.
;
; Takes:
;   Nothing
;
; Returns:
;   A: duty cycle is A / 180.
;
; Mangles:
;   Nothing
;
PWM_getDC1:
  mov A, PWM0H
  ret


END

