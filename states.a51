; State machine test
; 2009 Nathan Blythe
;


$INCLUDE (ADuC841.mcu)

; Configuration.
;
DRIVE_SPEED_F EQU 255
DRIVE_SPEED_R EQU 0
DRIVE_TIME    EQU 5



; State variables.
;
BSEG
  State_mode:      dbit 1
  State_adc0valid: dbit 1
  State_adc1valid: dbit 1
DSEG
  StateL:          ds   1
  StateH:          ds   1
  State_adc0:      ds   1
  State_adc1:      ds   1


; Interrupt vector table.
;
CSEG at 00000H
    ljmp Main             ; Reset
    ljmp Stub             ; External interrupt 0
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
    ljmp Stub             ; Unused.
    ds   5
    ljmp TIC              ; Timer interval counter
    ds   5
    ljmp Stub             ; Watchdog timer
  Stub:
    reti


; TIC tocked.
;
  TIC:
    jnb P3.4, TIC_turnOff
    clr P3.4
    reti
  TIC_turnOFF:
    setb P3.4

    push ACC
    mov A, #005H
    call TIC_Start
    pop ACC
    reti



; Main entry point.
;
;
  Main:
    mov IE,    #10000000b
    mov IEIP2, #00000100b

    mov A, #005H
    call TIC_Start

  Loop:
    sjmp Loop


; State: Drive
; Action: enter
;
  State_Drive_Enter:
    push ACC

    mov A, #DRIVE_SPEED_F
    jnb 


; Start the TIC counting a certain number of seconds.
;
; Takes:
;   A: number of seconds the TIC should count.
;
; Returns:
;   Nothing
;
; Mangles:
;   Nothing
;
; Notes:
;   "Seconds" are used as the interval timebase.
;   Single-shot timer (no auto-restart).
;
;   See page 55 in the documentation.
;
  TIC_Start:
    push ACC

  ; Disable the TIC and reset current time interval.
  ;
    mov TIMECON, #00000000b
    call TIC_Safety
    mov HTHSEC,  #00H
    call TIC_Safety
    mov SEC,     #00H
    call TIC_Safety
    mov MIN,     #00H
    call TIC_Safety
    mov HOUR,    #00H
    call TIC_Safety

  ; Set the counter limit.
  ;
    mov INTVAL, A
    call TIC_Safety

  ; Enable the TIC.
  ;
    mov TIMECON, #00010011b
    call TIC_Safety

  ; All done.
  ;
    pop ACC
    ret


  TIC_Safety:
    push ACC
    push B
    mov A, #002H
  TIC_Safety_0:
    mov B, #0FFH
  TIC_Safety_1:
    djnz B, TIC_Safety_1
    djnz ACC, TIC_Safety_0
    pop B
    pop ACC
    ret


; Reset the TIC interrupt.
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
  TIC_Reset:
    mov TIMECON, #00000000b
    ret


END

