;' $Header$
	title	WNTST31 -- INT 31h Handler for WNTDPMI Stub Program
	page	58,122
	name	WNTST31

COMMENT|		Module Specifications

Copyright:  (C) Copyright 2003 Qualitas, Inc.  All rights reserved.

Segmentation:  See WNTSTSEG.INC

Program derived from:  None.

Original code by:  Bob Smith, June, 2003

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include ASCII.INC
	include DOS.INC
	include PTR.INC
	include DPMI.INC
	include 386.INC
	include BITFLAGS.INC
	include ISVBOP.INC

	include WNTDPMI.INC
	include WNTSTSEG.INC
.list

CODE	segment 		; Start CODE segment
	assume	ds:PGROUP

	extrn	DATASEG:word

CODE	ends			; End CODE segment


LDATA	segment 		; Start LDATA segment
	assume	ds:PGROUP

	extrn	ClientIndex:dword
	extrn	DATASEL:word
	extrn	ModuleHandle:word

@LMB_MASK equ	4*1024-1	; Mask for testing LMB handles
@LMB_BITS equ	4*1024-1	; Low-order bits which identify our LMB handles

@NumClients equ 16		; # nested DPMI clients we support

	public	OLDINT21_FVEC,OLDINT31_FVEC
OLDINT21_FVEC dq @NumClients dup (?) ; Old PM INT 21h handler(s)
				; Note we use DQ instead of DF so we can
				; index the array more easily
OLDINT31_FVEC dq @NumClients dup (?) ; Old PM INT 31h handler(s)
				; Note we use DQ instead of DF so we can
				; index the array more easily
	public	DPMITYPE
DPMITYPE db	((@NumClients + (8-1))/8) dup (?) ; DPMI client type :	0 = 16-bit, 1 = 32-bit

	public	DPMIFL
DPMIFL	db	?		; DPMI flags

LDATA	ends			; End LDATA segment


CODE16	segment 		; Start CODE16 segment
	assume	cs:PGROUP

	public	PTRINT21_LCL,PTRINT21_LCLLG2
PTRINT21_LCL:
	CALLD	LCL_INT21	; Five-byte code sequence
PTRINT21_LCLZ:
	nop			; For alignment
	nop			; ...
	nop			; ...
PTRINT21_LCLLEN equ $-PTRINT21_LCL ; Length of block
PTRINT21_LCLLG2 equ 3		; @Lg2 (PTRINT21_LCLLEN) ; Log2 (Length of block)

	rept	@NumClients-1

	CALLD	LCL_INT21	; Five-byte code sequence
	nop			; For alignment
	nop			; ...
	nop			; ...

	endm			; REPT


	public	PTRINT31_LCL,PTRINT31_LCLLG2
PTRINT31_LCL:
	CALLD	LCL_INT31	; Five-byte code sequence
PTRINT31_LCLZ:
	nop			; For alignment
	nop			; ...
	nop			; ...
PTRINT31_LCLLEN equ $-PTRINT31_LCL ; Length of block
PTRINT31_LCLLG2 equ 3		; @Lg2 (PTRINT31_LCLLEN) ; Log2 (Length of block)

	rept	@NumClients-1

	CALLD	LCL_INT31	; Five-byte code sequence
	nop			; For alignment
	nop			; ...
	nop			; ...

	endm			; REPT

	FPPROC	LCL_INT21 -- Local INT 21h Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local PM INT 21h handler

Note that we are a 16- or 32-bit client depending upon the original
caller's choice.  Thus the stack frame at I31_RET is either IRETD_STR
or IRET_STR.  Any references to values at or above I31_RET must take
into account the caller's original DPMITYPE.

On entry:

AX	=	function code

On exit:

Depends upon the entry vars

|

I21_STR struc

I21_EGP db	(type PUSHAD_STR) dup (?) ; Caller's EGPs
I21_EIP dd	?		; Return EIP if continuing with next handler
I21_NDX dd	?		; Client index
I21_RET dd	?		; Return IRETD_STR

I21_STR ends

	sub	esp,type I21_EIP ; Make room for return EIP if continuing

