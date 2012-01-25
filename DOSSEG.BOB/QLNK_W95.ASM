;' $Header:   P:/PVCS/MISC/QLINK/QLNK_W95.ASV   1.0   07 Aug 1998 15:59:22   BOB  $
	title	QLNK_W95 -- Qualitas Linker, Win95 Routines
	page	58,122
	name	QLNK_W95

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1994-8 Qualitas, Inc.  All rights reserved.

Program derived from:  None.

Original code by:  Bob Smith, November, 1997.

Modifications by:  None.

|
.386p
.xlist
	include 386.INC
	include BITFLAGS.INC
	include DPMI.INC
	include MASM.INC
	include PTR.INC
	include VWIN32.INC
	include WINDEVID.INC
	include W95DPMI.INC

	include QLNK_SEG.INC
.list


DATA	segment 		; Start DATA segment
	assume	ds:DGROUP

	public	OLDLCL31_FVEC
OLDLCL31_FVEC df ?		; Original local INT 31h handler

	public	W95DPMI_FVEC
W95DPMI_FVEC df ?		; Ptr to W95DPMI VxD

	public	EPMPEHV0E_FVEC
EPMPEHV0E_FVEC df ?		; Ptr to Extended PM Exception Page Fault handler

	public	OLDLCL0E_FVEC
OLDLCL0E_FVEC df ?		; Old local INT 0Eh handler

DATA	 ends			; End DATA segment


NCODE	segment 		; Start NCODE segment
	assume	cs:NGROUP,ds:NGROUP

	extrn	SEL_DATA:word

	NPPROC	HOOK_WIN95 -- Hook Resources Needed To Run Under Win95
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Hook resources needed to run under Win95

On exit:

CF	=	0 if successful
	=	1 if error

|

	pushad			; Save registers

; Get address of W95DPMI.VxD

	push	es		; Save for a moment

	xor	edi,edi 	; Assume in error
	mov	es,di		; ES:EDI == 0:0
	assume	es:nothing	; Tell the assembler about it

	mov	ax,1684h	; Get Device Entry Point
	mov	bx,W95DPMI_Device_ID ; Device ID for W95DPMI.VxD
	int	2fh		; Request multiplexor service
	assume	es:nothing	; Tell the assembler about it

	mov	W95DPMI_FVEC.FOFF,edi ; Save for later use
	mov	W95DPMI_FVEC.FSEL,es ; ...

	pop	es		; Restore
	assume	es:DGROUP	; Tell the assembler about it

	cmp	W95DPMI_FVEC.FSEL,1 ; Izit invalid?
	jb	short HOOK_WIN95_EXIT ; Jump if so (note CF=1)

; Save the old INT 31h handler address

	mov	bl,31h		; Intercept this one
	DPMICALL @DPMI_GETPMIV	; Return with CX:EDX ==> old handler
	jc	short HOOK_WIN95_EXIT ; Jump if something went wrong (note CF=1)

	mov	OLDLCL31_FVEC.FOFF,edx ; Save for later use
	mov	OLDLCL31_FVEC.FSEL,cx ; ...

; Set our INT 31h handler into place

;;;;;;; mov	bl,31h		; Intercept this one
	mov	cx,cs		; Get our code selector
	lea	edx,LCL_INT31	; ...	       offset
	DPMICALL @DPMI_SETPMIV	; Set CX:EDX as new handler
;;;;;;; jc	short HOOK_WIN95_EXIT ; Jump if something went wrong
HOOK_WIN95_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HOOK_WIN95 endp 		; End HOOK_WIN95 procedure
	FPPROC	LCL_INT31 -- Local INT 31h Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local INT 31h handler

On entry:

AX	=	function code

On exit:

As appropriate

|

	sti			; Allow interrupts

	cmp	ax,@DPMI_GETLMB ; Izit one we need to launder?
	jne	short @F	; Jump if not

	call	EMU_GETLMB	; Emulate it

	jmp	short LCL_INT31_IRETD ; Join common exit code

@@:
	cmp	ax,@DPMI_RELMEM ; Izit one we need to launder?
	jne	short @F	; Jump if not

	call	EMU_RELMEM	; Emulate it

	jmp	short LCL_INT31_IRETD ; Join common exit code

