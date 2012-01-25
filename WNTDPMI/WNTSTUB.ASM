;' $Header$
	title	WNTSTUB -- Stub Program for WNTDPMI.EXE
	page	58,122
	name	WNTSTUB

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
	include INTVEC.INC
	include ISVBOP.INC

	include WNTDPMI.INC
	include WNTSTSEG.INC
.list

; --------------------------------------------------------------

PSPGRP	group	PSP_SEG

PSP_SEG segment use16 at 0	; Start PSP_SEG segment
	assume	cs:PSPGRP,ds:PSPGRP
.xlist
	include PSP.INC
.list

PSP_SEG ends			; End PSP_SEG segment


CODE	segment 		; Start CODE segment
	assume	cs:PGROUP,ds:PGROUP

	extrn	PRINTF16:near

	public	DATASEG
DATASEG dw	seg DGROUP	; DGROUP data segment/selector

CODE	ends			; End CODE segment


LDATA	segment 		; Start LDATA segment
	assume	ds:PGROUP

	extrn	OLDINT21_FVEC:qword
	extrn	OLDINT31_FVEC:qword
	extrn	DPMITYPE:byte

	public	ClientIndex
ClientIndex dd	0		; Index of next available DPMI client

	public	OLDINT2F_VEC,OURINT2F_VEC
OLDINT2F_VEC dd ?		; Old VM INT 2Fh handler
OURINT2F_VEC dd PGROUP:LCL_INT2F ; Our ...

	public	DPMIDRV_VEC,LCLDRV_VEC
DPMIDRV_VEC dd	 ?		; DPMI driver address
LCLDRV_VEC dd	 PGROUP:LCLDRV	; Local ...

	public	VSAPI_VEC
VSAPI_VEC dd	PGROUP:LCL_VSAPI ; Ptr to VS API entry point

	public	DATASEL
DATASEL dw	?		; Data selector

;;;;	     public  CODE32SEL
;;;; CODE32SEL dw    ?		     ; 32-bit code selector

	public	ModuleHandle
ModuleHandle dw ?		; Module handle for DispatchCall

	public	PSPSEG
PSPSEG	dw	?		; PSP segment

	public	SIGNATURE
SIGNATURE db	WNTTITLE,0	; Resident signature
SIGNATURE_LEN equ $-SIGNATURE	; Length of ...

	public	bActive
bActive db	TRUE		; TRUE = active, FALSE = not

LDATA	ends			; End LDATA segment


CODE16	segment 		; Start CODE16 segment
	assume	cs:PGROUP

	extrn	PTRINT21_LCL:near
	extrn	PTRINT21_LCLLG2:abs

	extrn	PTRINT31_LCL:near
	extrn	PTRINT31_LCLLG2:abs

CODE16	ends			; End CODE16 segment


CODE16	segment 		; Start CODE16 segment
	assume	cs:PGROUP

	FPPROC	LCL_VSAPI -- Local Vendor-Specific API Entry Point
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local vendor-specific entry point

On entry:

AX	=	function # (see VSAPI_xxx)

On exit:

Depends upon the function

|

	cmp	ax,@VSAPI_DISABLE ; Disabling?
	je	short LCL_VSAPI_DIS ; Jump if so

	cmp	ax,@VSAPI_ENABLE ; Enabling?
	je	short LCL_VSAPI_ENA ; Jump if so

	cmp	ax,@VSAPI_UNLOAD ; Unloading?
	je	short LCL_VSAPI_UNL ; Jump if so

	jmp	short LCL_VSAPI_ERR ; Join common error code


LCL_VSAPI_DIS:
.8086
	mov	bActive,FALSE	; Mark as disabled
DOT386 p
	jmp	short LCL_VSAPI_DONE ; Join common done code


LCL_VSAPI_ENA:
.8086
	mov	bActive,TRUE	; Mark as enabled
DOT386 p
	jmp	short LCL_VSAPI_DONE ; Join common done code


LCL_VSAPI_UNL:

; If we're the current holder of INT 2Fh, restore it

	REGSAVE <eax,fs>	; Save registers

	xor	ax,ax		; Segment # of IVT
	mov	fs,ax		; Address it
	assume	fs:INTVEC	; Tell the assembler about it

	mov	eax,INT00_VEC[2Fh * (type INT00_VEC)] ; Get INT 2Fh handler

	cmp	eax,OURINT2F_VEC ; Izit us?
	jne	short @F	; Jump if not

	mov	eax,OLDINT2F_VEC ; Get previous handler
	mov	INT00_VEC[2Fh * (type INT00_VEC)],eax ; Restore
