;'$Header$

; WNTDPMI.INC

TRUE	equ	1
FALSE	equ	0

WNTTITLE equ	<'Qualitas DPMI 1.0 Extensions for Win NT/2000/XP'>
WNTFNAM equ	<'WNTDPMI'>


; Function codes to LCL_VSAPI

@VSAPI_DISABLE equ 0
@VSAPI_ENABLE  equ 1
@VSAPI_UNLOAD  equ 2


; Flags for LCL_FLAG

@LCL_NOWIN equ	0004h		; Don't require Win NT/2000/XP (for debugging only)
@LCL_NRES equ	0002h		; Don't go resident
@LCL_INST equ	0001h		; Installed


; Function codes for DispatchCall
; The following equates *MUST* match the ones in WNTVDD.C

@VDD_GETLMB equ 1 shl 16	; Allocate Linear Memory Block
@VDD_RELLMB equ 2 shl 16	; Release  Linear Memory Block
@VDD_GETLL  equ 99 shl 16	; Get LL count



; Macros

IF16ZX	macro	REG		; If this is a 16-bit client, MOVZX the REG
	local	L1

	push	eax		; Save for a moment

	mov	eax,[ebp].I31_NDX ; Get the current index

	bt	DPMITYPE.ELO,ax ; Izit a 32-bit client?
	pop	eax		; Restore
	jc	short L1	; Jump if so

	movzx	e&REG,REG	; Zero to use as dword
L1:
	endm			; IF16ZX


IF16STK macro	REGS		; If the stack is 16-bit, zero
	local	L1		; the high-order word of specified regs

	push	eax		; Save for a moment

	mov	eax,ss		; Copy stack selector
	lar	eax,eax 	; Get A/R word

	bt	eax,$DTE_B+16	; Test the B-bit
	pop	eax		; Restore
	jc	short L1	; Jump if 32-bit

	irp	XX,<REGS>	; Loop through registers whose high-order word we're to clear
	movzx	e&&XX,&XX	; Clear the high-order word
	endm			; REPT
L1:
	endm			; IF16STK


;;;; @Lg2    macro   NUM
;;;;	     local   CNT,N
;;;;
;;;; CNT     =	     0
;;;; N	     =	     NUM
;;;;
;;;; while N NE 0
;;;; CNT     =	     CNT + 1
;;;; N	     =	     N / 2
;;;; endm
;;;;	     exitm   %CNT
;;;;
;;;;	     endm		     ; @Lg2
;;;;
;;;;
