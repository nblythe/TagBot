; ADC support.
; 2009 Nathan Blythe
;
; Public routines:
;   adcInit:   Initialize and calibrate the ADC.
;   adcStart:  Start continuous ADC measurements on a channel.
;   adcStop:   Stop continuous ADC measurements.
;   adcSingle: Start a single ADC measurement on a channel.
;   adcISR:    ADC interrupt service routine.
;
; Public variables:
;   adcValid:  Flag indicating that the ADC value is now valid.
;   adcValue:  Last read value of the ADC.
;


; ADC channels.
;
ADC_MIC_OFFENSIVE EQU 0
ADC_MIC_DEFENSIVE EQU 1
ADC_COL_OFFENSIVE EQU 2
ADC_COL_DEFENSIVE EQU 3


; ADC bits.
;
BSEG
  adcValid: dbit 1


; ADC bytes.
;
DSEG
  adcValue: ds 1


; Routines follow.
;
CSEG


; Initialize and calibrate the ADC.
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
;   See pages 24, 30 of the documentation.
;
  adcInit:
    push ACC

  ; Initialize SFRs.
  ;
    mov ADCCON1, #10101100b
    mov ADCCON2, #00000000b
    mov ADCCON3, #00000000b

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


; Start continuous ADC measurements on a channel.
;
; Takes:
;   A: channel on which to begin measurements.
;
; Returns:
;   Nothing
;
; Mangles:
;   Nothing
;
  adcStart:
    push ACC

    clr adcValid

    orl A, #00100000b
    mov ADCCON2, A

    pop ACC
    ret


; Stop continuous ADC measurements.
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
  adcStop:
    mov ADCCON2, #00000000b
    ret


; Start a single ADC measurement on a channel.
;
; Takes:
;   A: channel on which to begin a measurement
;
; Returns:
;   Nothing
;
; Mangles:
;   Nothing
;
  adcSingle:
    push ACC

    clr adcValid

    orl A, #00010000b
    mov ADCCON2, A

    pop ACC
    ret


; ADC interrupt service routine.
;
  adcISR:
    push ACC

  ; Upper nybble.
  ;
    mov A, ADCDATAH
    swap A
    anl A, #11110000b
    mov adcValue, A

  ; Lower nybble.
  ;
    mov A, ADCDATAL
    swap A
    anl A, #00001111b
    orl A, adcValue
    mov adcValue, A

  ; Value is now valid.
  ;
    setb adcValid

  ; All done.
  ;
    pop ACC
    reti