@@:
	REGREST <fs,eax>	; Restore
	assume	fs:nothing	; Tell the assembler about it

; Unregister our module

	mov	ax,ModuleHandle ; Get the module handle
	UnRegisterModule	; Unregister the module

; Free our memory

	push	es		; Save for a moment

	mov	es,PSPSEG	; Get segment of PSP
	assume	es:PSPGRP	; Tell the assembler about it

	DOSCALL @RELMEM 	; Free the memory at ES:0
	pop	es		; Restore
	assume	es:PGROUP	; Tell the assembler about it
	jnc	short LCL_VSAPI_DIS ; Join common disable code
LCL_VSAPI_ERR:
	mov	ax,FALSE	; Mark as in error

	jmp	short LCL_VSAPI_EXIT ; Join common exit code


LCL_VSAPI_DONE:
	mov	ax,TRUE 	; Mark as successful
LCL_VSAPI_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_VSAPI endp			; End LCL_VSAPI procedure
	FPPROC	LCLDRV -- Local DPMI PM Entry Point
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local DPMI PM Entry Point

On entry:

AX	=	Bit 0 = 0 if 16-bit client
		      = 1 if 32-bit client

On exit:

CF	=	0 if successful
CS	=	16-bit code selector  (from VM CS)
SS	=	16-bit stack selector (from VM SS)
DS	=	16-bit data selector  (from VM DS)
ES	=	PSP selector
FS	=	0
GS	=	0

CF	=	1 if error

|

LCLDRV_STR struc

LCLDRV_EGP db	(type PUSHAD_STR) dup (?) ; Caller's EGPs
LCLDRV_CSIP dd	?		; Return CS:IP

LCLDRV_STR ends

	push	ax		; Save 16-/32-bit flag
	call	DPMIDRV_VEC	; Call down to the DPMI host
	pop	ax		; Restore
	jc	near ptr LCLDRV_EXIT ; Jump if something went wrong (note CF=1)

	pushad			; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

; Clear the high-order word of EBP/ESP if SS is a 16-bit selector

	IF16STK <sp,bp>

; Convert the caller's return CS from segment to selector

	mov	bx,[ebp].LCLDRV_CSIP.VSEG ; Get the segment
	DPMICALL @DPMI_SEG2SEL	; Convert to selector
;;;;;;; jc	short ???	; Ignore error return

; In case the selector returned is being used for data, get an alias of it

	mov	bx,ax		; Get data selector
	DPMICALL @DPMI_GETALIAS ; Return with AX = data alias
;;;;;;; jc	short ???	; Ignore error return

; Mark it as a 16-bit code selector

	mov	[ebp].LCLDRV_CSIP.VSEG,ax ; Save in stack
	mov	bx,ax		; Copy to DPMI selector register
	mov	cl,CPL0_CODE or DPL3 ; Get A/R byte
	mov	ch,0		; Clear the B-bit
	DPMICALL @DPMI_SSELARW	; Set the selector's A/R word
;;;;;;; jc	short ???	; Ignore error return

; Create an alias of our code selector for data

	mov	bx,cs		; Get code selector
	DPMICALL @DPMI_GETALIAS ; Convert to data selector
;;;;;;; jc	short ???	; Ignore error return

	push	ds		; Save for a moment

	mov	ds,ax		; Address it
	assume	ds:PGROUP	; Tell the assembler about it

	mov	DATASEL,ax	; Save for later use

; Create a selector for DGROUP for use by PRINTF

	mov	bx,seg DGROUP	; Get DGROUP data segment
	DPMICALL @DPMI_SEG2SEL	; Convert to selector
;;;;;;; jc	short ???	; Ignore error return

	mov	DATASEG,ax	; Save for use by PRINTF