@@:
	cmp	ax,@DPMI_SPGATTR ; Izit one we need to launder?
	jne	short @F	; Jump if not

	call	EMU_SPGATTR	; Emulate it

	jmp	short LCL_INT31_IRETD ; Join common exit code

@@:
	cmp	ax,@DPMI_GPGATTR ; Izit one we need to launder?
	jne	short @F	; Jump if not

	call	EMU_GPGATTR	; Emulate it

	jmp	short LCL_INT31_IRETD ; Join common exit code

@@:
	cmp	ax,@DPMI_SETEPMPEHV ; Izit one we need to launder?
	jne	short @F	; Jump if not

	call	EMU_SETEPMPEHV	; Emulate it

	jmp	short LCL_INT31_IRETD ; Join common exit code

@@:
	PUSHW	ds		; Save for a moment
	mov	ds,SEL_DATA	; Address DGROUP
	assume	ds:DGROUP	; Tell the assembler about it

	push	OLDLCL31_FVEC.FSEL ; Pass the selector
	push	OLDLCL31_FVEC.FOFF ; ...      offset

L31_STR struc

	df	?		; Next handler address
L31_DS	dw	?		; Caller's DS

L31_STR ends

	mov	ds,[esp].L31_DS ; Get next handler's DS
	assume	ds:nothing	; Tell the assembler about it

	RETFD			; Continue with next handler

LCL_INT31_IRETD:
	pushfd			; Get flags

I31_STR struc

I31_EIP dd	?		; Caller's EIP
I31_CS	dw	?,?		; ...	   CS w/filler
I31_EFL dd	?		; ...	   EFL

I31_STR ends

	pop	[esp].I31_EFL	; Put into effect

	iretd			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT31 endp			; End LCL_INT31 procedure
	NPPROC	EMU_GETLMB -- Emulate Get Linear Memory Block
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Emulate Get Linear Memory Block

On entry:

AX	=	0504h
EBX	=	desired page-aligned linear address of memory block
		or zero if linear address unspecified
ECX	=	size of block in bytes
EDX	=	flags
		Bit
		0	0=create uncommitted pages
			1=create committed pages
		1-31	reserved

On exit:

If successful,

CF	=	0
EBX	=	linear address of memory block
ESI	=	handle for memory block

If unsuccessful,

CF	=	1
AX	=	error code
		8001h	unsupported function
		8012h	linear memory unavailable
		8013h	physical memory unavailable
		8014h	backing store unavailable
		8016h	handle unavailable
		8021h	invalid value (ECX=0)
		8025h	invalid linear address (EBX not page-aligned)

|

	push	ds		; Save for a moment

	mov	ds,SEL_DATA	; Address DGROUP
	assume	ds:DGROUP	; Tell the assembler about it

	REGSAVE <ecx>		; Save for a moment

	lea	eax,[ecx+4*1024-1] ; Round up to 4KB boundary
	shr	eax,12-0	; Convert from bytes to 4KB

	mov	ecx,esp 	; Copy stack offset
	push	dword ptr 0	; 1:  No flags
	push	eax		; 2:  # pages to reserve

	mov	eax,PR_SHARED	; Get page type if linear address not specified

	and	ebx,ebx 	; Is the linear address specified?
	jz	short @F	; Jump if not

	mov	eax,ebx 	; Copy the linear address
@@:
	push	eax		; 3:  Page type (or linear address)

	sub	ecx,esp 	; Less current offset to get # bytes pushed
	mov	ah,@W95DPMI_PAGE_RESERVE ; Reserve some pages
	call	W95DPMI_FVEC	; Request W95DPMI.VxD service

	REGREST <ecx>		; Restore

	cmp	eax,-1		; Did it fail?
	je	short EMU_GETLMB_ERR1 ; Jump if so

	mov	esi,eax 	; Copy as handle
	mov	ebx,eax 	; Copy as linear address

	test	edx,@BIT0	; Commit the pages?
	jz	short EMU_GETLMB_DONE ; Jump if not