; Convert the return address to a client index
; and store it back in the same place

	pushad			; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

; Clear the high-order word of EBP/ESP if SS is a 16-bit selector

	IF16STK <sp,bp>

	mov	eax,[ebp].I21_NDX ; Get the return address of the
				; PTRINT21_LCL call
	sub	eax,offset PGROUP:PTRINT21_LCLZ ; Convert to origin-0 (times 8)
	shr	eax,3-0 	; Convert from bytes to entries
	mov	[ebp].I21_NDX,eax ; Save back

; Put the client's EFL into effect (in particular IF)

	push	[ebp].I21_RET.IRETD_EFL ; Get client's EFL
	popfd			; Restore

	mov	eax,[ebp].I21_EGP.PUSHAD_EAX ; Get the original EAX

	cmp	ah,@EXITRC	; Izit Exit to DOS?
	je	short LCL_INT21_EXITRC ; Jump if so

; Launder other DOS functions??















	jmp	short LCL_INT21_EXIT_COM ; Join common exit code


LCL_INT21_EXITRC:
	push	ds		; Save for a moment

	mov	ds,DATASEL	; Get PGROUP data selector
	assume	ds:PGROUP	; Tell the assembler about it

	dec	ClientIndex	; Back off by one client

	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it
LCL_INT21_EXIT_COM:

; Continue with next handler in sequence

	mov	esi,[ebp].I21_NDX ; Get client index

	mov	eax,OLDINT21_FVEC[esi * (type OLDINT21_FVEC)].FOFF ; Get next EIP
	mov	[ebp].I21_EIP,eax ; Save on stack
	mov	ax,OLDINT21_FVEC[esi * (type OLDINT21_FVEC)].FSEL ; Get next CS
	mov	[ebp].I21_NDX,eax ; Save on stack

; If this client is 16-bit, change the stack frame to be 16-bit as well

	bt	DPMITYPE.ELO,si ; Izit a 32-bit client?
	jc	short LCL_INT21_EXITORIG ; Jump if so

; Move up the stack

@DIFF21 equ	(type IRETD_STR) - (type IRET_STR)

	mov	eax,[ebp].I21_RET.IRETD_EFL ; Get EFL
	mov	[ebp + @DIFF21].I21_RET.IRET_FL,ax ; Save in new position

	mov	ax,[ebp].I21_RET.IRETD_CS ; Get CS
	mov	[ebp + @DIFF21].I21_RET.IRET_CS,ax ; Save in new position

	mov	eax,[ebp].I21_RET.IRETD_EIP ; Get EIP
	mov	[ebp + @DIFF21].I21_RET.IRET_IP,ax ; Save in new position

	mov	eax,[ebp].I21_NDX ; Get return CS
	mov	[ebp + @DIFF21].I21_NDX,eax ; Save in new position

	mov	eax,[ebp].I21_EIP ; Get return EIP
	mov	[ebp + @DIFF21].I21_EIP,eax ; Save in new position

	popad			; Restore all EGPs

	add	esp,@DIFF21	; Strip off the difference

	pushad			; Rather than jump over the POPAD??
LCL_INT21_EXITORIG:
	popad			; Restore

	RETFD			; "Return" to next handler in sequence

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT21 endp			; End LCL_INT21 procedure
	FPPROC	LCL_INT31 -- Local INT 31h Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local PM INT 31h handler

Note that we are a 16- or 32-bit client depending upon the original
caller's choice.  Thus the stack frame at I31_RET is either IRETD_STR
or IRET_STR.  Any references to values at or above I31_RET must take
into account the caller's original DPMITYPE.

On entry:

AX	=	function code

On exit:

Depends upon the entry vars

|

I31_STR struc

I31_EGP db	(type PUSHAD_STR) dup (?) ; Caller's EGPs
I31_EIP dd	?		; Return EIP if continuing with next handler
I31_NDX dd	?		; Client index
I31_RET dd	?		; Return IRETd_STR

I31_STR ends

	sub	esp,type I31_EIP ; Make room for return EIP if continuing

; Convert the return address to a client index
; and store it back in the same place

	pushad			; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