;;;; ; Create an alias of our code selector as a 32-bit selector
;;;;
;;;;	     mov     bx,cs	     ; Get code selector
;;;;	     DPMICALL @DPMI_GETALIAS ; Convert to data selector
;;;; ;;;;;;; jc      short ???	     ; Ignore error return
;;;;
;;;;	     mov     CODE32SEL,ax    ; Save for later use
;;;;	     mov     bx,ax	     ; Copy to DPMI selector register
;;;;
;;;; ; Mark it as a 32-bit code selector
;;;;
;;;;	     mov     cl,CPL0_CODE or DPL3 ; Get A/R byte
;;;;	     mov     ch,mask $DTE_B  ; Set the B-bit
;;;;	     DPMICALL @DPMI_SSELARW  ; Set the selector's A/R word
;;;; ;;;;;;; jc      short ???	     ; Ignore error return
;;;;
; Store and increment current client index

	mov	esi,ClientIndex ; Save current value
	inc	ClientIndex	; Skip to next value

; Save the bitness in DPMITYPE

	test	[ebp].LCLDRV_EGP.PUSHAD_EAX.ELO.LO,@DPMI_EPM_32 ; Izit 32-bit client?
	jz	short LCLDRV_BIT16 ; Jump if not

	bts	DPMITYPE.ELO,si ; Set the bit

	jmp	short LCLDRV_BITCOM ; Join common code


LCLDRV_BIT16:
	btr	DPMITYPE.ELO,si ; Clear the bit
LCLDRV_BITCOM:

; Hook INT 31h so we can launder DPMI 1.0 calls

	xor	edx,edx 	; Zero to use as dword
				; in case we're a 16-bit client
	mov	bl,31h		; Interrupt #
	DPMICALL @DPMI_GETPMIV	; Get the PM interrupt vector
;;;;;;; jc	short ???	; Ignore error return

	mov	OLDINT31_FVEC.FOFF[esi * (type OLDINT31_FVEC)],edx ; Save for later use
	mov	OLDINT31_FVEC.FSEL[esi * (type OLDINT31_FVEC)],cx  ; ...

;;;;;;; mov	cx,CODE32SEL	; CS:eDX ==> local handler
	mov	cx,cs		; CS:eDX ==> local handler
	mov	edx,esi 	; Copy to destroy
	shl	edx,PTRINT31_LCLLG2 ; Shift by block length
	lea	edx,PTRINT31_LCL[edx]  ; ...
;;;;;;; mov	bl,31h		; Interrupt #
	DPMICALL @DPMI_SETPMIV	; Set the PM interrupt vector
;;;;;;; jc	short ???	; Ignore error return

; Hook INT 21h so we can catch DPMI client termination

	xor	edx,edx 	; Zero to use as dword
				; in case we're a 16-bit client
	mov	bl,21h		; Interrupt #
	DPMICALL @DPMI_GETPMIV	; Get the PM interrupt vector
;;;;;;; jc	short ???	; Ignore error return

	mov	OLDINT21_FVEC.FOFF[esi * (type OLDINT21_FVEC)],edx ; Save for later use
	mov	OLDINT21_FVEC.FSEL[esi * (type OLDINT21_FVEC)],cx  ; ...

;;;;;;; mov	cx,CODE32SEL	; CS:eDX ==> local handler
	mov	cx,cs		; CS:eDX ==> local handler
	mov	edx,esi 	; Copy to destroy
	shl	edx,PTRINT21_LCLLG2 ; Shift by block length
	lea	edx,PTRINT21_LCL[edx]  ; ...
;;;;;;; mov	bl,21h		; Interrupt #
	DPMICALL @DPMI_SETPMIV	; Set the PM interrupt vector
;;;;;;; jc	short ???	; Ignore error return

	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popad			; Restore

	clc			; Mark as successful
LCLDRV_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCLDRV	endp			; End LCLDRV procedure
	FPPROC	LCL_INT2F -- Local INT 2Fh Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local VM INT 2Fh handler

On entry:

AX	=	function code

On exit:

Depends upon the entry vars.

|

	cmp	ax,@DPMI_GPME	; Izit DPMI presence check?
	jne	short LCL_INT2F1 ; Jump if not

	cmp	bActive,TRUE	; Are we active?
	jne	short LCL_INT2F_ORIG ; Jump if not

	push	ax		; Make room for the flags
	push	bp		; Save for a moment
	mov	bp,sp		; Address the stack

I2F_STR struc

	dw	?		; Callers' BP
I2F_AX	dw	?		; ...	   AX
	dd	?		; Return CS:IP
