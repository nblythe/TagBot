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

  ; Store the final carry byte.
  ;
    mov A, R2
    mov @R0, A

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
  ; Multiply low byte



