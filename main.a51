; Auto-Tag 
; 2009 Nathan Blythe
;
; Overview:
;   TODO
;


$INCLUDE (ADuC841.mcu)


; Configuration constants.
;
DRIVE_TIME      EQU 5     ; Duration of drive state.
DRIVE_TIMEBASE  EQU 1     ; Timebase for DRIVE_TIME.
SCAN_TIME       EQU 2     ; Duration of a single scan loop.
SCAN_TIMEBASE   EQU 1     ; Timebase for SCAN_TIME.
SCAN_THRESH     EQU 0A0H  ; Initial scan threshold.
SCAN_DELTA      EQU 020H  ; Scan threshold decrease per loop.
DETECT_COUNT    EQU 20    ; Maximum number of bus detection loops.
DETECT_TIME     EQU 10    ; Duration of bus detection read/write cycles.
DETECT_TIMEBASE EQU 0     ; Timebase for DETECT_TIME.
DETECT_THRESH   EQU 080H  ; Bus detection threshold.


; Pin configurations.
;
PIN_CREAR       EQU P2.0
PIN_CRIGHT      EQU P2.1
PIN_CLEFT       EQU P2.2
PIN_CFRONT      EQU P2.3

; State variables.
;
BSEG
  flagMode:    dbit 1
  flagCol:     dbit 1


; Interrupt vector table.
;
CSEG at 00000H
    ljmp Reset
    ljmp Stub             ; External interrupt 0
    ds   5
    ljmp Stub             ; Timer 0
    ds   5
    ljmp colISR           ; External interrupt 1
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

  ; Collision flag starts out clear.
  ;
    clr flagCol

  ; TODO - init mode from GPIO.
  ;
    clr flagMode

  ; Initialize firmware components.
  ;
    call locoInit
    call adcInit
    call rngInit

  ; TODO
  ;
    ljmp BugBot

  ;  mov A, #LOCO_STOP
  ;  call locoState
  ;t:
  ;  sjmp t

  ; Start in scan state.
  ;
    ljmp Scan


; Collision ISR.
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
  colISR:
    setb flagCol
    reti


; "Drive" state
;
  Drive:
    clr P3.4
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
    mov B, #DRIVE_TIMEBASE
    call ticStart

  ; Wait until either the time expires or a collision
  ; occurs.
  ;
  Drive_Wait:
    jb ticTock, Drive_Done
    ;jb flagCol, Drive_Collision
    sjmp Drive_Wait

  ; Time expired.  Stop the drive motor and switch
  ; to the "Scan" state.
  ;
  Drive_Done:
    mov A, #LOCO_STOP
    call locoState
    setb P3.4
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
  ; again.  If a collision occurs we stop.
  ;
  Scan_Loop:
    push B
    mov A, #SCAN_TIME
    mov B, #SCAN_TIMEBASE
    call ticStart
    pop B
  ;
  Scan_LoopWait:
    jb ticTock, Scan_LoopWaitTO
    jb flagcol, Scan_Col
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

  ; Scan interrupted by a collision.  Stop turning,
  ; stop the timer, and switch to the "Bus Detect" state.
  ;
  Scan_Col:
    mov A, #LOCO_STOP
    call locoState
    call ticStop
    ljmp BusDetect