; Commit physical memory to the pages

	REGSAVE <ecx>		; Save for a moment

	lea	eax,[ecx+4*1024-1] ; Round up to 4KB boundary
	shr	eax,12-0	; Convert from bytes to 4KB

	mov	ecx,esp 	; Copy stack offset
	push	dword ptr (PC_USER or PC_WRITEABLE or PC_LOCKED) ; 1:  Pass flags
	push	dword ptr 0	; 2:  Pass pagerdata (none)
	push	dword ptr PD_NOINIT ; 3:  Pass hpd
	push	eax		; 4:  Pass # pages to commit

	mov	eax,ebx 	; Copy the linear address
	shr	eax,12-0	; Convert from bytes to 4KB
	push	eax		; 5: Pass the linear page #

	sub	ecx,esp 	; Less current offset to get # bytes pushed
	mov	ah,@W95DPMI_PAGE_COMMIT ; Commit some pages
	call	W95DPMI_FVEC	; Request W95DPMI.VxD service

	REGREST <ecx>		; Restore

	and	eax,eax 	; Did it succeed?
	jz	short EMU_GETLMB_ERR2 ; Jump if not
EMU_GETLMB_DONE:
	clc			; Mark as successful

	jmp	short EMU_GETLMB_EXIT ; Join common exit code

EMU_GETLMB_ERR1:
	mov	ax,@DPMIERR_NOLMEM ; Mark as no linear memory available

	jmp	short EMU_GETLMB_ERRCOM ; Join common code

EMU_GETLMB_ERR2:
	mov	ax,@DPMIERR_NOPMEM ; Mark as no physical memory available
;;;;;;;
;;;;;;; jmp	short EMU_GETLMB_ERRCOM ; Join common code
;;;;;;;
EMU_GETLMB_ERRCOM:
	int	03h		; Call our debugger

	stc			; Mark as in error
EMU_GETLMB_EXIT:
	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMU_GETLMB endp 		; End EMU_GETLMB procedure
	NPPROC	EMU_RELMEM -- Emulate Release Memory Block
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Emulate Release Memory Block

On entry:

AX	=	0502h
SI:DI	=	memory block handle

On exit:

If successful,

CF	=	0

If unsuccessful,

CF	=	1
AX	=	error code
		8023h	invalid handler

|

	push	ds		; Save for a moment

	mov	ds,SEL_DATA	; Address DGROUP
	assume	ds:DGROUP	; Tell the assembler about it

; Free the reserved pages

	REGSAVE <ecx>		; Save register

	mov	ecx,esp 	; Copy stack offset
	push	dword ptr 0	; 1:  No flags
	push	si		; 2H:  Pass the address
	push	di		; 2L:  ...
	sub	ecx,esp 	; Less current offset to get # bytes pushed
	mov	ah,@W95DPMI_PAGE_FREE ; Free some pages
	call	W95DPMI_FVEC	; Request W95DPMI.VxD service

	REGREST <ecx>		; Restore

	and	eax,eax 	; Did it succeed?
	jnz	short EMU_RELMEM_EXIT ; Jump if so (note CF=0)

	int	03h		; Call our debugger

	mov	ax,@DPMIERR_BADHNDL ; Mark as invalid handle

	stc			; Mark as unsuccessful
EMU_RELMEM_EXIT:
	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMU_RELMEM endp 		; End EMU_RELMEM procedure
	NPPROC	EMU_GPGATTR -- Emulate Get Page Attributes
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Emulate Get Page Attributes

On entry:

AX	=	0506h
ESI	=	memory block handle
EBX	=	offset within memory block of pages whose attributes
		are to be modified
ECX	=	# pages
ES:EDX	==>	buffer containing page attributes, one word per page

On exit:

If successful,

CF	=	0

If unsuccessful,

CF	=	1
AX	=	error code
		8001h	unsupported function
		8023h	invalid handle (in ESI)
		8025h	invalid linear address (specified range not within
			specified block)

|

	push	ds		; Save for a moment

	mov	ds,SEL_DATA	; Address DGROUP
	assume	ds:DGROUP	; Tell the assembler about it

	REGSAVE <>		; Save registers

	int	03h








	stc			; Mark as unsuccessful

	REGREST <>		; Restore

	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMU_GPGATTR endp		; End EMU_GPGATTR procedure
	NPPROC	EMU_SPGATTR -- Emulate Set Page Attributes
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Emulate Set Page Attributes

