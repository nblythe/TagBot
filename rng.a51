; 8-bit random number generator.
; 2009 Nathan Blythe
;
; Public routines:
;   rngInit:   Initialize and seed the RNG.
;   rngGet:    Retrieve the next RNG value.
;
; Overview:
;   TODO
;


; LCG parameters.
;
RNG_A_3 EQU 000H
RNG_A_2 EQU 019H
RNG_A_1 EQU 066H
RNG_A_0 EQU 00DH
RNG_C_3 EQU 03CH
RNG_C_2 EQU 06EH
RNG_C_1 EQU 0F3H
RNG_C_0 EQU 05FH


; State.
;
DSEG
  rngState: ds 4
  rngTemp0: ds 4
  rngTemp1: ds 4
  rngTemp2: ds 4
  rngTemp3: ds 4


; Routines follow.
;
CSEG


; Initialize the RNG.
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
  rngInit:
    mov rngState + 0, #0
    mov rngState + 1, #0
    mov rngState + 2, #0
    mov rngState + 3, #0
    ret


; Add argument C to the state.
;
; Takes:
;   Nothing
;
; Returns:
;   Nothing
;
; Mangles:
;   A
;
  rngAdd:
    mov A, rngState + 0
    add A, #RNG_A_0
    mov rngState + 0, A

    mov A, rngState + 1
    addc A, #RNG_A_1
    mov rngState + 1, A

    mov A, rngState + 2
    addc A, #RNG_A_2
    mov rngState + 2, A

    mov A, rngState + 3
    addc A, #RNG_A_3
    mov rngState + 3, A

    ret


; Multiply register A against state.
;
; Takes:
;   A
;   R0: points to storage space for result
;
; Returns:
;   Result at R0
;
; Mangles:
;   Nothing
;
  rngMulB:
    push ACC
    push B
    mov A, R0
    push ACC
    mov A, R1
    push ACC
    mov A, R2
    push ACC

  ; Point R1 to the state.
  ; Carry byte initially 0.
  ; Count initially at 4.
  ;
    mov R1, #rngState
    mov R2, #0
    mov B, #4

  ; A times byte n + carry byte (n - 1).
  ; Generates byte n and carry byte (n).
  ;
  rngMulB_Loop:
    push B
    push ACC
  ;
    mov A, @R1
    inc R1
    mov B, A
    pop ACC
    push ACC
  ;
    mul AB
    add A, R2
    jnc rngMulB_nc
    inc B
  rngMulB_nc:
  ;
    mov @R0, A
    inc R0
    mov R2, B
  ;
    pop ACC
    pop B
    djnz B, rngMulB_Loop

  ; All done, unroll and return.
  ;
    pop ACC
    mov R2, A
    pop ACC
    mov R1, A
    pop ACC
    mov R0, A
    pop B
    pop ACC
    ret


; Multiply argument A against the state.
;
; Takes:
;   Nothing
;
; Returns:
;   Nothing
;
; Mangles:
;   A
;
  rngMul:
    push B
    mov A, R0
    push ACC

  ; A.0 * State -> Temp0
  ;
    mov R0, #rngTemp0
    mov A, RNG_A_0
    call rngMulB

  ; A.1 * State -> Temp1
  ;
    mov R0, #rngTemp1
    mov A, RNG_A_1
    call rngMulB

  ; A.2 * State -> Temp2
  ;
    mov R0, #rngTemp2
    mov A, RNG_A_2
    call rngMulB

  ; A.3 * State -> Temp3
  ;
    mov R0, #rngTemp3
    mov A, RNG_A_3
    call rngMulB

  ; Temp0.0 -> State.0
  ;
    mov A, rngTemp0 + 0
    mov rngState + 0, A

  ; Temp0.1 + Temp1.0 -> State.1
  ;
    mov A, rngTemp0 + 1
    mov B, rngTemp1 + 0
    add A, B
    mov rngState + 1, A

  ; C + Temp0.2 + Temp1.1 + Temp2.0 -> State.2
  ;
    mov A, rngTemp0 + 2
    mov B, rngTemp1 + 1
    addc A, B
    mov B, rngTemp2 + 0
    addc A, B
    mov rngState + 2, A

  ; C + Temp0.3 + Temp1.2 + Temp2.1 + Temp3.0 -> State.3
  ;
    mov A, rngTemp0 + 3
    mov B, rngTemp1 + 2
    addc A, B
    mov B, rngTemp2 + 1
    addc A, B
    mov B, rngTemp3 + 0
    addc A, B
    mov rngState + 3, A

  ; All done.
  ;
    pop ACC
    mov R0, A
    pop B
    ret


; Retrieve the next RNG value.
;
; Takes:
;   Nothing
;
; Returns:
;   A: pseudo-random value
;
; Mangles:
;   Nothing
;
  rngGet:
    call rngMul
    call rngAdd
    mov A, rngState + 3
    ret

