; Auto-Tag locomotion.
; 2009 Nathan Blythe
;
; Public routines:
;   locoInit:  Initialize the locomotion system.
;   locoState: Set the state of the locomotion system.
;
; Overview:
;   TODO
;


; Locomotion states.
;
LOCO_STOP     EQU 0
LOCO_DRIVE_F  EQU 1
LOCO_DRIVE_R  EQU 2
LOCO_SPIN_L   EQU 3
LOCO_SPIN_R   EQU 4


; Initialize the locomotion system.
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
  locoInit:
    mov PWM1L, #255         ; Period of both PWMs.
    mov PWM1H, #000H        ; Offset of PWM1's rising edge (PWM0 rises at 0).
    mov PWM0L, #000H        ; PWM0 has initial duty cycle 0.
    mov PWM0H, #000H        ; PWM1 has initial duty cycle 0.
    mov PWMCON, #00101111b  ; Mode 2, clock is fosc / 64.
    ret


; Set the state of the locomotion system.
;
; Takes:
;   A: state
;
; Returns:
;   Nothing
;
; Mangles:
;   Nothing
;
  locoState:
    push ACC
    push DPH
    push DPL
    clr C
    rlc A
    clr C
    rlc A
    clr C
    rlc A
    mov DPTR, #locoState_JT
    jmp @A+DPTR

  ; Top of jump table (8 byte entries).
  ;
  locoState_JT:

  ; Both motors stopped.
  ;
    mov PWM0L, #080H
    mov PWM0H, #080H
    sjmp locoState_Done

  ; Heading motor stopped, drive motor forwards.
  ;
    mov PWM0L, #080H
    mov PWM0H, #0FFH
    sjmp locoState_Done

  ; Heading motor stopped, drive motor reverse.
  ;
    mov PWM0L, #080H
    mov PWM0H, #000H
    sjmp locoState_Done

  ; Heading motor forwards, drive motor stopped.
  ;
    mov PWM0L, #0FFH
    mov PWM0H, #080H
    sjmp locoState_Done

  ; Heading motor reverse, drive motor stopped.
  ;
    mov PWM0L, #000H
    mov PWM0H, #080H
    sjmp locoState_Done
 
  ; All done.
  ;
  locoState_Done:
    pop DPL
    pop DPH
    pop ACC
    ret