On entry:

AX	=	0507h
ESI	=	memory block handle
EBX	=	offset within memory block of pages whose attributes
		are to be modified
ECX	=	# pages
ES:EDX	==>	buffer containing page attributes, one word per page

On exit:

If successful,

CF	=	0

If unsuccessful,

CF	=	1
AX	=	error code
		8001h	unsupported function
		8002h	invalid state (page in wrong state for request)
		8013h	physical memory unavailable
		8014h	backing store unavailable
		8021h	invalid value (illelga request in bits 0-2 of one
			or more page attribute words)
		8023h	invalid handle (in ESI)
		8025h	invalid linear address (specified range not within
			specified block)

|

	push	ds		; Save for a moment

	mov	ds,SEL_DATA	; Address DGROUP
	assume	ds:DGROUP	; Tell the assembler about it

	REGSAVE <ecx,edx,esi,edi> ; Save registers

	jecxz	EMU_SPGATTR_DONE ; Jump if no pages to change
	add	esi,ebx 	; Add to get linear address
	shr	esi,12-0	; Convert from bytes to 4KB
EMU_SPGATTR_NEXT:
	mov	ax,es:[edx]	; Get the attribute word
	mov	edi,PC_USER or PC_LOCKED ; Get default attrs

	test	ax,@SPATTR_RW	; Izit to be read-write?
	jz	short @F	; Jump if not

	or	edi,PC_WRITEABLE ; Mark as such
@@:

; Check for bits we don't support

	test	ax,@SPATTR_RSVD or @SPATTR_DIRTY or @SPATTR_ACC or @SPATTR_MOD
	jnz	short EMU_SPGATTR_ERR1 ; Jump if any are set

	and	al,@SPATTR_TYP	; Isolate the type bits

;;;;;;; cmp	al,@SPTYP_MOD	; Izit to be modify attrs w/o page type?
;;;;;;; je	short EMU_SPGATTR_MOD ; Jump if so
;;;;;;;
;;;;;;; cmp	al,@SPTYP_UNC	; Izit to be uncommitted?
;;;;;;; je	short EMU_SPGATTR_UNC ; Jump if so
;;;;;;;
	cmp	al,@SPTYP_COM	; Izit to be committed?
	jne	short EMU_SPGATTR_ERR1 ; Jump if not

	REGSAVE <ecx>		; Save for a moment

	mov	ecx,esp 	; Copy stack offset
	push	edi		; 1:  Pass flags
	push	dword ptr 0	; 2:  Pass pagerdata (none)
	push	dword ptr PD_NOINIT ; 3:  Pass hpd
	push	dword ptr 1	; 4:  Pass # pages to commit
	push	esi		; 5:  Pass the linear page #
	sub	ecx,esp 	; Less current offset to get # bytes pushed
	mov	ah,@W95DPMI_PAGE_COMMIT ; Commit some pages
	call	W95DPMI_FVEC	; Request W95DPMI.VxD service

	REGREST <ecx>		; Restore

	and	eax,eax 	; Did it succeed?
	jz	short EMU_SPGATTR_ERR2 ; Jump if not

	inc	esi		; Skip to next linear page #
	add	edx,2		; Skip to next word

	loop	EMU_SPGATTR_NEXT ; Jump if more pages to change
EMU_SPGATTR_DONE:
	clc			; Mark as successful

	jmp	short EMU_SPGATTR_EXIT ; Join common exit code

EMU_SPGATTR_ERR1:
	mov	ax,@DPMIERR_BADVALUE ; Mark as invalid value

	jmp	short EMU_SPGATTR_ERRCOM ; Join common error code

EMU_SPGATTR_ERR2:
	mov	ax,@DPMIERR_NOPMEM ; Mark as no physical memory available
;;;;;;;
;;;;;;; jmp	short EMU_SPGATTR_ERRCOM ; Join common error code
;;;;;;;
EMU_SPGATTR_ERRCOM:
	stc			; Mark as unsuccessful