; Clear the high-order word of EBP/ESP if SS is a 16-bit selector

	IF16STK <sp,bp>

	mov	eax,[ebp].I31_NDX ; Get the return address of the
				; PTRINT31_LCL call
	sub	eax,offset PGROUP:PTRINT31_LCLZ ; Convert to origin-0 (times 8)
	shr	eax,3-0 	; Convert from bytes to entries
	mov	[ebp].I31_NDX,eax ; Save back

; Put the client's EFL into effect (in particular IF)

	push	[ebp].I31_RET.IRETD_EFL ; Get client's EFL
	popfd			; Restore

	mov	eax,[ebp].I31_EGP.PUSHAD_EAX ; Get the original EAX

	cmp	ax,9999h	; Izit Get LL Count?
	je	near ptr LCL_INT31_GETLLCNT ; Jump if so

	cmp	ax,@DPMI_GETMLDTE ; Izit Get Multiple LDTEs?
	je	near ptr LCL_INT31_GETMLDTE ; Jump if so

	cmp	ax,@DPMI_SETMLDTE ; Izit Set Multiple LDTEs?
	je	near ptr LCL_INT31_SETMLDTE ; Jump if so

;;;;;;; cmp	ax,@DPMI_GETEPMPEHV ; Izit Get Extended PM Proc Exception Handler?
;;;;;;; cmp	ax,@DPMI_GETEVMPEHV ; Izit Get Extended VM Proc Exception Handler?
;;;;;;; cmp	ax,@DPMI_SETEPMPEHV ; Izit Set Extended PM Proc Exception Handler?
;;;;;;; cmp	ax,@DPMI_SETEVMPEHV ; Izit Set Extended VM Proc Exception Handler?

	cmp	ax,@DPMI_RELMEM     ; Izit Release Memory Block?
	je	near ptr LCL_INT31_RELMEM ; Jump if so

	cmp	ax,@DPMI_GETLMB     ; Izit Allocate Linear Memory Block?
	je	near ptr LCL_INT31_GETLMB ; Jump if so

;;;;;;; cmp	ax,@DPMI_MODLMB     ; Izit Resize Linear Memory Block?
;;;;;;; cmp	ax,@DPMI_GPGATTR    ; Izit Get Page Attributes?

	cmp	ax,@DPMI_SPGATTR    ; Izit Set Page Attributes?
	je	near ptr LCL_INT31_SPGATTR ; Jump if so

;;;;;;; cmp	ax,@DPMI_MAPDEV     ; Izit Map Device in Memory Block?
;;;;;;; cmp	ax,@DPMI_MAPCONV    ; Izit Map Conventional Memory in Memory Block?
;;;;;;; cmp	ax,@DPMI_GETMBLKSZ  ; Izit Get Memory Block Size & Base?
;;;;;;; cmp	ax,@DPMI_GETMEMI    ; Izit Get Memory Information?
;;;;;;; cmp	ax,@DPMI_RELP2L     ; Izit Free Physical to Linear Address Mapping?
;;;;;;; cmp	ax,@DPMI_GETSHR     ; Izit Allocate Shared Memory?
;;;;;;; cmp	ax,@DPMI_RELSHR     ; Izit Free Shared Memory?
;;;;;;; cmp	ax,@DPMI_SERIALIZE  ; Izit Serialize on Shared Memory?
;;;;;;; cmp	ax,@DPMI_RELSERIAL  ; Izit Free Serialization on Shared Memory?
;;;;;;; cmp	ax,@DPMI_GETCAP     ; Izit Get DPMI Capabilities?
;;;;;;; cmp	ax,@DPMI_TSRSRV     ; Izit Install Resident Service Provider CB?
;;;;;;; cmp	ax,@DPMI_TSRXIT     ; Izit Terminate & Stay Resident?

; Continue with next handler in sequence

LCL_INT31_NEXT:
	mov	esi,[ebp].I31_NDX ; Get client index

	mov	eax,OLDINT31_FVEC[esi * (type OLDINT31_FVEC)].FOFF ; Get next EIP
	mov	[ebp].I31_EIP,eax ; Save on stack
	mov	ax,OLDINT31_FVEC[esi * (type OLDINT31_FVEC)].FSEL ; Get next CS
	mov	[ebp].I31_NDX,eax ; Save on stack

