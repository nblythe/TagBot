; Auto-Tag 
; 2009 Nathan Blythe
;
; Overview:
;   TODO
;


$INCLUDE (ADuC841.mcu)


; Configuration constants.
;
DRIVE_TIME    EQU 5
SCAN_TIME     EQU 2
SCAN_THRESH   EQU 0A0H
SCAN_DELTA    EQU 020H


; State variables.
;
BSEG
  flagMode:    dbit 1
DSEG
  StateL:      ds   1
  StateH:      ds   1
  State_adc0:  ds   1
  State_adc1:  ds   1


; Interrupt vector table.
;
CSEG at 00000H
    ljmp Reset
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
    ljmp adcISR           ; ADC
    ds   5
    ljmp Stub             ; SPI, I2C
    ds   5
    ljmp Stub             ; Power supply monitor
    ds   5
    ljmp Stub             ; Reserved
    ds   5
    ljmp ticISR           ; Timer interval counter
    ds   5
    ljmp Stub             ; Watchdog timer
  Stub:
    reti


; Firmware entry point at reset.
;
;
  Reset:
  ; Enable ADC, TIC interrupts.
  ;
    mov IE,    #11000000b
    mov IEIP2, #00000100b

  ; TODO - init mode from GPIO.
  ;
    clr flagMode

  ; Initialize firmware components.
  ;
    call locoInit
    call adcInit

  ; Start in scan state.
  ;
    ljmp Scan


; "Drive" state
;
  Drive:
  ; Offensive: drive forwards.
  ; Defensive: drive reverse.
  ;
    mov A, #LOCO_DRIVE_F
    jnb flagMode, Drive_Start
    mov A, #LOCO_DRIVE_R
  Drive_Start:
    call locoState

  ; Start the timer.
  ;
    mov A, #DRIVE_TIME
    call ticStart

  ; Wait until either the time expires or a collision
  ; occurs.  TODO
  ;
    ;clr State_colFlag
  Drive_Wait:
    jb ticTock, Drive_Done
    ;jb State_colFlag, Drive_Collision
    sjmp Drive_Wait

  ; Time expired.  Stop the drive motor and switch
  ; to the "Scan" state.
  ;
  Drive_Done:
    mov A, #LOCO_STOP
    call locoState
    ljmp Scan

  ; Interrupted by a collision.  Stop the drive motor,
  ; cancel the timer, and switch to the "Bus Detect" state.
  ;
  Drive_Collision:
    mov A, #LOCO_STOP
    call locoState
    call ticStop
    ljmp BusDetect


; "Scan" state
;
  Scan:
    clr P3.4

  ; Initialize the threshold scan value.
  ;
    mov B, #SCAN_THRESH

  ; Offensive: listen to the defensive microphone input.
  ; Defensive: listen to the offensive microphone input.
  ;
    mov A, #ADC_MIC_DEFENSIVE
    jnb flagMode, Scan_Start
    mov A, #ADC_MIC_OFFENSIVE
  Scan_Start:
    call adcStart

  ; Wait until we start getting valid results.
  ;
  Scan_WaitValid:
    jnb adcValid, Scan_WaitValid

  ; Start turning in a circle.
  ;
  ; TODO: pick direction randomly.
  ;
    mov A, #LOCO_SPIN_L
    call locoState

  ; Scan loop.  On each iteration we run the timer and
  ; watch the scan values while we wait for it to finish.
  ; If the scan value exceeds the threshold we stop.  If
  ; the timer runs out we decrease the threshold and try
  ; again.
  ;
  ; TODO: collisions!
  ;
  Scan_Loop:
    mov A, #SCAN_TIME
    call ticStart
  ;
  Scan_LoopWait:
    jb ticTock, Scan_LoopWaitTO
  ;
    mov A, adcValue
    clr C
    subb A, B
    jnc Scan_Done
  ;
    sjmp Scan_LoopWait
  ;
  Scan_LoopWaitTO:
    mov A, B
    clr C
    subb A, #SCAN_DELTA
    mov B, A
    jnc Scan_Loop
    mov B, #000H
    sjmp Scan_Loop

  ; Threshold exceeded.  Stop turning, stop the timer,
  ; and switch to the "Drive" state.
  ;
  Scan_Done:
    mov A, #LOCO_STOP
    call locoState
    call ticStop
    ljmp Drive


; "Bus Detect" state
;
; TODO
;
  BusDetect:
    sjmp BusDetect


; "Seperate" state
;
; TODO
;
  Seperate:
    sjmp Seperate


; Additional source files.
;
$INCLUDE(loco.a51)
$INCLUDE(tic.a51)
$INCLUDE(adc.a51)


END