EMU_SPGATTR_EXIT:
	REGREST <edi,esi,edx,ecx> ; Restore

	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMU_SPGATTR endp		; End EMU_SPGATTR procedure
	NPPROC	EMU_SETEPMPEHV -- Emulate Set Extended PM Exception Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Emulate Set Extended PM Exception handler

On entry:

AX	=	0212h
BL	=	exception/fault # (00h-1Fh
CX:EDX	==>	new handler

On exit:

If successful,

CF	=	0

If unsuccessful,

CF	=	1
AX	=	error code
		8021h	invalid value (BL not in range 00h-1Fh)
		8022h	invalid selector

|

	push	ds		; Save for a moment

	mov	ds,SEL_DATA	; Address DGROUP
	assume	ds:DGROUP	; Tell the assembler about it

	REGSAVE <ebx,ecx,edx>	; Save registers

; We support intercepting Page Faults only

	cmp	bl,0Eh		; Izit Page Fault?
	jne	short EMU_SETEPMPEHV_ERR2 ; Jump if not

	mov	EPMPEHV0E_FVEC.FOFF,edx ; Save for later use
	mov	EPMPEHV0E_FVEC.FSEL,cx ; ...

; Save the old INT 0Eh handler address

;;;;;;; mov	bl,0Eh		; Intercept this one
	DPMICALL @DPMI_GETPEHV	; Return with CX:EDX ==> old handler
	jc	short EMU_SETEPMPEHV_ERR1 ; Jump if something went wrong

	mov	OLDLCL0E_FVEC.FOFF,edx ; Save for later use
	mov	OLDLCL0E_FVEC.FSEL,cx ; ...

; Set our INT 0Eh handler into place

;;;;;;; mov	bl,0Eh		; Intercept this one
	mov	cx,cs		; Get our code selector
	lea	edx,LCL_INT0E	; ...	       offset
	DPMICALL @DPMI_SETPEHV	; Set CX:EDX as new handler
	jc	short EMU_SETEPMPEHV_ERR1 ; Jump if something went wrong

;;;;;;; clc			; Mark as successful

	jmp	short EMU_SETEPMPEHV_EXIT ; Join common exit code

EMU_SETEPMPEHV_ERR1:
	int	03h		; Call our debugger
EMU_SETEPMPEHV_ERR2:
	mov	ax,@DPMIERR_BADVALUE ; Mark as invalid value

	stc			; Mark as unsuccessful
EMU_SETEPMPEHV_EXIT:
	REGREST <edx,ecx,ebx>	; Restore

	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMU_SETEPMPEHV endp		; End EMU_SETEPMPEHV procedure
	FPPROC	LCL_INT0E -- Local INT 0Eh Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local INT 0Eh handler

On entry:

|

LCL0E_STR struc

LCL0E_EBP  dd	?		; Caller's EBP
LCL0E_REIP dd	?		; Return CS:EIP
LCL0E_RCS  dw	?,?		; ...
LCL0E_ERR  dd	?		; Error code
LCL0E_EIP  dd	?		; Faulting CS:EIP
LCL0E_CS   dw	?,?		; ...
LCL0E_EFL  dd	?		; ...	   EFL
LCL0E_ESP  dd	?		; ...	   SS:ESP
LCL0E_SS   dw	?,?		; ...

LCL0E_STR ends


EPM0E_STR struc

;;;0E_REIP dd	?		; Return CS:EIP
;;;0E_RCS  dw	?,?		; ...
EPM0E_ERR  dd	?		; Error code
EPM0E_EIP  dd	?		; Faulting CS:EIP
EPM0E_CS   dw	?		; ...
EPM0E_EIB  dw	?		; ...	   Exception Information Bits
EPM0E_EFL  dd	?		; ...	   EFL
EPM0E_ESP  dd	?		; ...	   SS:ESP
EPM0E_SS   dw	?,?		; ...
EPM0E_ES   dw	?,?		; ...	   ES
EPM0E_DS   dw	?,?		; ...	   DS
EPM0E_FS   dw	?,?		; ...	   FS
EPM0E_GS   dw	?,?		; ...	   GS
EPM0E_CR2  dd	?		; ...	   CR2
EPM0E_PTE  dd	?		; ...	   PTE

