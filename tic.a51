; TIC support.
; 2009 Nathan Blythe
;
; Public routines:
;   ticStart:  Start the TIC counting for a certain number of seconds.
;   ticStop:   Stop the TIC counter, whatever it's doing.
;


; Start the TIC counting for a certain number of seconds.
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

  ; Enable the TIC.
  ;
    mov TIMECON, #00010011b
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