; If this client is 16-bit, change the stack frame to be 16-bit as well

	bt	DPMITYPE.ELO,si ; Izit a 32-bit client?
	jc	short LCL_INT31_EXITORIG ; Jump if so

; Move up the stack

@DIFF31 equ	(type IRETD_STR) - (type IRET_STR)

	mov	eax,[ebp].I31_RET.IRETD_EFL ; Get EFL
	mov	[ebp + @DIFF31].I31_RET.IRET_FL,ax ; Save in new position

	mov	ax,[ebp].I31_RET.IRETD_CS ; Get CS
	mov	[ebp + @DIFF31].I31_RET.IRET_CS,ax ; Save in new position

	mov	eax,[ebp].I31_RET.IRETD_EIP ; Get EIP
	mov	[ebp + @DIFF31].I31_RET.IRET_IP,ax ; Save in new position

	mov	eax,[ebp].I31_NDX ; Get return CS
	mov	[ebp + @DIFF31].I31_NDX,eax ; Save in new position

	mov	eax,[ebp].I31_EIP ; Get return EIP
	mov	[ebp + @DIFF31].I31_EIP,eax ; Save in new position

	popad			; Restore all EGPs

	add	esp,@DIFF31	; Strip off the difference

	pushad			; Rather than jump over the POPAD??
LCL_INT31_EXITORIG:
	popad			; Restore

	RETFD			; "Return" to next handler in sequence


COMMENT|

|

LCL_INT31_GETLLCNT:

; Pass this request to the VDD

	mov	eax,@VDD_GETLL	; Function code
	mov	ax,ModuleHandle ; Get the module handle
	DispatchCall		; Call the VDD
				; Return with CF and all EGP registers significant
	mov	[ebp].I31_EGP.PUSHAD_EAX,eax ; Return to caller

	jmp	LCL_INT31_EXITCOM ; Join common exit code


COMMENT|

DPMI 1.0 function to Get multiple LDT entries

On entry (in I31_STR):

AX	=	000Eh
CX	=	number of descriptors to copy
ES:eDI	=	pointer to an array of structures in GetSetLDT
IF	=	caller's (possibly enabled)
SS:EBP	==>	INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in I31_STR):

CF	=	0 if successful

CF	=	1 if not successful
AX	=	8022 if invalid selector
CX	=	number of descriptors successfully copied

All other registers except EBP, FS, GS, and SS may be clobbered.

|

GetSetLDT struc

GS_Sel	dw	?		; The selector
GS_Desc dq	?		; The descriptor

GetSetLDT ends


LCL_INT31_GETMLDTE:
	jcxz	LCL_INT31_GETMLDTE_EXIT1 ; Jump if no selectors to get

	IF16ZX	di		; Zero high-order word if 16-bit client
@@:
	mov	bx,es:[edi].GS_Sel ; Get the selector
	add	edi,type GS_Sel ; ES:eDI ==> descriptor
	DPMICALL @DPMI_GETLDTE	; Request DPMI service
	jc	short LCL_INT31_GETMLDTE_EXIT ; Jump if something went wrong

	add	edi,type GS_Desc ; Skip to next entry

	loop	@B		; Jump if more entries
LCL_INT31_GETMLDTE_EXIT:
	pushf			; Save flags

; Set CX to the # descriptors set

	sub	cx,[ebp].I31_EGP.PUSHAD_ECX.ELO ; Less original #
	neg	cx		; Negate to subtract from original #

	popf			; Restore
LCL_INT31_GETMLDTE_EXIT1:
	jmp	LCL_INT31_EXITCOM ; Join common exit code


COMMENT|

DPMI 1.0 function to Get multiple LDT entries

On entry (in I31_STR):

AX	=	000Fh
CX	=	number of descriptors to set
ES:eDI	=	pointer to an array of structures in GetSetLDT
IF	=	caller's (possibly enabled)
SS:EBP	==>	INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in I31_STR):