; "Bus Detect" state
;
  BusDetect:
  ; Initialize the loop counter.
  ;
    mov B, #DETECT_COUNT

  ; Top of detection loop.
  ;
  BusDetect_Loop:
    push ACC

  ; Prepare the TIC for a read cycle.
  ;
    mov A, #DETECT_TIME
    mov B, #DETECT_TIMEBASE
    call ticStart

  ; Switch the bus to read mode.
  ;
  ; TODO

  ; Read from the bus until we time out or detect
  ; someone.
  ;
  BusDetect_LoopR:
  ; Timed out?
  ;
    jb ticTock, BusDetect_toLoopR
  ;
  ; Found a defensive player?
  ;
    mov A, #ADC_COL_DEFENSIVE
    call adcStart
  BusDetect_LoopR_adcDef:
    jnb adcValid, BusDetect_LoopR_adcDef
    mov A, adcValue
    clr C
    subb A, #DETECT_THRESH
    jc BusDetect_foundDef
  ;
  ; Found an offensive player?
  ;
    mov A, #ADC_COL_OFFENSIVE
    call adcStart
  BusDetect_LoopR_adcOff:
    jnb adcValid, BusDetect_LoopR_adcOff
    mov A, adcValue
    clr C
    subb A, #DETECT_THRESH
    jc BusDetect_foundOff
  ;
    sjmp BusDetect_LoopR
  BusDetect_toLoopR:

  ; Prepare the TIC for a write cycle.
  ;
    mov A, #DETECT_TIME
    mov B, #DETECT_TIMEBASE
    call ticStart

  ; Switch the bus to write mode.
  ;
  ; TODO
  ;

  ; Write to the bus until we time out.
  ;
  BusDetect_LoopW:
    jnb ticTock, BusDetect_LoopW

  ; Rinse, wash, repeat!
  ;
    pop B
    djnz B, BusDetect_Loop

  ; Done looping; didn't find anyone.  We must have
  ; collided with an obstacle.  Switch to the "Seperate"
  ; state.
  ;
    ljmp Seperate

  ; Found a defensive player.  Change mode to defensive
  ; and switch to the "Seperate" state.
  ;
  BusDetect_foundDef:
    pop B
    setb flagMode
    ljmp Seperate

  ; Found an offensive player.  Change mode to offensive
  ; and switch to the "Seperate" state.
  ;
  BusDetect_foundOff:
    pop B
    clr flagMode
    ljmp Seperate


; "Seperate" state
;
; Drive away from the collision and ensure that we
; seperated enough that the collision flag can be safely
; cleared.  This will sort of a randomly "run away" routine.
;
  Seperate:
    sjmp Seperate


; "Bug bot" state
;
; Drive forward until a collision is detected.  When
; there's a collision, drive backwards a bit, turn
; randomly and drive forwards again.
;
  BugBot:
  ; Start out stopped.
  ;
    mov A, #LOCO_STOP
    call locoState

  BugBot_Loop:

  ; Front switch hit.  Drive backward, turn randomly,
  ; drive forward.
  ;
    jb PIN_CFRONT, BugBot_Loop_notFront
  ;
    mov A, #LOCO_DRIVE_R
    call locoState
  ;
    mov A, #3
    mov B, #1
    call ticStart
  BugBot_Loop_frontWait0:
    jnb ticTock, BugBot_Loop_frontWait0
  ;
    call rngGet
    mov B, A
    mov A, #LOCO_SPIN_R
    jnb B.0, BugBot_Loop_frontTurn
    mov A, #LOCO_SPIN_L
  BugBot_Loop_frontTurn:
    call locoState
  ;
    mov A, #2
    mov B, #1
    call ticStart
  BugBot_Loop_frontWait1:
    jnb ticTock, BugBot_Loop_frontWait1
  ;
    mov A, #LOCO_DRIVE_F
    call locoState
    sjmp BugBot_Loop
  BugBot_Loop_notFront:


  ; Right switch hit.  Turn left.
  ;
  ; TODO
  ;
  ;  jb PIN_CRIGHT, BugBot_Loop_notRight
  ;BugBot_Loop_notRight:


  ; Left switch hit.  Turn right.
  ;
  ; TODO
  ;
  ;  jb PIN_CLEFT, BugBot_Loop_notLeft
  ;BugBot_Loop_notLeft:


  ; Rear switch hit.  Drive forwards.
  ;
  ;  jb PIN_CREAR, BugBot_Loop_notRear
  ;BugBot_Loop_notRear:


  ; Nothing: keep doing whatever it is we're doing.
  ;
    sjmp BugBot_Loop


; Additional source files.
;
$INCLUDE(loco.a51)
$INCLUDE(tic.a51)
$INCLUDE(adc.a51)
$INCLUDE(rng.a51)


END

