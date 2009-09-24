; TIC support.
; 2009 Nathan Blythe
;
; Public routines:
;   ticStart:  Start the TIC counting for a certain number of ticks.
;   ticStop:   Stop the TIC counter, whatever it's doing.
;   ticISR:    TIC interrupt service routine.
;
; Public variables:
;   ticTock:   Flag indicating that the TIC has tocked.
;
; Overview:
;   TODO
;


; TIC bits.
;
BSEG
  ticTock: dbit 1


; Routines follow.
;
CSEG


; Start the TIC counting for a certain number of ticks.
;
; Takes:
;   A: number of ticks the TIC should count.
;   B: 0 = tick in 128ths of seconds; 1 = tick in seconds.
;
; Returns:
;   Nothing
;
; Mangles:
;   Nothing
;
; Notes:
;   Single-shot timer (no auto-restart).
;
;   See page 55 in the documentation.
;
  ticStart:
    push ACC

  ; Disable the TIC and reset current time interval.
  ;
    mov TIMECON, #00000000b
    call ticSafety
    mov HTHSEC,  #00H
    call ticSafety
    mov SEC,     #00H
    call ticSafety
    mov MIN,     #00H
    call ticSafety
    mov HOUR,    #00H
    call ticSafety

  ; Set the counter limit.
  ;
    mov INTVAL, A
    call ticSafety

  ; Reset the event flag.
  ;
    clr ticTock

  ; Enable the TIC with the proper timebase.
  ;
    mov A, #00000011b
    jnb B.0, ticStart_Ready
    mov A, #00010011b
  ticStart_Ready:
    mov TIMECON, A
    call ticSafety

  ; All done.
  ;
    pop ACC
    ret


; Stop the TIC counter, whatever it's doing.
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
  ticStop:
    mov TIMECON, #00000000b
    call ticSafety
    ret


; Delay between TIC-accessing instructions.
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
;   See page 44 in the documentation.
;
  ticSafety:
    push ACC
    push B
    mov A, #002H
  ticSafety_0:
    mov B, #0FFH
  ticSafety_1:
    djnz B, ticSafety_1
    djnz ACC, ticSafety_0
    pop B
    pop ACC
    ret


; TIC interrupt service routine.
;
  ticISR:
    setb ticTock
    reti