I2F_FL	dw	?		; ...	 FL

I2F_STR ends

	mov	ax,[bp].I2F_FL	; Get the caller's flags
	xchg	ax,[bp].I2F_AX	; Swap with original AX

	pop	bp		; Restore

;;;;;;; pushf			; Pass the flags
	cli			; Simulate INT environment
	call	OLDINT2F_VEC	; Pass on to previous handler

	and	ax,ax		; Izit present
	jnz	short LCL_INT2F_DONE ; Jump if not
.8086
	mov	DPMIDRV_VEC.VSEG,es ; Save for later use
	mov	DPMIDRV_VEC.VOFF,di ; ...
DOT386 p
	les	di,LCLDRV_VEC	; ES:DI ==> our DPMI PM Entry Point
	assume	es:nothing	; Tell the assembler about it
LCL_INT2F_DONE:
	ret	2		; Return to caller, popping flags


	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
LCL_INT2F1:
	cmp	ax,168Ah	; Izit Get Vendor-specific API Entry Point?
	jne	short LCL_INT2F2 ; Jump if not

	cmp	bActive,TRUE	; Are we active?
	jne	short LCL_INT2F_ORIG ; Jump if not

	REGSAVE <cx,si,di,es>	; Save registers

	push	cs		; Get our code/data segment
	pop	es		; Address it
	assume	es:PGROUP	; Tell the assembler about it

	lea	di,SIGNATURE	; ES:DI ==> local signature
	mov	cx,SIGNATURE_LEN ; CX = length of ...
	cld			; String ops forwards
   repe cmps	ds:[si].LO,SIGNATURE[di] ; Compare 'em

	REGREST <es,di,si,cx>	; Restore
	assume	es:nothing	; Tell the assembler about it
	jne	short LCL_INT2F_ORIG ; Jump if not

	les	di,VSAPI_VEC	; ES:DI ==> VSAPI entry point
	assume	es:nothing	; Tell the assembler about it

	mov	al,0		; Mark as successful

	iret			; Return to caller


	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
LCL_INT2F2:



LCL_INT2F_ORIG:
	jmp	OLDINT2F_VEC	; Continue with next handler in sequence

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT2F endp			; End LCL_INT2F procedure

CODE16	ends			; End CODE16 segment


NDATA	segment 		; Start NDATA segment
	assume	ds:PGROUP

	extrn	LCL_FLAG:word

	public	ZTAIL
ZTAIL	label	byte

;;;;	     public  DPMI_HPDA,DPMI_VER,DPMI_CPU,DPMI_FLAG
;;;; DPMI_HPDA dw     ? 	     ; DPMI HPDA size in paras
;;;; DPMI_VER dw     ?		     ; DPMI version #
;;;; DPMI_FLAG dw    ?		     ; DPMI flags
;;;; DPMI_CPU db     ?,0	     ; DPMI CPU

	public	ERRCODE
ERRCODE db	-1		; Return code for DOS (assumes error)

	public	MSG_COPY
MSG_COPY db	'WNTDPMI -- Version 0.01 ',CR,LF
	db	'   (C) Copyright 2003 Qualitas, Inc. '
	db	' All rights reserved.',CR,LF,EOS

	public	MSG_BADVER,MSG_NODPMI
MSG_BADVER db	BEL,'ออ> Incorrect version #:  Win NT/2000/XP only.',CR,LF,EOS
MSG_NODPMI db	BEL,'ออ> No DPMI present:  be sure to run DOSX.EXE first.',CR,LF,EOS

	public	MSG_ERRINST
MSG_ERRINST db	BEL,'*** Already installed.',CR,LF
	db	EOS

	public	ModuleName,DispatchName,InitName
ModuleName db	WNTFNAM,'.dll',0 ; Module name
DispatchName db WNTFNAM,'_Dispatch',0 ; Dispatch name
InitName db	WNTFNAM,'_Init',0 ; Initialzation name

	public	FMT_NOVDD,FMT_2FADDR
FMT_NOVDD  db	BEL,'ออ> No VDD present:  RC=%u.',CR,LF,0
FMT_2FADDR db	'Original INT 2Fh = %04X:%04X',CR,LF,0

	public	MSG_NOVDD1,MSG_NOVDD2,MSG_NOVDD3,MSG_NOVDD4