EPM0E_STR ends


XPM0E_STR struc

XPM0E_EPM db	(type EPM0E_STR) dup (?) ; EPM0E_STR
XPM0E_LCL db	(type LCL0E_STR) dup (?) ; LCL0E_STR

XPM0E_STR ends


LPM0E_STR struc

;;;0E_REIP dd	?		; Return CS:EIP
;;;0E_RCS  dw	?,?		; ...
LPM0E_ERR  dd	?		; Error code
LPM0E_EIP  dd	?		; Faulting CS:EIP
LPM0E_CS   dw	?,?		; ...
LPM0E_EFL  dd	?		; ...	   EFL
LPM0E_ESP  dd	?		; ...	   SS:ESP
LPM0E_SS   dw	?,?		; ...
LPM0E_CSEIP dq	?		; Return CS:EIP
LPM0E_EPM db	(type EPM0E_STR) dup (?) ; EPM0E_STR
LPM0E_LCL db	(type LCL0E_STR) dup (?) ; LCL0E_STR

LPM0E_STR ends

	push	ebp		; Save for a moment
	mov	ebp,esp 	; Address the stack

; Pass this exception on to the local Page Fault handler

	sub	esp,type EPM0E_STR ; Make room for EPM struc

	PUSHD	cs		; Pass return CS:EIP
	push	dword ptr (offset NGROUP:LCL_INT0E_RET2) ; ...

; Push the bottom half of the final struc

	push	[ebp].LCL0E_SS.EDD  ; Pass SS:ESP
	push	[ebp].LCL0E_ESP     ; ...
	push	[ebp].LCL0E_EFL     ; ...  EFL
	push	[ebp].LCL0E_CS.EDD  ; ...  CS:EIP
	push	[ebp].LCL0E_EIP     ; ...
	push	[ebp].LCL0E_ERR     ; ...  error code

	mov	ebp,esp 	; SS:EBP ==> LPM0E_STR with all but
				; LPM0E_EPM filled in
	push	[ebp].LPM0E_ERR ; Pass error code
	pop	[ebp].LPM0E_EPM.EPM0E_ERR ; ...

	push	[ebp].LPM0E_EIP ; Pass EIP
	pop	[ebp].LPM0E_EPM.EPM0E_EIP ; ...

	push	[ebp].LPM0E_CS	; Pass CS
	pop	[ebp].LPM0E_EPM.EPM0E_CS ; ...

	push	[ebp].LPM0E_EFL ; Pass EFL
	pop	[ebp].LPM0E_EPM.EPM0E_EFL ; ...

	push	[ebp].LPM0E_ESP ; Pass ESP
	pop	[ebp].LPM0E_EPM.EPM0E_ESP ; ...

	push	[ebp].LPM0E_SS	; Pass SS
	pop	[ebp].LPM0E_EPM.EPM0E_SS ; ...

	mov	[ebp].LPM0E_EPM.EPM0E_DS,ds ; Pass DS
	mov	[ebp].LPM0E_EPM.EPM0E_ES,es ; ...  ES
	mov	[ebp].LPM0E_EPM.EPM0E_FS,fs ; ...  FS
	mov	[ebp].LPM0E_EPM.EPM0E_GS,gs ; ...  GS

	mov	[ebp].LPM0E_EPM.EPM0E_EIB,0 ; Pass EIB

	push	eax		; Save for a moment

	mov	eax,cr2 	; Get Page Fault linear address

	mov	[ebp].LPM0E_EPM.EPM0E_CR2,eax ; Pass CR2
	mov	[ebp].LPM0E_EPM.EPM0E_PTE,0 ; Pass PTE

	pop	eax		; Restore

	mov	ebp,[ebp].LPM0E_LCL.LCL0E_EBP ; Restore caller's EBP

	PUSHD	cs		    ; Pass return CS:EIP
	push	dword ptr (offset NGROUP:LCL_INT0E_RET1) ; ...

	PUSHW	ds		; Save for a moment
	mov	ds,SEL_DATA	; Address DGROUP
	assume	ds:DGROUP	; Tell the assembler about it

	push	EPMPEHV0E_FVEC.FSEL ; Pass the selector
	push	EPMPEHV0E_FVEC.FOFF ; ...      offset