CF	=	0 if successful

CF	=	1 if not successful
AX	=	8022 if invalid selector
	=	8021 if invalid access rights
	=	8025 if invalid linear address
		 (this last error is not in the 0.9 spec and so
		  we don't enforce it here as some programs might
		  break were we to do so)
CX	=	number of descriptors successfully set

All other registers except EBP, FS, GS, and SS may be clobbered.

|

LCL_INT31_SETMLDTE:
	jcxz	LCL_INT31_SETMLDTE_EXIT1 ; Jump if no selectors to set

	IF16ZX	di		; Zero high-order word if 16-bit client
@@:
	mov	bx,es:[edi].GS_Sel ; Get the selector
	add	edi,type GS_Sel ; ES:eDI ==> descriptor
	DPMICALL @DPMI_SETLDTE	; Request DPMI service
	jc	short LCL_INT31_SETMLDTE_EXIT ; Jump if something went wrong

	add	edi,type GS_Desc ; Skip to next entry

	loop	@B		; Jump if more entries
LCL_INT31_SETMLDTE_EXIT:
	pushf			; Save flags

; Set CX to the # descriptors set

	sub	cx,[ebp].I31_EGP.PUSHAD_ECX.ELO ; Less original #
	neg	cx		; Negate to subtract from original #

	popf			; Restore
LCL_INT31_SETMLDTE_EXIT1:
	jmp	LCL_INT31_EXITCOM ; Join common exit code


COMMENT|

DPMI 0.9 function to release memory block

On entry (in I31_STR):

AX	=	0502h
SI:DI	=	memory block handle

On exit (in I31_STR):

CF	=	0 if successful

CF	 =	 1 if not successful
AX	 =	 8023 if invalid handle

|

LCL_INT31_RELMEM:

; If this is a handle allocated by us via function 0504h,
; we cleverly set the low-order bits to a unique value
; so we can tell it apart from the normal handles

	mov	bx,si		; Copy high-order word of the handle
	shl	ebx,16		; Shift into high-order word
	mov	bx,di		; Copy low-order word of the handle

	mov	eax,ebx 	; Copy to test
	and	eax,@LMB_MASK	; Isolate the bits

	cmp	eax,@LMB_BITS	; Izit our handle?
	jne	near ptr LCL_INT31_NEXT ; Jump if not

	and	ebx,not @LMB_MASK ; Clear the mask bits

; Pass this request to the VDD

	mov	eax,@VDD_RELLMB ; Function code
	mov	ax,ModuleHandle ; Get the module handle
	DispatchCall		; Call the VDD
				; Return with CF and all EGP registers significant
	jnc	short @F	; Jump if no error

	cmp	ax,@DPMIERR_BADLADDR ; Izit Invalid LMB?
	je	near ptr LCL_INT31_NEXT ; Jump if so (continue with next handler)

	mov	[ebp].I31_EGP.PUSHAD_EAX.ELO,ax ; Return to caller
@@:
	jmp	short LCL_INT31_EXITCOM ; Join common exit code


COMMENT|

DPMI 1.0 function to allocate linear memory block

On entry (in I31_STR):

AX	=	0504h
EBX	=	desired linear address (page aligned)
ECX	=	size of block (bytes, must be non-zero)
EDX	=	flags bit 0 = 1 means committed, else uncommitted
IF	=	caller's (possibly enabled)
SS:EBP	==>	INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in I31_STR):

CF	=	0 if successful
EBX	=	linear address of allocated block
ESI	=	memory block handle

CF	=	1 if not successful
AX	=	8012 if linear memory unavailable
	=	8013 if physical ...
	=	8014 if backing store ...
	=	8016 if handle unavailable
	=	8021 if invalid value (ECX = 0)
	=	8025 if requested address is not page aligned

All other registers except EBP, FS, GS, and SS may be clobbered.

|

LCL_INT31_GETLMB:

; Validate the arguments

	test	ebx,4*1024-1	; Izit page-aligned?
	mov	ax,@DPMIERR_BADLADDR ; Assume not
	jnz	short LCL_INT31_ERRCOM ; Jump if not

	mov	ax,@DPMIERR_BADVALUE ; Assume CX is zero
	jecxz	LCL_INT31_ERRCOM ; Jump if so

; Pass this request to the VDD

	mov	eax,@VDD_GETLMB ; Function code
	mov	ax,ModuleHandle ; Get the module handle
	DispatchCall		; Call the VDD
				; Return with CF and all EGP registers significant
	jc	short @F	; Jump if something went wrong

	or	esi,@LMB_BITS	; Mark as special handle
@@:
	mov	[ebp].I31_EGP.PUSHAD_EAX,eax ; Return to caller
	mov	[ebp].I31_EGP.PUSHAD_EBX,ebx ; ...
	mov	[ebp].I31_EGP.PUSHAD_ESI,esi ; ...

	jmp	short LCL_INT31_EXITCOM ; Join common exit code


COMMENT|

DPMI 1.0 function to retrieve page attributes

On entry (in I31_STR):

AX	 =	 0506h
ESI	 =	 memory block handle
EBX	 =	 base offset in block of first page
ECX	 =	 number of pages
ES:EDX	 =	 selector offset of buffer to receive page attributes

On exit (in I31_STR):

CF	 =	 0 if successful
EBX	 =	 new linear address of block

CF	 =	 1 if not successful
AX	 =	 8023 if handle is invalid
	 =	 8025 if linear address is invalid

|

LCL_INT31_GPGATTR:





	clc			; Mark as successful

	jmp	short LCL_INT31_EXITCOM ; Join common exit code


COMMENT|

DPMI 1.0 function to set page attributes

On entry (in I31_STR):

AX	 =	 0507h
ESI	 =	 memory block handle
EBX	 =	 base offset in block of first page
ECX	 =	 number of pages
ES:EDX	 =	 selector offset of buffer containing page attributes

On exit (in I31_STR):

CF	 =	 0 if successful
EBX	 =	 new linear address of block

CF	 =	 1 if not successful
AX	 =	 8021 if invalid value
	 =	 8023 if handle is invalid
	 =	 8025 if linear address is invalid
ECX	 =	 number of pages that were successfully set

|

LCL_INT31_SPGATTR:






	clc			; Mark as successful

	jmp	short LCL_INT31_EXITCOM ; Join common exit code


LCL_INT31_ERRCOM:
	mov	[ebp].I31_EGP.PUSHAD_EAX.ELO,ax ; Return to caller

	stc			; Mark as in error
LCL_INT31_EXITCOM:

; Enter here with FL significant
; As we need to test for 16- vs. 32-bit, save the current FL

	push	ds		; Save for a moment

	mov	ds,DATASEL	; Get PGROUP data selector
	assume	ds:PGROUP	; Tell the assembler about it

	lahf			; Load FL into AH
	mov	DPMIFL,ah	; Save for later use

	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

; In order to return to the caller properly, we need
; to know whether we're a 16- or 32-bit client

	mov	esi,[ebp].I31_NDX ; Get client index
	bt	DPMITYPE.ELO,si ; Izit a 32-bit client?
				; Return with CF = 1 iff 32-bit client
	popad			; Restore

; Good old MASM 5.10b doesn't support putting the two constants
; into the instruction, so we need to use an equate.

@STRIP	equ	(size I31_EIP) + (size I31_NDX) ; Strip these from the stack

	lea	esp,[esp + @STRIP] ; Strip from stack

	jc	short @F	; Jump if 32-bit client

	push	eax		; Save for a moment

	mov	ah,DPMIFL	; Get return flags
	sahf			; Set FL from AH

	pop	eax		; Restore

	RETFS	2		; Return to caller, popping flags


@@:
	push	eax		; Save for a moment

	mov	ah,DPMIFL	; Get return flags
	sahf			; Set FL from AH

	pop	eax		; Restore

	RETFD	4		; Return to caller, popping flags

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT31 endp			; End LCL_INT31 procedure

CODE16	ends			; End CODE16 segment

	MEND			; End WNTST31 module