MSG_NOVDD1 db	    '    DLL not found.',CR,LF,0
MSG_NOVDD2 db	    '    Dispatch routine not found.',CR,LF,0
MSG_NOVDD3 db	    '    Init routine not found.',CR,LF,0
MSG_NOVDD4 db	    '    Insufficient memory.',CR,LF,0

	public	NOVDDTAB
NOVDDTAB dw	offset PGROUP:MSG_NOVDD1
	dw	offset PGROUP:MSG_NOVDD2
	dw	offset PGROUP:MSG_NOVDD3
	dw	offset PGROUP:MSG_NOVDD4

NDATA	ends			; End NDATA segment


NCODE	segment 		; Start NCODE segment
	assume	cs:PGROUP

	extrn	CheckInstalled:near
	extrn	CheckArgs:near

	NPPROC	WNTSTUB -- Start of WNTDPMI Stub
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

; Address PGROUP with DS & ES

	mov	ax,cs		; Get PGROUP segment
	mov	ds,ax		; Address it
	assume	ds:PGROUP	; Tell the assembler about it

	mov	PSPSEG,es	; Save for later use

	mov	es,ax		; Address PGROUP
	assume	es:PGROUP	; Tell the assembler about it

	DOSCALL @STROUT,MSG_COPY ; Display our copyright

	call	CheckInstalled	; Are we already installed?

	call	CheckArgs	; Check the argument list
	jc	near ptr WNTSTUB_BADARG ; Jump if it's not right

; See if we should go resident

	test	LCL_FLAG,@LCL_NRES ; Are we going resident?
	jnz	near ptr WNTSTUB_EXIT ; Jump if not

; Check to see if we're already installed

	test	LCL_FLAG,@LCL_INST ; Are we already installed?
	jnz	near ptr WNTSTUB_ERRINST ; Jump if so

; Check DOS version # as we run on Win NT/2000/XP only

	call	CheckDOSVer	; Check on it
	jc	near ptr WNTSTUB_BADVER ; Jump if it's not right

; Check for DPMI host

	call	CheckDPMI	; See if we're running under a DPMI host
	jc	near ptr WNTSTUB_NODPMI ; Jump if not present

; Save original INT 2Fh address

	push	es		; Save for a moment

	mov	al,2Fh		; Interrupt #
	DOSCALL @GETINT 	; Request DOS service
				; Return with ES:BX ==> old handler
	mov	OLDINT2F_VEC.VSEG,es ; Save for later use
	mov	OLDINT2F_VEC.VOFF,bx ; ...

	pop	es		; Restore
	assume	es:PGROUP	; Tell the assembler about it

; Display old INT 2Fh address

	push	OLDINT2F_VEC.VOFF ; Pass ptr to address
	push	OLDINT2F_VEC.VSEG ; ... 
	push	ds		; ...  ptr to format string
	push	offset ds:FMT_2FADDR ; ...
	call	PRINTF16	; Printf the argument
	add	sp,4+4		; Strip from the stack