L0E_STR struc

	df	?		; Next handler address
L0E_DS	dw	?		; Caller's DS

L0E_STR ends

	mov	ds,[esp].L0E_DS ; Get next handler's DS
	assume	ds:nothing	; Tell the assembler about it

	RETFD			; Continue with next handler

LCL_INT0E_RET1:

; The caller returned with the entire stack intact
; Copy (possibly) changed values back to caller's stack

	mov	[esp].LPM0E_LCL.LCL0E_EBP,ebp ; Save to restore later
	mov	ebp,esp 	; SS:EBP ==> LPM0E_STR

	push	[ebp].LPM0E_ERR ; Pass error code
	pop	[ebp].LPM0E_LCL.LCL0E_ERR ; ...

	push	[ebp].LPM0E_EIP ; Pass EIP
	pop	[ebp].LPM0E_LCL.LCL0E_EIP ; ...

	push	[ebp].LPM0E_CS	; Pass CS
	pop	[ebp].LPM0E_LCL.LCL0E_CS ; ...

	push	[ebp].LPM0E_EFL ; Pass EFL
	pop	[ebp].LPM0E_LCL.LCL0E_EFL ; ...

	push	[ebp].LPM0E_ESP ; Pass ESP
	pop	[ebp].LPM0E_LCL.LCL0E_ESP ; ...

	push	[ebp].LPM0E_SS	; Pass SS
	pop	[ebp].LPM0E_LCL.LCL0E_SS ; ...

	add	esp,(type LPM0E_STR) - (type LCL0E_STR) ; Strip from the stack

	jmp	short LCL_INT0E_EXIT ; Join common exit code


LCL_INT0E_RET2:

; The caller returned with the upper portion of the stack only
; Copy (possibly) changed values back to caller's stack

	mov	[esp].XPM0E_LCL.LCL0E_EBP,ebp ; Save to restore later
	mov	ebp,esp 	; SS:EBP ==> XPM0E_STR

	push	[ebp].XPM0E_EPM.EPM0E_ERR ; Pass error code
	pop	[ebp].XPM0E_LCL.LCL0E_ERR ; ...

	push	[ebp].XPM0E_EPM.EPM0E_EIP ; Pass EIP
	pop	[ebp].XPM0E_LCL.LCL0E_EIP ; ...

	push	[ebp].XPM0E_EPM.EPM0E_CS ; Pass CS
	pop	[ebp].XPM0E_LCL.LCL0E_CS ; ...

	push	[ebp].XPM0E_EPM.EPM0E_EFL ; Pass EFL
	pop	[ebp].XPM0E_LCL.LCL0E_EFL ; ...

	push	[ebp].XPM0E_EPM.EPM0E_ESP ; Pass ESP
	pop	[ebp].XPM0E_LCL.LCL0E_ESP ; ...

	push	[ebp].XPM0E_EPM.EPM0E_SS ; Pass SS
	pop	[ebp].XPM0E_LCL.LCL0E_SS ; ...

;;;;;;; mov	ds,[ebp].XPM0E_EPM.EPM0E_DS ; Restore
;;;;;;; assume	ds:nothing	; Tell the assembler about it
;;;;;;; mov	es,[ebp].XPM0E_EPM.EPM0E_ES ; ...
;;;;;;; assume	es:nothing	; Tell the assembler about it
;;;;;;; mov	fs,[ebp].XPM0E_EPM.EPM0E_FS ; ...
;;;;;;; assume	fs:nothing	; Tell the assembler about it
;;;;;;; mov	gs,[ebp].XPM0E_EPM.EPM0E_GS ; ...
;;;;;;; assume	gs:nothing	; Tell the assembler about it
;;;;;;;
	add	esp,(type XPM0E_STR) - (type LCL0E_STR) ; Strip from the stack
LCL_INT0E_EXIT:
	pop	ebp		; Restore

	RETFD			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT0E endp			; End LCL_INT0E procedure

NCODE	ends			; End NCODE segment

	MEND			; End QLNK_W95 module
