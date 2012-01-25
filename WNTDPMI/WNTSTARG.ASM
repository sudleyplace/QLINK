;' $Header$
	title	WNTSTARG -- Argument Processing for WNTDPMI Stub Program
	page	58,122
	name	WNTSTARG

COMMENT|		Module Specifications

Copyright:  (C) Copyright 2003 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment DATA,  dword-aligned, public, class 'prog'
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Tail    segment NDATA, dword-aligned, public, class 'ndata'
	       Tail    segment NCODE, byte-aligned,  public, class 'ndata'
	       Stack   segment STACK, dword-aligned, stack,  class 'ndata'

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

	include WNTDPMI.INC
	include WNTSTSEG.INC
.list

; Define segments and groups

PGROUP	group	LDATA,NDATA,NCODE,NTEXT,NTXTTAB,NTXTLEN,NTXTACT

PSPGRP	group	PSP_SEG

PSP_SEG segment use16 at 0	; Start PSP_SEG segment
	assume	cs:PSPGRP,ds:PSPGRP

	extrn	PSP_PARM_STRING:byte
	extrn	PSP_PARM_COUNT:byte

PSP_SEG ends			; End PSP_SEG segment

; --------------------------------------------------------------

LDATA	segment 		; Start LDATA segment
	assume	ds:PGROUP

	extrn	PSPSEG:word
	extrn	VSAPI_VEC:dword
	extrn	ERRCODE:byte
	extrn	SIGNATURE:byte

LDATA	ends			; End LDATA segment


NDATA	segment use16 dword public 'ndata' ; Start NDATA segment
	assume	ds:PGROUP

	public	LDATASEG
LDATASEG dw	seg PGROUP	; PGROUP data segment

	public	LCL_FLAG
LCL_FLAG dw	0		; Local flags (see @LCL_xxx)

	public	MSG_ERRCMDSW,MSG_ERRCMDLIN
MSG_ERRCMDSW  db BEL,'*** Unknown switch on command line.',CR,LF,EOS
MSG_ERRCMDLIN db BEL,'*** Unknown keyword on command line.',CR,LF,EOS

	public	MSG_NOUNLOAD1,MSG_NOUNLOAD2
	public	MSG_ENABLED,MSG_DISABLED,MSG_UNLOADED
	public	MSG_NOENABLE,MSG_NODISABLE
MSG_NOUNLOAD1 db BEL,'*** Unable to unload:  not previously installed.',CR,LF,EOS
MSG_NOUNLOAD2 db BEL,'*** Unable to unload:  disabling instead.',CR,LF,EOS
MSG_ENABLED   db '   Resident program enabled.',CR,LF,EOS
MSG_DISABLED  db '   Resident program disabled.',CR,LF,EOS
MSG_UNLOADED  db '   Resident program unloaded.',CR,LF,EOS
MSG_NOENABLE  db BEL,'*** Unable to enable:  not previously installed.',CR,LF,EOS
MSG_NODISABLE db BEL,'*** Unable to disable:  not previously installed.',CR,LF,EOS

NDATA	ends			; End NDATA segment


LINARG_MAC macro TXT,ACT
	local	LCL_TXT,LCL_LEN

NTEXT	segment use16 byte public 'ndata' ; Start NTEXT segment
	assume	ds:PGROUP

LCL_TXT db	TXT
LCL_LEN equ	$-LCL_TXT

NTEXT	ends			; End NTEXT segment


NTXTLEN segment use16 word public 'ndata' ; Start NTXTLEN segment
	assume	ds:PGROUP

	dw	LCL_LEN

NTXTLEN ends			; End NTXTLEN segment


NTXTTAB segment use16 word public 'ndata' ; Start NTXTTAB segment
	assume	ds:PGROUP

	dw	PGROUP:LCL_TXT

NTXTTAB ends			; End NTXTTAB segment


NTXTACT segment use16 word public 'ndata' ; Start NTXTACT segment
	assume	ds:PGROUP

	dw	PGROUP:ACT

NTXTACT ends			; End NTXTACT segment

	endm			; LINARG_MAC


NTXTTAB segment use16 word public 'ndata' ; Start NTXTTAB segment
	assume	ds:PGROUP

	public	LINARG_TAB
LINARG_TAB label word

NTXTTAB ends			; End NTXTTAB segment


NTXTLEN segment use16 word public 'ndata' ; Start NTXTLEN segment
	assume	ds:PGROUP

	public	LINARG_LEN
LINARG_LEN label word

NTXTLEN ends			; End NTXTLEN segment


NTXTACT segment use16 word public 'ndata' ; Start NTXTACT segment
	assume	ds:PGROUP

	public	LINARG_ACT