;;;; ; Get the full DPFE of this program
;;;;
;;;;	     push    es 	     ; Save for a moment
;;;;
;;;;	     mov     es,PSPSEG	     ; Get segment of PSP
;;;;	     assume  es:PSPGRP	     ; Tell the assembler about it
;;;;
;;;;	     mov     es,es:[0].PSP_ENVIR_PTR ; Get the environment segment
;;;;	     assume  es:nothing      ; Tell the assembler about it
;;;;
;;;; ; Loop through the environment to get to the strings section
;;;;
;;;;	     xor     di,di	     ; ES:DI ==> start of environment
;;;;	     mov     al,0	     ; String terminator
;;;; @@:
;;;;	     mov     cx,-1	     ; We know it's there
;;;;   repne scas    es:[di].LO      ; Search for it
;;;; ;;;;;;; jne     short ???	     ; Jump if not found???
;;;;
;;;;	     scas    es:[di].LO      ; Is the next byte the end of the Set variables?
;;;;	     jne     short @B	     ; Jump if not
;;;;
;;;;	     add     di,2	     ; Skip over the string count
;;;;
;;;; ; ES:DI ==> d:\path\filename.ext of this program
;;;; ; Copy to ModuleDPFE
;;;;
;;;;	     mov     si,es	     ; Copy PSP segment
;;;;	     mov     fs,si	     ; Address it
;;;;	     assume  fs:PSPGRP	     ; Tell the assembler about it
;;;;
;;;;	     mov     si,di	     ; FS:SI ==> DPFE
;;;;
;;;;	     pop     es 	     ; Restore
;;;;	     assume  es:PGROUP	     ; Tell the assembler about it
;;;;
;;;;	     lea     di,ModuleDPFE   ; ES:DI ==> ModuleDPFE
;;;; WNTSTUB1:
;;;;	     lods    fs:[si].LO      ; Get next byte
;;;;	     stos    ModuleDPFE[di]  ; Save in output
;;;;
;;;;	     cmp     al,'.'          ; Izit extension separator?
;;;;	     jne     short @F	     ; Jump if not
;;;;
;;;;	     mov     bx,di	     ; Copy offset of next byte after dot
;;;; @@:
;;;;	     and     al,al	     ; Izit EOS?
;;;;	     jnz     short WNTSTUB1  ; Jump if not
;;;;
;;;; ; Form the .DLL name
;;;;
;;;;	     mov     PGROUP:[bx].EDD,'LDD' ; Blast in new extension
;;;;
;;;; ; Register the VDD module
;;;;
;;;;	     lea     si,ModuleDPFE   ; DS:SI ==> module d:\path\filename.ext

; Register the VDD module

	test	LCL_FLAG,@LCL_NOWIN ; Ignore Windows requirement?
	jnz	short @F	; Jump if so (Skip registering module)

	lea	si,ModuleName	; DS:SI ==> module d:\path\filename.ext
	lea	bx,DispatchName ; DS:BX ==> dispatch name
	lea	di,InitName	; ES:DI ==> initialization name
	stc			; Just in case
	xor	ax,ax		; Set to known value *DEBUG*
	RegisterModule		; Call the powers that be
				; If CF=0, AX = handle
				; If CF=1, AX = 1 - DLL not found
				;	   AX = 2 - Dispatch routine not found
				;	   AX = 3 - Init Routine Not Found
				;	   AX = 4 - Insufficient Memory
	jc	short WNTSTUB_NOVDD ; Jump if something went wrong

	mov	ModuleHandle,ax ; Save for later use
@@:

; Hook INT 2Fh

	mov	al,2Fh		; Interrupt #
	DOSCALL @SETINT,LCL_INT2F ; Put our handler into effect

; Free the environment

	mov	es,PSPSEG	; Get the PSP segment
	assume	es:PSPGRP	; Tell the assembler about it

	xor	ax,ax		; A convenient zero
	xchg	ax,es:[0].PSP_ENVIR_PTR ; Get and zero the environment segment
	mov	es,ax		; Address it
	assume	es:nothing	; Tell the assembler about it

	DOSCALL @RELMEM 	; Free the memory

	mov	ERRCODE,0	; Mark as successful

; Go resident

	mov	ax,cs		; Get PGROUP segment
	sub	ax,PSPSEG	; Less PSP segment
	lea	dx,ZTAIL[16-1]	; Get ending offset in PGROUP, rounded
				; up to to para boundary plus size of PSP
	shr	dx,4-0		; Convert from bytes to paras
	add	dx,ax		; Add to get ending para
	mov	al,ERRCODE	; Get return code
	DOSCALL @KEEPRC 	; Return to DOS, staying resident
				; No return from this call
	cli			; We should never get here
	hlt			; ...


	assume	es:PGROUP	; Tell the assembler about it
WNTSTUB_ERRINST:
	DOSCALL @STROUT,MSG_ERRINST ; Tell 'em the bad news

	jmp	short WNTSTUB_ERRCOM ; Join common error exit code


WNTSTUB_NOVDD:
	mov	si,ax		; Save error code

	push	si		; Pass error code
	push	es		; ...  ptr to format string
	push	offset es:FMT_NOVDD ; ...
	call	PRINTF16	; Printf the argument
	add	sp,4+2		; Strip from the stack

	cmp	si,4		; Izit abov the upper limit?
	ja	short @F	; Jump if so

	dec	si		; Convert to origin-0
	shl	si,1-0		; Convert from words to bytes

	push	es		; Pass ptr to format string
	push	NOVDDTAB[si]	; ...
	call	PRINTF16	; Printf the argument
	add	sp,4		; Strip from the stack
