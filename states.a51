; State machine test
; 2009 Nathan Blythe
;


$INCLUDE (ADuC841.mcu)
$INCLUDE (loco.inc)

; Configuration.
;
DRIVE_SPEED_F EQU 255
DRIVE_SPEED_R EQU 0
DRIVE_TIME    EQU 5



; State variables.
;
BSEG
  State_modeFlag:  dbit 1
  State_toFlag:    dbit 1
  State_colFlag:   dbit 1

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
    setb State_toFlag
    reti



; Main entry point.
;
;
  Main:
    mov IE,    #10000000b
    mov IEIP2, #00000100b

    call locoInit

    ;mov A, #005H
    ;call TIC_Start

    ljmp Drive



; "Drive" state
;
  Drive:
  ; Offensive: drive forwards.
  ; Defensive: drive reverse.
  ;
    mov A, #LOCO_DRIVE_F
    jnb State_modeFlag, Drive_Start
    mov A, #LOCO_DRIVE_R
  Drive_Start:
    call locoState

  ; Start the timer.
  ;
    clr State_toFlag
    mov A, #DRIVE_TIME
    call ticStart

  ; Wait until either the time expires or a collision
  ; occurs.
  ;
    clr State_colFlag
  Drive_Wait:
    jb State_toFlag, Drive_Done
    jb State_colFlag, Drive_Collision
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
; TODO
;
  Scan:
    sjmp Scan


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















$INCLUDE(loco.a51)
$INCLUDE(tic.a51)



END

