; ADC -> PWM test
; 2009 Nathan Blythe
;


$INCLUDE (ADuC841.mcu)


; State variables.
;
BSEG
  State_adc0valid: dbit 1
  State_adc1valid: dbit 1
DSEG
  State_adc0:      ds   1
  State_adc1:      ds   1


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
    ljmp ADC              ; ADC
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
  Button:
    push ACC
    mov A, State_adc0
    call PWM_setDC0
    call PWM_setDC1
    pop ACC
  Button_waitRelease:
    jnb P3.2, Button_waitRelease
    reti


; ADC finished a conversion.
;
  ADC:
    push ACC
    mov A, ADCDATAH
    swap A
    jb ACC.0, ADC_channel1

  ; Channel 0.
  ;
    anl A, #11110000b
    mov State_adc0, A
    mov A, ADCDATAL
    swap A
    anl A, #00001111b
    orl A, State_adc0
    mov State_adc0, A
    pop ACC
    setb State_adc0valid
    reti

  ; Channel 1.
  ;
  ADC_channel1:
    anl A, #11110000b
    mov State_adc1, A
    mov A, ADCDATAL
    swap A
    anl A, #00001111b
    orl A, State_adc1
    mov State_adc1, A
    pop ACC
    setb State_adc1valid
    reti




; Main entry point.
;
;
  Main:
    mov IE, #11000001b

    call PWM_Init

    call ADC_Init
    call ADC_Calibrate

    call ADC_Start0

  Loop0:
    clr State_adc0valid
  Loop1:
    jnb State_adc0valid, Loop1
    mov A, State_adc0
    call PWM_setDC0
    call PWM_setDC1
    sjmp Loop0  


  Loop:
    sjmp Loop




; Initialize the ADC.
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
;   Internal 2.5V reference voltage.
;   ADC clock divider of 8.
;   4 clocks of track-and-hold.
;   No DMA.
;
;   See page 24 of the documentation.
;
  ADC_Init:
    mov ADCCON1, #10101100b
    mov ADCCON2, #00000000b
    mov ADCCON3, #00000000b
    ret


; Start the ADC in continuous mode on channel 0.
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
  ADC_Start0:
    mov ADCCON2, #00100000b
    ret


; Start the ADC in single mode on channel 1.
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
  ADC_Start1:
    mov ADCCON2, #00010001b
    ret


; Calibrate the ADC.
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
;   See page 30 of the documentation.
;
  ADC_Calibrate:
    push ACC

  ; Select channel AGND and perform offset calibration.
  ;
    mov ADCCON2, #00001011b
    mov ADCCON3, #00000101b
  ADC_Calibrate_waitOffset:
    mov A, ADCCON3
    jb ACC.7, ADC_Calibrate_waitOffset

  ; Select channel VREF and perform gain calibration.
  ;
    mov ADCCON2, #00001100b
    mov ADCCON3, #00000101b
  ADC_Calibrate_waitGain:
    mov A, ADCCON3
    jb ACC.7, ADC_Calibrate_waitGain

  ; All done.
  ;
    pop ACC
    ret









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
;   have a resolution of 1 / 255.
;
;   See page 43 of the documentation.
;
  PWM_Init:
    mov PWM1L, #255         ; Period of both PWMs.
    mov PWM1H, #000H        ; Offset of PWM1's rising edge (PWM0 rises at 0).
    mov PWM0L, #000H        ; PWM0 has initial duty cycle 0.
    mov PWM0H, #000H        ; PWM1 has initial duty cycle 0.
    mov PWMCON, #00101111b  ; Mode 2, clock is fosc / 64.
    ret


; Set PWM0's duty cycle.
;
; Takes:
;   A: duty cycle is A / 255.
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
;   A: duty cycle is A / 255.
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
;   A: duty cycle is A / 255.
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
;   A: duty cycle is A / 255.
;
; Mangles:
;   Nothing
;
  PWM_getDC1:
    mov A, PWM0H
    ret


END