@@:
	jmp	short WNTSTUB_ERRCOM ; Join common error exit code


WNTSTUB_NODPMI:
	DOSCALL @STROUT,MSG_NODPMI ; Tell 'em the bad news

	jmp	short WNTSTUB_ERRCOM ; Join common error exit code


WNTSTUB_BADVER:
	DOSCALL @STROUT,MSG_BADVER ; Tell 'em the bad news
WNTSTUB_BADARG:
WNTSTUB_ERRCOM:
WNTSTUB_EXIT:
	mov	al,ERRCODE	; Get return code
	DOSCALL @EXITRC 	; Return to DOS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WNTSTUB endp			; End WNTSTUB procedure
	NPPROC	CheckDOSVer -- Check DOS Version #
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check DOS version #

On entry:

Nothing

On exit:

CF	=	0 if good version #
	=	1 if not

|

	REGSAVE <ax,bx,dx>	; Save registers

	DOSCALL @GETDVER	; Get DOS version #
				; Return with BL = major version #
				;	      BH = minor ...
				;	      DL = revision # in bits 0:2
				;	      DH = version flags
				;	      AL = FF if true DOS version is < 5.0
	jc	short CheckDOSVerExit ; Jump if not supported

	xchg	bh,bl		; Swap to comparison order

	cmp	al,0FFh 	; Is true DOS version # < 5.0?
	je	short CheckDOSVerErr ; Jump if so

	cmp	bx,0532h	; Izit 5.50 from Win NT/2000?
	je	short CheckDOSVerExit ; Jump if so (note CF=0)

;;;;;;; cmp	bx,		; Izit Win NT 4.0?


;;;;;;; cmp	bx,		; Izit Win XP?






	test	LCL_FLAG,@LCL_NOWIN ; Ignore Windows requirement?
	jnz	short CheckDOSVerExit ; Jump if so (Skip registering module)
				; Note CF=0
CheckDOSVerErr:
	stc			; Mark as bad version #
CheckDOSVerExit:
	REGREST <dx,bx,ax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CheckDOSVer endp		; End CheckDOSVer procedure
	NPPROC	CheckDPMI -- Check On DPMI Services
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on DPMI services

On entry:

Nothing

On exit:

CF	=	0 if successful
	=	1 if not

|

	pusha			; Save all GP registers
	push	es		; Save

	mov	ax,@DPMI_GPME	; Function code to detect DPMI servcices
	int	2Fh		; Request multiplexor services
	assume	es:nothing	; Tell the assembler about it
				; On return
				;   AX	  =   0 (if present)
				;   BX	  =   flags -- Bit 0: 1 = 32-bit apps supported
				;   CL	  =   CPU type (02 = 286, 03 = 386, 04 = 486, etc.)
				;   DH	  =   DPMI major version # (in decimal)
				;   DL	  =   ...  minor ...
				;   SI	  =   # paras in host private data area
				;   ES:DI ==> VM -> PM entry point
	and	ax,ax		; Izit present?
	stc			; Assume not
	jnz	short CheckDPMIExit ; Jump if not

;;;;;;; mov	DPMIDRV_VEC.VSEG,es ; Save for later use
;;;;;;; mov	DPMIDRV_VEC.VOFF,di ; ...
;;;;;;; mov	DPMI_HPDA,si	; ...
;;;;;;; xchg	dl,dh		; Swap for PRINTF
;;;;;;; mov	DPMI_VER,dx	; ...
;;;;;;; mov	DPMI_CPU,cl	; ...
;;;;;;; mov	DPMI_FLAG,bx	; ...

	clc			; Mark as successful
CheckDPMIExit:
	pop	es		; Restore
	assume	es:nothing	; Tell the assembler about it
	popa			; ...

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CheckDPMI endp			; End CHECK_DPMI procedure

NCODE	ends			; End NCODE segment


STACK	segment 		; Start STACK segment

; Use this area for uninitialized temporary storage

	public	ModuleDPFE
ModuleDPFE db	1024 dup (?)	; Module d:\path\filename.ext

	dw	(4*1024) dup (?)

STACK	ends			; End STACK segment

	MEND	WNTSTUB 	; End WNTSTUB module