LINARG_ACT label word

NTXTACT ends			; End NTXTACT segment


NDATA	segment 		; Start NDATA segment
	assume	ds:PGROUP

; All keywords in this table *MUST* be in uppercase

	LINARG_MAC 'UNLOAD',            FCN_UNLOAD
	LINARG_MAC 'UNINSTALL',         FCN_UNLOAD
	LINARG_MAC 'ENABLE',            FCN_ENABLE
	LINARG_MAC 'DISABLE',           FCN_DISABLE
	LINARG_MAC 'NOWIN',             FCN_NOWIN

NDATA	ends			; End NDATA segment


NTXTTAB segment use16 word public 'ndata' ; Start NTXTTAB segment
	assume	ds:PGROUP

	public	NLINARGS
NLINARGS equ	($-LINARG_TAB)/(type LINARG_TAB) ; Its length

NTXTTAB ends			; End NTXTTAB segment


NCODE	segment 		; Start NCODE segment
	assume	cs:PGROUP

	NPPROC	CheckArgs -- Check For Arguments
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for arguments

On exit:

CF	=	0 if OK
	=	1 if not

|

	REGSAVE <ax,si,ds>	; Save registers

	mov	ds,PSPSEG	; DS:0 ==> PSP Segment
	assume	ds:PSPGRP	; Tell the assembler about it

	lea	si,PSP_PARM_STRING ; DS:SI ==> command line
	movzx	bx,PSP_PARM_COUNT ; Get the command line length
	mov	PSP_PARM_STRING[bx],0 ; Terminate the line

	call	StrUpper	; Convert the string at DS:SI to upper case
CheckArgsSrch:			; Search for arguments
	call	SkipWhite	; Skip over white space

	cmp	al,0		; Izit EOL?
	je	short CheckArgsDone ; Jump if so

	cmp	al,'/'          ; Izit switch char?
	je	short CheckArgsSwitch ; Jump if so

	lea	dx,MSG_ERRCMDLIN ; PGROUP:DX ==> error message

	jmp	short CheckArgsErrCom ; Join common error code


CheckArgsSwitch:
	inc	si		; Skip over switch separator
	call	SkipWhite	; Skip over white space

; Check for allowed switches

; If we're already installed and running under Windows,
; pass on the ENABLE/DISABLE request to the VxD

	cmp	al,0		; Check for terminator
	je	short CheckArgsErrCmdSW ; Jump if so (that's an error)

; Search for the argument text

	xor	bx,bx		; Zero index register
	mov	cx,NLINARGS	; # arguments to check
CheckArgsNextSW:
	mov	di,LINARG_TAB[bx] ; Get location of text

	REGSAVE <cx,si> 	; Save for a moment
	mov	cx,LINARG_LEN[bx] ; Get length
   repe cmps	ds:[si].LO,es:[di].LO ; Compare 'em
	REGREST <si,cx> 	; Restore
	jne	short CheckArgsLoopSW ; Not this one

; Mark as found only if the next character is a valid separator

	mov	di,LINARG_LEN[bx] ; Get length of matching command
	add	di,si		; Add into starting offset
	mov	al,ds:[di]	; Get the next character

	cmp	al,'='          ; Check for valid separator
	je	short CheckArgsFoundSW ; Jump if valid

	cmp	al,'/'          ; Check for valid separator
	je	short CheckArgsFoundSW ; Jump if valid

	cmp	al,' '          ; Check for blank or below
	jbe	short CheckArgsFoundSW ; Jump if so
CheckArgsLoopSW:
	add	bx,type LINARG_TAB ; Skip to next entry

	loop	CheckArgsNextSW ; Jump if more entries to check

; Keyword not found

CheckArgsErrCmdSW:
	lea	dx,MSG_ERRCMDSW ; PGROUP:DX ==> error message

	jmp	short CheckArgsErrCom ; Join common error code


CheckArgsFoundSW:
	add	si,LINARG_LEN[bx] ; Skip over the keyword

	call	LINARG_ACT[bx]	; Take appropriate action
	jc	short CheckArgsErr ; Join common error code

	jmp	CheckArgsSrch ; Join common tail code


CheckArgsErrCom:
	mov	ds,LDATASEG	; Address the data in PGROUP
	assume	ds:PGROUP	; Tell the assembler about it

	DOSCALL @STROUT 	; Tell 'em the bad news
CheckArgsErr:
	stc			; Mark as in error

	jmp	short CheckArgsExit ; Join common exit code


CheckArgsDone:
	clc			; Mark as successful
CheckArgsExit:
	REGREST <ds,si,ax>	; Restore
	assume	ds:PGROUP	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CheckArgs endp			; End CheckArgs procedure
	NPPROC	FCN_DISABLE -- DISABLE Function
	assume	ds:PSPGRP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/DISABLE function

On entry:

DS:SI	==>	command line following keyword

On exit:

DS:SI	==>	next character to scan
CF	=	0 if successful
	=	1 if not

|

	REGSAVE <ax,dx> 	; Save registers

; See if we're already installed

	test	LCL_FLAG,@LCL_INST ; Are we already installed?
	jz	short FCN_DISABLE_ERR ; Jump if not

	mov	ax,@VSAPI_DISABLE ; Tell the TSR to disable itself
	call	VSAPI_VEC	; Request VSAPI service

	push	ds		; Save for a moment

	mov	ds,LDATASEG	; Address the data in PGROUP
	assume	ds:PGROUP	; Tell the assembler about it

	DOSCALL @STROUT,MSG_DISABLED ; Tell 'em the good news

	pop	ds		; Restore
	assume	ds:PSPGRP	; Tell the assembler about it

	or	LCL_FLAG,@LCL_NRES ; Mark as not going resident
	mov	ERRCODE,0	; Normal error code

	clc			; Mark as successful

	jmp	short FCN_DISABLE_EXIT ; Join common exit code


FCN_DISABLE_ERR:
	push	ds		; Save for a moment

	mov	ds,LDATASEG	; Address the data in PGROUP
	assume	ds:PGROUP	; Tell the assembler about it

	DOSCALL @STROUT,MSG_NODISABLE ; Tell 'em the bad news

	pop	ds		; Restore
	assume	ds:PSPGRP	; Tell the assembler about it

;;;;;;; jmp	short FCN_DISABLE_ERRCOM ; Join common error code


FCN_DISABLE_ERRCOM:
	stc			; Mark as in error
FCN_DISABLE_EXIT:
	REGREST <dx,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DISABLE endp		; End FCN_DISABLE procedure
	NPPROC	FCN_ENABLE -- ENABLE Function
	assume	ds:PSPGRP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/ENABLE function

On entry:

DS:SI	==>	command line following keyword

On exit:

DS:SI	==>	next character to scan
CF	=	0 if successful
	=	1 if not

|

	REGSAVE <ax,dx> 	; Save registers

; See if we're already installed

	test	LCL_FLAG,@LCL_INST ; Are we already installed?
	jz	short FCN_ENABLE_ERR ; Jump if not

	mov	ax,@VSAPI_ENABLE ; Tell the TSR to enable itself
	call	VSAPI_VEC	; Request VSAPI service

	push	ds		; Save for a moment

	mov	ds,LDATASEG	; Address the data in PGROUP
	assume	ds:PGROUP	; Tell the assembler about it

	DOSCALL @STROUT,MSG_ENABLED ; Tell 'em the good news

	pop	ds		; Restore
	assume	ds:PSPGRP	; Tell the assembler about it

	or	LCL_FLAG,@LCL_NRES ; Mark as not going resident
	mov	ERRCODE,0	; Normal error code

	clc			; Mark as successful

	jmp	short FCN_ENABLE_EXIT ; Join common exit code


FCN_ENABLE_ERR:
	push	ds		; Save for a moment

	mov	ds,LDATASEG	; Address the data in PGROUP
	assume	ds:PGROUP	; Tell the assembler about it

	DOSCALL @STROUT,MSG_NOENABLE ; Tell 'em the bad news

	pop	ds		; Restore
	assume	ds:PSPGRP	; Tell the assembler about it

;;;;;;; jmp	short FCN_ENABLE_ERRCOM ; Join common error code


FCN_ENABLE_ERRCOM:
	stc			; Mark as in error
FCN_ENABLE_EXIT:
	REGREST <dx,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_ENABLE endp 		; End FCN_ENABLE procedure
	NPPROC	FCN_NOWIN -- NOWIN Function
	assume	ds:PSPGRP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/NOWIN function

On entry:

DS:SI	==>	command line following keyword

On exit:

DS:SI	==>	next character to scan
CF	=	0 if successful
	=	1 if not

|

	or	LCL_FLAG,@LCL_NOWIN ; Mark as not requiring Win NT/2000/XP
				; Note CF=0
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOWIN endp			; End FCN_NOWIN procedure
	NPPROC	FCN_UNLOAD -- UNLOAD Function
	assume	ds:PSPGRP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/UNLOAD function

On entry:

DS:SI	==>	command line following keyword

On exit:

DS:SI	==>	next character to scan
CF	=	0 if successful
	=	1 if not

|

	REGSAVE <ax,dx> 	; Save registers

; See if we're already installed

	test	LCL_FLAG,@LCL_INST ; Are we already installed?
	jz	short FCN_UNLOAD_ERR1 ; Jump if not

	mov	ax,@VSAPI_DISABLE ; Tell the TSR to disable itself
	call	VSAPI_VEC	; Request VSAPI service

;;;;;;; cmp	ax,TRUE 	; Did it succeed?
;;;;;;; jne	short ???	; Jump if not

	mov	ax,@VSAPI_UNLOAD ; Tell the TSR to unload itself
	call	VSAPI_VEC	; Request VSAPI service

	cmp	ax,TRUE 	; Did it succeed?
	jne	short FCN_UNLOAD_ERR2 ; Jump if not

	push	ds		; Save for a moment

	mov	ds,LDATASEG	; Address the data in PGROUP
	assume	ds:PGROUP	; Tell the assembler about it

	DOSCALL @STROUT,MSG_UNLOADED ; Tell 'em the bad news

	pop	ds		; Restore
	assume	ds:PSPGRP	; Tell the assembler about it

	or	LCL_FLAG,@LCL_NRES ; Mark as not going resident
	mov	ERRCODE,0	; Normal error code

	clc			; Mark as successful

	jmp	short FCN_UNLOAD_EXIT ; Join common exit code


FCN_UNLOAD_ERR1:
	push	ds		; Save for a moment

	mov	ds,LDATASEG	; Address the data in PGROUP
	assume	ds:PGROUP	; Tell the assembler about it

	DOSCALL @STROUT,MSG_NOUNLOAD1 ; Tell 'em the bad news

	pop	ds		; Restore
	assume	ds:PSPGRP	; Tell the assembler about it

	jmp	short FCN_UNLOAD_ERRCOM ; Join common error code


FCN_UNLOAD_ERR2:
	push	ds		; Save for a moment

	mov	ds,LDATASEG	; Address the data in PGROUP
	assume	ds:PGROUP	; Tell the assembler about it

	DOSCALL @STROUT,MSG_NOUNLOAD2 ; Tell 'em the bad news

	pop	ds		; Restore
	assume	ds:PSPGRP	; Tell the assembler about it

;;;;;;; jmp	short FCN_UNLOAD_ERRCOM ; Join common error code


FCN_UNLOAD_ERRCOM:
	stc			; Mark as in error
FCN_UNLOAD_EXIT:
	REGREST <dx,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_UNLOAD endp 		; End FCN_UNLOAD procedure
	NPPROC	StrUpper -- Copnvert String to Uppercase
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert ASCIIZ string at DS:SI to uppercase

|

	REGSAVE <ax,si> 	; Save registers
StrUpperNext:
	lods	ds:[si].LO	; Get next character

	and	al,al		; Check for end-of-the-line
	jz	short StrUpperExit ; Good guess

	cmp	al,'a'          ; Check against lower limit
	jb	short StrUpperNext ; Jump if too small

	cmp	al,'z'          ; Check against upper limit
	ja	short StrUpperNext ; Jump if too large

	add	al,'A'-'a'      ; Convert to uppercase

	mov	ds:[si-1],al	; Save back in text

	jmp	short StrUpperNext ; Go around again


StrUpperExit:
	REGREST <si,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrUpper endp			; End StrUpper procedure
	NPPROC	SkipWhite -- Skip Over White Space
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over white space

On entry:

DS:SI	==>	command line

On exit:

AL	=	last non-white space char
DS:SI	==>	(updated)

|

@@:
	lods	ds:[si].LO	; Get next char

	cmp	al,' '          ; Izit white space?
	je	short @B	; Jump if so

	cmp	al,TAB		; Izit white space?
	je	short @B	; Jump if so

	dec	si		; Back off to last char

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SkipWhite endp			; End SkipWhite procedure
	NPPROC	CheckInstalled -- Check On Already Installed
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on already installed

On exit:

LCL_FLAG set

|

	REGSAVE <ax,si,di,es>	; Save registers

	lea	si,SIGNATURE	; DS:SI ==> SIGNATURE

	mov	ax,168Ah	; Get VSAPI function code
	int	2Fh		; Request multiplexor service
	assume	es:nothing	; Tell the assembler about it
				; Return with AL = 0
				; ...	      ES:DI ==> VSAPI entry point
	cmp	al,0		; Ar we installed?
	jne	short @F	; Jump if not

	mov	VSAPI_VEC.VSEG,es ; Save for later use
	mov	VSAPI_VEC.VOFF,di ; ...

	or	LCL_FLAG,@LCL_INST ; Mark as already installed
@@:
	REGREST <es,di,si,ax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CheckInstalled endp		; End CheckInstalled procedure

NCODE	ends			; End NCODE segment

	MEND			; End WNTSTARG module
