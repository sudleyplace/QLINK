;' $Header:   P:/PVCS/MISC/QLINK/QLNK_MAP.ASV   1.1   17 Jul 1997 12:36:48   BOB  $
	title	QLNK_MAP -- QLINK Map File Routines
	page	58,122
	name	QLNK_MAP

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1994-2002 Qualitas, Inc.  All rights reserved.

Program derived from:  None.

Original code by:  Bob Smith, August, 1994.

Modifications by:  None.

|
.386
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include ASCII.INC
	include DOSCALL.INC
	include ALLMEM.INC
	include EXE.INC
	include DIR.INC
	include BITFLAGS.INC
	include WINSTR.INC

	include QLNK_COM.INC
	include QLNK_IWF.INC
	include QLNK_SEG.INC
	include QLNK_SYM.INC
.list

DATA	segment 		; Start DATA segment
	assume	ds:DGROUP

	extrn	ARG_FLAG:dword
	include QLNK_ARG.INC

	extrn	DBG_FLAG:dword
	include QLNK_DBG.INC

	extrn	LCL_FLAG:dword
	include QLNK_LCL.INC

	extrn	PFLDS:dword
	extrn	LaDATA:dword
	extrn	LMB_SYMBOL:tbyte
	extrn	LMB_TXTSTR:tbyte
	extrn	LMB_PERCLS:tbyte
	extrn	LMB_PEROBJ:tbyte
	extrn	LMB_PERSEG:tbyte
	extrn	LMB_PERGRP:tbyte
	extrn	LMB_PUBDEF:tbyte
	extrn	LMB_SEGOBJ:tbyte
	extrn	LMB_LINNUM:tbyte
	extrn	LMB_EXPDEF:tbyte
	extrn	LMB_IMPDEF:tbyte
	extrn	LMB_PERMOD:tbyte
	extrn	LMB_PERLSEG:tbyte
	extrn	SEGLNK_1ST:dword
	extrn	MINSTACK:dword
	extrn	EXE_HDR:tbyte
;;;;;;; extrn	NONULLS_OFF:dword
	extrn	IWFCNT:dword
	extrn	ALINTYP:dword
	extrn	EXE_WIN:byte
	extrn	WIN_NAME:byte
	extrn	MODEND_PEROBJ:dword
	extrn	NE_HDR:tbyte

	public	MAP_SYM_STR
MAP_SYM_STR dd	?		; Local copy of SYM_STR for segment

	public	SEGOBJ_CNT
SEGOBJ_CNT dd	?		; # SEGOBJs written per segment

	public	LAST_PEROBJ,LAST_PERSEG
LAST_PEROBJ dd	?		; Last PEROBJ_STR for LINNUM display
LAST_PERSEG dd	?		; ...  PERSEG_STR ...

	public	PMAP_PUBLINE_ABS,PMAP_PUBLINE_LEN
PMAP_PUBLINE_ABS dd ?		; Offset in DGROUP of MAP_PUBLINEn_ABSxx
PMAP_PUBLINE_LEN dd ?		; Length of MAP_PUBLINE depending upon LCL_SEG32

	public	MAPHNDL
MAPHNDL dw	-1,?		; Map file handle (-1=invalid) (can be used as dword)

	public	CTYP_TAB
CTYP_TAB label dword
	dd	offset DGROUP:CTYP_PRIVATE ; 0
	dd	offset DGROUP:CTYP_UNKNOWN ; 1
	dd	offset DGROUP:CTYP_PUBLIC  ; 2
	dd	offset DGROUP:CTYP_UNKNOWN ; 3
	dd	offset DGROUP:CTYP_UNKNOWN ; 4
	dd	offset DGROUP:CTYP_STACK   ; 5
	dd	offset DGROUP:CTYP_COMMON  ; 6
	dd	offset DGROUP:CTYP_UNKNOWN ; 7

	CCMAC	' Private',     CTYP_PRIVATE
	CCMAC	' Public',      CTYP_PUBLIC
	CCMAC	' Stack',       CTYP_STACK
	CCMAC	' Common',      CTYP_COMMON
	CCMAC	' **Unknown**', CTYP_UNKNOWN

	public	MAP_SEGHDR1
MAP_SEGHDR1 db	CR,LF,' Start  Stop   Length Name                   Class'
	db	CR,LF
MAP_SEGHDR1_LEN equ $-MAP_SEGHDR1 ; Length of ...

	public	MAP_SEGHDR2
MAP_SEGHDR2 db	CR,LF,' Start     Length     Name                   Class'
	db	CR,LF
MAP_SEGHDR2_LEN equ $-MAP_SEGHDR2 ; Length of ...

	public	MAP_SEGLINE1
MAP_SEGLINE1	     db ' '
MAP_SEGLINE1_START   db '_____H '
MAP_SEGLINE1_STOP    db '_____H '
MAP_SEGLINE1_LENGTH  db '_____H '
MAP_SEGLINE1_SEGMENT db 23 dup (' ')
MAP_SEGLINE1_CLASS   db 34 dup (' '),CR,LF
MAP_SEGLINE1_LEN equ $-MAP_SEGLINE1 ; Length of ...

	public	MAP_SEGLINE2
MAP_SEGLINE2	     db ' '
MAP_SEGLINE2_LSEG    db '____:'
MAP_SEGLINE2_START   db '____ '
MAP_SEGLINE2_LENGTH  db '_____H '
		     db '    '
MAP_SEGLINE2_SEGMENT db 23 dup (' ')
MAP_SEGLINE2_CLASS   db 34 dup (' '),CR,LF
MAP_SEGLINE2_LEN equ $-MAP_SEGLINE2 ; Length of ...

; The following two data must be together

MAP_USE16 db	' 16-bit'
MAP_USE32 db	' 32-bit'
MAP_USE32_LEN equ $-MAP_USE32	; Length of ...

MAP_ALIGNED db	'-aligned'      ; Text to append to alignment type
MAP_ALIGNED_LEN equ $-MAP_ALIGNED ; Length of ...

@MAP_SEGOBJ_NRM equ 15		; # leading blanks for normal display
@MAP_SEGOBJ_NE	equ 11		; ...		       EXETYPE WINDOWS

MAP_SEGOBJ     db @MAP_SEGOBJ_NRM dup (' '),'at offset '
MAP_SEGOBJ_OFF db '_____H '
MAP_SEGOBJ_SIZ db '_____H bytes from '
MAP_SEGOBJ_LEN equ $-MAP_SEGOBJ ; Length of ...

	public	MSG_MAPCREA,MSG_MAPWRIT
MSG_MAPCREA db	'袴> FAIL:  Unable to create .MAP file.',CR,LF,EOS
MSG_MAPWRIT db	'袴> FAIL:  Unable to write .MAP file.',CR,LF,EOS

	public	MAP_GRPHDR
MAP_GRPHDR db	CR,LF,' Origin   Group',CR,LF
MAP_GRPHDR_LEN equ $-MAP_GRPHDR ; Length of ...

	public	MAP_GRPLINE
MAP_GRPLINE	db ' '
MAP_GRPLINE_SEG db '____:'
MAP_GRPLINE_OFF db '_   '
MAP_GRPLINE_NAM db 69 dup (' ')
	db	CR,LF
MAP_GRPLINE_LEN equ $-MAP_GRPLINE ; Length of ...

	public	MAP_EXPHDR
MAP_EXPHDR db	CR,LF,' Address   Export                  Alias'
	db	CR,LF
	db	CR,LF
MAP_EXPHDR_LEN equ $-MAP_EXPHDR ; Length of ...

	public	MAP_EXPLINE
MAP_EXPLINE	   db ' '
MAP_EXPLINE_LSEG   db '____:'
MAP_EXPLINE_START  db '____ '
MAP_EXPLINE_EXPORT db 24 dup (' ')
MAP_EXPLINE_ALIAS  db 44 dup (' '),CR,LF
MAP_EXPLINE_LEN equ $-MAP_EXPLINE ; Length of ...

	public	MAP_NAMHDR
MAP_NAMHDR db	CR,LF,'  Address         Publics by Name',CR,LF,CR,LF
MAP_NAMHDR_LEN equ $-MAP_NAMHDR ; Length of ...

	public	MAP_VALHDR
MAP_VALHDR db	CR,LF,'  Address         Publics by Value',CR,LF,CR,LF
MAP_VALHDR_LEN equ $-MAP_VALHDR ; Length of ...

	public	MAP_PUBLINE1
MAP_PUBLINE1	   db ' '
MAP_PUBLINE1_SEG   db '____:'
MAP_PUBLINE1_OFF   db '________'
MAP_PUBLINE1_ABS32 db '       '
MAP_PUBLINE1_ABS16 equ MAP_PUBLINE1_ABS32 - 4 ; Offset if all 16-bit segments
MAP_PUBLINE1_LEN equ $-MAP_PUBLINE1 ; Length of ...

	public	MAP_PUBLINE2
MAP_PUBLINE2	   db ' '
MAP_PUBLINE2_SEG   db '____:'
MAP_PUBLINE2_OFF   db '________'
MAP_PUBLINE2_ABS32 db '       '
MAP_PUBLINE2_ABS16 equ MAP_PUBLINE2_ABS32 - 4 ; Offset if all 16-bit segments
MAP_PUBLINE2_LEN equ $-MAP_PUBLINE2 ; Length of ...

MAP_IMP db	'  Imp  '
MAP_REL db	'       '
MAP_ABS db	'  Abs  '
MAP_ABS_LEN equ $-MAP_ABS	; Length of ...

@MAP_NAMLINE equ 20		; Limit name length ot this if EXE_WIN and imported

	public	MAP_NAMLINE1,MAP_NAMLINE2,MAP_NAMLINE3,MAP_NAMLINE4
MAP_NAMLINE1 db '%F*.*s',0
MAP_NAMLINE2 db ' (%F.*s.%F.*s)',0
MAP_NAMLINE3 db '%hu',0
MAP_NAMLINE4 db 6 dup (?)	; Buffer with room for '65535',0

	public	MAP_NUMHDR
MAP_NUMHDR db	CR,LF,'Line numbers for '
MAP_NUMHDR_LEN equ $-MAP_NUMHDR ; Length of ...
MAP_NUMHDR1 db	' segment '
MAP_NUMHDR1_LEN equ $-MAP_NUMHDR1 ; Length of ...

	public	MAP_NUMLINE
MAP_NUMLINE  db '     '
MAP_NUMLINE1 db '_ '
MAP_NUMLINE2 db '    '
	     db ' '
MAP_NUMLINE3 db '    '
MAP_NUMLINE_FLD equ $-MAP_NUMLINE ; Length of ...
	    db	'                '
	    db	'                '
	    db	'                '
MAP_NUMLINE_CLR equ $-MAP_NUMLINE ; Length of ... to clear
	db	CR,LF
MAP_NUMLINE_LEN equ $-MAP_NUMLINE ; Length of ...

	public	MAP_ENTRY
MAP_ENTRY db	CR,LF,'Program entry point at '
MAP_ENTRY_CS db '____:'
MAP_ENTRY_IP db '____',CR,LF
MAP_ENTRY_LEN equ $-MAP_ENTRY	; Length of ...

	public	MAP_STACK
MAP_STACK db	'Stack Allocation = %,u bytes',CR,LF,0

	public	MAP_WNAME
MAP_WNAME db	CR,LF,' %F.*s',CR,LF,0

DATA	ends			; End DATA segment


CODE	segment 		; Start CODE segment
	assume	cs:PGROUP,ds:PGROUP

	extrn	U32_DISP_MSG:near
	extrn	U32_DISP_MSGL:near
	extrn	U32_NEWLINE:near
	extrn	DISP_CNTCHR:near
	extrn	DISP_THEADR:near
	extrn	DG2HEX:near
	extrn	DW2HEX:near
	extrn	DD2HEX:near
	extrn	D52HEX:near
	extrn	DD2DEC:near
	extrn	RPRINTF32:near
	extrn	SPRINTF32:near
	extrn	WRITE_MAPBUF:near
	extrn	WRITE_OUT:near

	NPPROC	WRITE_MAP -- Write Out The .MAP File
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Write out the .MAP file.

On exit:

CF	=	0 if successful
	=	1 if not

|

	pushad			; Save registers
	REGSAVE <ds>		; ...

	cmp	PFLDS[@FLD_MAP*(type PFLDS)],0 ; Izit filled in?
	je	near ptr WRITE_MAP_EXIT ; Jump if not (note CF=0)

; Create the .MAP file

	movzx	eax,PFLDS[@FLD_MAP*(type PFLDS)].VSEG ; Get the segment
	shl	eax,4-0 	; Convert from paras to bytes
	movzx	edx,PFLDS[@FLD_MAP*(type PFLDS)].VOFF ; Get the offset
	add	edx,eax 	; Add to get LA

	mov	cx,DIR_ATTR_NORM ; Normal directory attrs
	DOSCALL @CREAF2 	; Create the file
	jc	near ptr WRITE_MAP_ERRCREA ; Jump if something went wrong

	mov	MAPHNDL,ax	; Save for later use
	or	LCL_FLAG,@LCL_MAPOUT ; Mark as writing to map file

	test	DBG_FLAG,@DBG_MAP16 ; Display as USE16 anyway?
	jz	short @F	; Jump if so

	and	LCL_FLAG,not (@LCL_SEG32 or @LCL_CON32) ; Clear 'em
@@:

; Setup local variables which depend upon whether or not there are
; any 32-bit segments present.

	cmp	EXE_WIN,1	; Izit EXETYPE WINDOWS?
	jne	short WRITE_MAP_DOS ; Jump if not

	mov	eax,MAP_PUBLINE2_LEN ; Get length if 32-bit segs present
	lea	ebx,MAP_PUBLINE2_ABS32 ; Get offset in DGROUP if USE32

	test	LCL_FLAG,@LCL_SEG32 or @LCL_CON32 ; Any 32-bit segments or constants?
	jnz	short @F	; Jump if so

	sub	eax,MAP_PUBLINE2_ABS32 - MAP_PUBLINE2_ABS16 ; Reduce the length
	lea	ebx,MAP_PUBLINE2_ABS16 ; Get offset in DGROUP if USE16
@@:
	jmp	short WRITE_MAP_DOS1 ; Join common code


WRITE_MAP_DOS:
	mov	eax,MAP_PUBLINE1_LEN ; Get length if 32-bit segs present
	lea	ebx,MAP_PUBLINE1_ABS32 ; Get offset in DGROUP if USE32

	test	LCL_FLAG,@LCL_SEG32 or @LCL_CON32 ; Any 32-bit segments or constants?
	jnz	short @F	; Jump if so

	sub	eax,MAP_PUBLINE1_ABS32 - MAP_PUBLINE1_ABS16 ; Reduce the length
	lea	ebx,MAP_PUBLINE1_ABS16 ; Get offset in DGROUP if USE16
@@:
WRITE_MAP_DOS1:
	mov	PMAP_PUBLINE_LEN,eax ; Save for later use
	mov	PMAP_PUBLINE_ABS,ebx ; ...
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;			STACK ALLOCATION
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

; Write out the stack allocation if non-default

	mov	eax,MINSTACK	; Get minimum stack size

	and	eax,eax 	; Izit default?
	jz	short @F	; Jump if so

	push	eax		; Pass the stack size
	push	fs		; ...  ptr to format string
	push	offset DGROUP:MAP_STACK ; ...
	push	cs		; ...  ptr to output routine
	push	offset PGROUP:RPRINTF_OUT ; ...
	call	RPRINTF32	; RPrintf it, return with EAX = # chars printed
	add	esp,4*5 	; Strip from stack
@@:
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;			WINDOWS PROGRAM NAME
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

; If we're writing a Windows executable, also write out the program name

	cmp	EXE_WIN,1	; Izit EXETYPE WINDOWS?
	jne	short @F	; Jump if not

	movzx	eax,WIN_NAME.CC_COUNT ; Get length of name
	push	fs		; Pass ptr to name
	push	offset DGROUP:WIN_NAME.CC_CHAR ; ...
	push	eax		; ...  length of ...
	push	fs		; ...  ptr to format string
	push	offset DGROUP:MAP_WNAME ; ...
	push	cs		; ...  ptr to output routine
	push	offset PGROUP:RPRINTF_OUT ; ...
	call	RPRINTF32	; RPrintf it, return with EAX = # chars printed
	add	esp,4*7 	; Strip from stack
@@:
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;			SEGMENTS
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

; Write out the segment header

	cmp	EXE_WIN,1	; Izit EXETYPE WINDOWS?
	jne	short WRITE_MAP0 ; Jump if not

	push	MAP_SEGHDR2_LEN ; Pass the length in bytes
	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MAP_SEGHDR2) ; Pass offset of message

	jmp	short @F	; Join common code


WRITE_MAP0:
	push	MAP_SEGHDR1_LEN ; Pass the length in bytes
	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MAP_SEGHDR1) ; Pass offset of message
@@:
	call	U32_DISP_MSGL	; Display the message

; Trundle through all the segments in sequence using the SEGLNK chain
; and write out a line for each

	mov	esi,SEGLNK_1ST	; Get starting LA (PERSEG_STR)
WRITE_MAP_NEXTSEG:
	cmp	esi,-1		; Are we at the end?
	je	near ptr WRITE_MAP_ENDSEG ; Jump if so

; Skip this if it's Absolute alignment type

	UNCURB	esi,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[esi].PERSEG_SEGSYM ; Get LA of SYM_STR

	UNCURB	eax,SYMBOL	; Ensure within current bounds
	test	AGROUP:[eax].SYM_FLAG,@SYMFL_A ; Izit Absolute alignment?
	jz	near ptr WRITE_MAP_LOOPSEG ; Jump if so

; Split off Windows case

	cmp	EXE_WIN,1	; Izit EXETYPE WINDOWS?
	jne	near ptr WRITE_MAP_DOSSEG1 ; Jump if not

; Format logical segment #

;;;;;;; UNCURB	esi,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[esi].PERSEG_CLS ; Get LA of class (PERCLS_STR)
	UNCURB	eax,PERCLS	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERCLS_PERLSEG ; Get LA of logical segment (PERLSEG_STR)
	UNCURB	eax,PERLSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERLSEG_LSEG ; Get logical segment #
	lea	edi,MAP_SEGLINE2_LSEG ; Get offset in DGROUP of format area
	add	edi,LaDATA	; Plus LA of DGROUP
	call	DW2HEX		; Convert AX to Hex at ES:EDI

; Format segment start offset

;;;;;;; UNCURB	esi,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[esi].PERSEG_ADRB.BOUND_BEG ; Copy start address
;;;;;;; UNCURB	esi,PERSEG	; Ensure within current bounds
	mov	ebx,AGROUP:[esi].PERSEG_CLS ; Get LA of class (PERCLS_STR)
	UNCURB	ebx,PERCLS	; Ensure within current bounds
	mov	ebx,AGROUP:[ebx].PERCLS_PERSEG1ST ; Get LA of 1st segment in class (PERSEG_STR)
	UNCURB	ebx,PERSEG	; Ensure within current bounds
	sub	eax,AGROUP:[ebx].PERSEG_ADRB.BOUND_BEG ; Less base address
	lea	edi,MAP_SEGLINE2_START ; Get offset in DGROUP of format area
	add	edi,LaDATA	; Plus LA of DGROUP
	call	DW2HEX		; Convert AX to Hex at ES:EDI

; Format segment length

;;;;;;; UNCURB	esi,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[esi].PERSEG_NEWLEN ; Get length of the segment
	lea	edi,MAP_SEGLINE2_LENGTH ; Get offset in DGROUP of format area
	add	edi,LaDATA	; Plus LA of DGROUP
	call	D52HEX		; Convert EAX to Hex at ES:EDI

; Clear the segment name format area

	lea	edi,MAP_SEGLINE2_SEGMENT ; Get offset in DGROUP of format area
	add	edi,LaDATA	; Plus LA of DGROUP

	push	edi		; Save for a moment

	mov	ecx,size MAP_SEGLINE2_SEGMENT ; # bytes to clear
	mov	al,' '          ; Clear to this
    rep stos	AGROUP:[edi].LO ; Clear it

	pop	edi		; Restore

; Copy segment name to format area

	push	esi		; Save for a moment

	UNCURB	esi,PERSEG	; Ensure within current bounds
	mov	esi,AGROUP:[esi].PERSEG_SEGSYM ; Get LA of SYM_STR
	mov	MAP_SYM_STR,esi ; Save LA of SYM_STR
	UNCURB	esi,SYMBOL	; Ensure within current bounds
	mov	esi,AGROUP:[esi].SYM_PNAM ; Get LA of symbol (CC_STR)
	UNCURB	esi,TXTSTR	; Ensure within current bounds
	lods	AGROUP:[esi].LO ; Get the length of the symbol
	movzx	ecx,al		; Copy to count register

    rep movs	AGROUP:[edi].LO,AGROUP:[esi].LO ; Copy the segment name

; Clear the class name format area

	lea	edi,MAP_SEGLINE2_CLASS ; Get offset in DGROUP of format area
	add	edi,LaDATA	; Plus LA of DGROUP

	push	edi		; Save for a moment

	mov	ecx,size MAP_SEGLINE2_CLASS ; # bytes to clear
	mov	al,' '          ; Clear to this
    rep stos	AGROUP:[edi].LO ; Clear it

	pop	edi		; Restore

; Copy class name to format area

	lea	edi,MAP_SEGLINE2_CLASS ; Get offset in DGROUP of format area

	jmp	WRITE_MAP_COMSEG1 ; Join common code


WRITE_MAP_DOSSEG1:

; Format segment start address

;;;;;;; UNCURB	esi,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[esi].PERSEG_ADRB.BOUND_BEG ; Copy start address
	mov	edx,eax 	; Copy for later use
	lea	edi,MAP_SEGLINE1_START ; Get offset in DGROUP of format area
	add	edi,LaDATA	; Plus LA of DGROUP
	call	D52HEX		; Convert EAX to Hex at ES:EDI

; Format segment length

;;;;;;; UNCURB	esi,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[esi].PERSEG_NEWLEN ; Get length of the segment
	lea	edi,MAP_SEGLINE1_LENGTH ; Get offset in DGROUP of format area
	add	edi,LaDATA	; Plus LA of DGROUP
	call	D52HEX		; Convert EAX to Hex at ES:EDI

; Format segment stop address

	cmp	eax,1		; If length is non-zero, decrement stop address
	cmc			; Complement so CF=1 is for length non-zero
	sbb	eax,0		; Subtract one if length is non-zero
	add	eax,edx 	; Add to get start of next segment

	lea	edi,MAP_SEGLINE1_STOP ; Get offset in DGROUP of format area
	add	edi,LaDATA	; Plus LA of DGROUP
	call	D52HEX		; Convert EAX to Hex at ES:EDI

; Clear the segment name format area

	lea	edi,MAP_SEGLINE1_SEGMENT ; Get offset in DGROUP of format area
	add	edi,LaDATA	; Plus LA of DGROUP

	push	edi		; Save for a moment

	mov	ecx,size MAP_SEGLINE1_SEGMENT ; # bytes to clear
	mov	al,' '          ; Clear to this
    rep stos	AGROUP:[edi].LO ; Clear it

	pop	edi		; Restore

; Copy segment name to format area

	push	esi		; Save for a moment

	UNCURB	esi,PERSEG	; Ensure within current bounds
	mov	esi,AGROUP:[esi].PERSEG_SEGSYM ; Get LA of SYM_STR
	mov	MAP_SYM_STR,esi ; Save LA of SYM_STR
	UNCURB	esi,SYMBOL	; Ensure within current bounds
	mov	esi,AGROUP:[esi].SYM_PNAM ; Get LA of symbol (CC_STR)
	UNCURB	esi,TXTSTR	; Ensure within current bounds
	lods	AGROUP:[esi].LO ; Get the length of the symbol
	movzx	ecx,al		; Copy to count register

    rep movs	AGROUP:[edi].LO,AGROUP:[esi].LO ; Copy the segment name

; Clear the class name format area

	lea	edi,MAP_SEGLINE1_CLASS ; Get offset in DGROUP of format area
	add	edi,LaDATA	; Plus LA of DGROUP

	push	edi		; Save for a moment

	mov	ecx,size MAP_SEGLINE1_CLASS ; # bytes to clear
	mov	al,' '          ; Clear to this
    rep stos	AGROUP:[edi].LO ; Clear it

	pop	edi		; Restore

; Copy class name to format area

	lea	edi,MAP_SEGLINE1_CLASS ; Get offset in DGROUP of format area
WRITE_MAP_COMSEG1:
	UNCURB	esi,TXTSTR	; Ensure within current bounds
	lods	AGROUP:[esi].LO ; Get the length of the symbol
	movzx	ecx,al		; Copy to count register

	add	edi,LaDATA	; Plus LA of DGROUP

    rep movs	AGROUP:[edi].LO,AGROUP:[esi].LO ; Copy the class name

; If we're doing /MAP:FULL, write out the segment USExx attr

	test	ARG_FLAG,@ARG_MAPFULL ; Izit a full map?
	jz	near ptr WRITE_MAP_XFULL ; Jump if not

	xor	eax,eax 	; Zero to use as dword
	mov	esi,MAP_SYM_STR ; Get LA of SYM_STR
	UNCURB	esi,SYMBOL	; Ensure within current bounds
	test	AGROUP:[esi].SYM_FLAG,@SYMFL_P ; Izit USE32?
	setnz	al		; AL = 1 iff USE32
	imul	eax,MAP_USE32_LEN ; Times byte length
	lea	esi,MAP_USE16[eax] ; Get offset in DGROUP of text

	mov	ecx,MAP_USE32_LEN ; Get length of text
    rep movs	AGROUP:[edi].LO,MAP_USE32[esi] ; Copy the USExx attribute

	mov	al,' '          ; Separator
	stos	AGROUP:[edi].LO ; Save in output area

; Write out the alignment type

	mov	esi,MAP_SYM_STR ; Get LA of SYM_STR
	UNCURB	esi,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[esi].SYM_FLAG ; Get the symbol flags
	and	eax,@ACBP_A	; Isolate the alignment bits
	shr	eax,$ACBP_A	; Shift to low-order
	mov	esi,ALINTYP[eax*(type ALINTYP)] ; Get offset in DGROUP of text
				; in CC_STR format
	lods	DGROUP:[esi].LO ; Get and skip over the count byte
	movzx	ecx,al		; Copy to count register
    rep movs	AGROUP:[edi].LO,DGROUP:[esi].LO ; Copy the alignment type

	lea	esi,MAP_ALIGNED ; DGROUP:ESI ==> trailing text
	mov	ecx,MAP_ALIGNED_LEN ; Length of ...
    rep movs	AGROUP:[edi].LO,MAP_ALIGNED[esi] ; Copy the trailing text

; Write out the combine type

	xor	eax,eax 	; Zero to use as dword
	mov	esi,MAP_SYM_STR ; Get LA of SYM_STR
	UNCURB	esi,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[esi].SYM_FLAG ; Get the flags
	and	eax,@SYMFL_C	; Isolate the combine type
	shr	eax,$SYMFL_C	; Shift to low-order
	mov	esi,CTYP_TAB[eax * (type CTYP_TAB)] ; Get offset in DGROUP
				; of text in CC_STR format
	lods	DGROUP:[esi].LO ; Get and skip over the count byte
	movzx	ecx,al		; Copy to count register
    rep movs	AGROUP:[edi].LO,CTYP_UNKNOWN[esi] ; Copy the combine type
WRITE_MAP_XFULL:
	pop	esi		; Restore

; Write out the segment description line

	cmp	EXE_WIN,1	; Izit EXETYPE WINDOWS?
	jne	short WRITE_MAP_DOSSEG2 ; Jump if not

	push	MAP_SEGLINE2_LEN ; Pass the length in bytes
	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MAP_SEGLINE2) ; Pass offset of message

	jmp	short WRITE_MAP_COMSEG2 ; Join common code


WRITE_MAP_DOSSEG2:
	push	MAP_SEGLINE1_LEN ; Pass the length in bytes
	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MAP_SEGLINE1) ; Pass offset of message
WRITE_MAP_COMSEG2:
	call	U32_DISP_MSGL	; Display the message

; If we're doing /MAP:FULL, write out one line for each .OBJ which
; contributed to this segment

	test	ARG_FLAG,@ARG_MAPFULL ; Izit a full map?
	jz	near ptr WRITE_MAP_NOFULL ; Jump if not

	UNCURB	esi,PERSEG	; Ensure within current bounds
	mov	ebx,AGROUP:[esi].PERSEG_SEG1ST ; Get 1st link in the chain
	mov	SEGOBJ_CNT,0	; Initialize count
WRITE_MAPFULL_NEXT:
	cmp	ebx,-1		; Izit the last?
	je	near ptr WRITE_MAPFULL_DONE ; Jump if so

	UNCURB	ebx,SEGOBJ	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].SEGOBJ_SIZ ; Get segment size

	and	eax,eax 	; Izit empty?
	jz	near ptr WRITE_MAPFULL_LOOP ; Jump if so (skip it)

	lea	edi,MAP_SEGOBJ_SIZ ; Get offset in DGROUP
	add	edi,LaDATA	; Plus LA of DGROUP
	call	D52HEX		; Convert EAX to Hex at ES:EDI

;;;;;;; UNCURB	ebx,SEGOBJ	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].SEGOBJ_OFF ; Get segment offset

;;;; If this is segment '_TEXT' and /DOSSEG is specified,
;;;; subtract out the size of the NULL para before displaying
;;;; the offset because that's what MS-LINK does (don't ask me).
;;;
;;;	test	ARG_FLAG,@ARG_DOSSEG ; Is /DOSSEG specified?
;;;	jz	short @F	; Jump if so
;;;
;;;	UNCURB	esi,PERSEG	; Ensure within current bounds
;;;	test	AGROUP:[esi].PERSEG_FLAG,@PERSEG__TEXT ; Izit '_TEXT'?
;;;	jz	short @F	; Jump if not
;;;
;;;	sub	eax,NONULLS_OFF ; Subtract size of NULL para
;;;@@:
	lea	edi,MAP_SEGOBJ_OFF ; Get offset in DGROUP
	add	edi,LaDATA	; Plus LA of DGROUP
	call	D52HEX		; Convert EAX to Hex at ES:EDI

; Write out the line
; If it's EXETYPE WINDOWS, shorten the line to match that header

	mov	eax,MAP_SEGOBJ_LEN ; Get the length in bytes
	lea	ecx,DGROUP:MAP_SEGOBJ ; Get offset of message

	cmp	EXE_WIN,1	; Izit EXETYPE WINDOWS?
	jne	short @F	; Jump if not

	add	ecx,@MAP_SEGOBJ_NRM - @MAP_SEGOBJ_NE ; Skip over leading blanks
	sub	eax,@MAP_SEGOBJ_NRM - @MAP_SEGOBJ_NE ; ...
@@:
	push	eax		; Pass the length in bytes
	push	fs		; ...  DGROUP segment
	push	ecx		; ...  offset of message
	call	U32_DISP_MSGL	; Display the message

	inc	SEGOBJ_CNT	; Count in another

; Display the .OBJ filename

	UNCURB	ebx,SEGOBJ	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].SEGOBJ_PPEROBJ ; Get LA of PEROBJ_STR

	UNCURB	eax,PEROBJ	; Ensure within current bounds
	push	AGROUP:[eax].PEROBJ_PFID ; Point to symbol (CC_STR)
	call	DISP_CNTCHR	; Display CC_STR

; If there's a THEADR record, display that, too

	push	1		; Display leading blank
	push	eax		; Pass LA of PEROBJ_STR as argument
	call	DISP_THEADR	; Display the THEADR if present

	call	U32_NEWLINE	; Goto a new line
WRITE_MAPFULL_LOOP:
	UNCURB	ebx,SEGOBJ	; Ensure within current bounds
	mov	ebx,AGROUP:[ebx].SEGOBJ_NXT ; Get next link in the chain

	jmp	WRITE_MAPFULL_NEXT ; Go around again


WRITE_MAPFULL_DONE:
	cmp	SEGOBJ_CNT,0	; Did we write out any lines?
	je	short @F	; Jump if not

	call	U32_NEWLINE	; Goto a new line
@@:
WRITE_MAP_NOFULL:
WRITE_MAP_LOOPSEG:
	UNCURB	esi,PERSEG	; Ensure within current bounds
	mov	esi,AGROUP:[esi].PERSEG_SEGSEQ ; Skip to next entry

	jmp	WRITE_MAP_NEXTSEG ; Go around again


WRITE_MAP_ENDSEG:
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;			GROUPS
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

; Trundle through the groups and write out a line for each

	mov	esi,LMB_PERGRP.LMB_CURB.BOUND_BEG ; Get starting LA

	cmp	esi,LMB_PERGRP.LMB_CURB.BOUND_NXT ; Are we at the end?
	je	near ptr WRITE_MAP_ENDGRP ; Jump if so

; Write out the group header

	push	MAP_GRPHDR_LEN	; Pass the length in bytes
	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MAP_GRPHDR) ; Pass offset of message
	call	U32_DISP_MSGL	; Display the message
WRITE_MAP_NEXTGRP:
	cmp	esi,LMB_PERGRP.LMB_CURB.BOUND_NXT ; Are we at the end?
	je	near ptr WRITE_MAP_ENDGRP ; Jump if so

; Format the group base segment

	cmp	EXE_WIN,1	; Izit EXETYPE WINDOWS?
	jne	short WRITE_MAP_GRP1 ; Jump if not

;;;;;;; UNCURB	esi,PERGRP	; Ensure within current bounds
	mov	eax,AGROUP:[esi].PERGRP_GRPLNK ; Get LA of next PERSEG_STR in chain

	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_CLS ; Get LA of class (PERCLS_STR)
	UNCURB	eax,PERCLS	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERCLS_PERLSEG ; Get LA of loigical segment (PERLSEG_STR)
	UNCURB	eax,PERLSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERLSEG_LSEG ; Get logical segment #

	jmp	short WRITE_MAP_GRP2 ; join common code


WRITE_MAP_GRP1:
;;;;;;; UNCURB	esi,PERGRP	; Ensure within current bounds
	mov	eax,AGROUP:[esi].PERGRP_ADRB.BOUND_BEG ; Copy start address
	shr	eax,4-0 	; Convert from paras to bytes
WRITE_MAP_GRP2:
	lea	edi,MAP_GRPLINE_SEG ; Get offset in DGROUP of format area
	add	edi,LaDATA	; Plus LA of DGROUP
	call	DW2HEX		; Convert AX to Hex at ES:EDI

; Format the group base offset

;;;;;;; UNCURB	esi,PERGRP	; Ensure within current bounds
	mov	eax,AGROUP:[esi].PERGRP_ADRB.BOUND_BEG ; Copy start address
	and	eax,@NIB0	; Convert from paras to bytes
	lea	edi,MAP_GRPLINE_OFF ; Get offset in DGROUP of format area
	add	edi,LaDATA	; Plus LA of DGROUP
	call	DG2HEX		; Convert digit in AL to Hex at ES:EDI

; Clear the group name format area

	lea	edi,MAP_GRPLINE_NAM ; Get offset in DGROUP of format area
	add	edi,LaDATA	; Plus LA of DGROUP

	push	edi		; Save for a moment

	mov	ecx,size MAP_GRPLINE_NAM ; # bytes to clear
	mov	al,' '          ; Clear to this
    rep stos	AGROUP:[edi].LO ; Clear it

	pop	edi		; Restore

; Copy group name to format area

	push	esi		; Save for a moment

	UNCURB	esi,PERGRP	; Ensure within current bounds
	mov	esi,AGROUP:[esi].PERGRP_GRPSYM ; Get LA of SYM_STR
	UNCURB	esi,SYMBOL	; Ensure within current bounds
	mov	esi,AGROUP:[esi].SYM_PNAM ; Get LA of symbol (CC_STR)
	UNCURB	esi,TXTSTR	; Ensure within current bounds
	lods	AGROUP:[esi].LO ; Get the length of the symbol
	movzx	ecx,al		; Copy to count register

    rep movs	AGROUP:[edi].LO,AGROUP:[esi].LO ; Copy the segment name

	pop	esi		; Restore

; Write out the group description line

	push	MAP_GRPLINE_LEN ; Pass the length in bytes
	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MAP_GRPLINE) ; Pass offset of message
	call	U32_DISP_MSGL	; Display the message
WRITE_MAP_LOOPGRP:
	add	esi,type PERGRP_STR ; Skip to next entry

	jmp	WRITE_MAP_NEXTGRP ; Go around again


WRITE_MAP_ENDGRP:
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;			EXPORTS
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

	cmp	EXE_WIN,1	; Izit EXETYPE WINDOWS?
	jne	near ptr WRITE_MAP_ENDEXP ; Jump if not

	mov	esi,LMB_EXPDEF.LMB_CURB.BOUND_BEG ; Get starting LA

	cmp	esi,LMB_EXPDEF.LMB_CURB.BOUND_NXT ; Are we at the end?
	je	near ptr WRITE_MAP_ENDEXP ; Jump if so

; Write out the exports header

	push	MAP_EXPHDR_LEN	; Pass the length in bytes
	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MAP_EXPHDR) ; Pass offset of message
	call	U32_DISP_MSGL	; Display the message
WRITE_MAP_NEXTEXP:
	cmp	esi,LMB_EXPDEF.LMB_CURB.BOUND_NXT ; Are we at the end?
	je	near ptr WRITE_MAP_ENDEXP ; Jump if so

; Format logical segment #

	UNCURB	esi,EXPDEF	; Ensure within current bounds
	mov	eax,AGROUP:[esi].EXPDEF_PSYM ; Get LA of symbol (SYM_STR)
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[eax].SYM_PERITEM ; Get LA of item (PUBDEF_STR)
	UNCURB	eax,PUBDEF	; Ensure within current bounds
	mov	ebx,AGROUP:[eax].PUBDEF_PPERSEG ; Get LA of segment (PERSEG_STR)
	UNCURB	ebx,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].PERSEG_CLS ; Get LA of class (PERCLS_STR)
	UNCURB	eax,PERCLS	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERCLS_PERLSEG ; Get LA of loigical segment (PERLSEG_STR)
	UNCURB	eax,PERLSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERLSEG_LSEG ; Get logical segment #
	lea	edi,MAP_EXPLINE_LSEG ; Get offset in DGROUP of format area
	add	edi,LaDATA	; Plus LA of DGROUP
	call	DW2HEX		; Convert AX to Hex at ES:EDI

; Format segment start offset

	UNCURB	ebx,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].PERSEG_ADRB.BOUND_BEG ; Copy start address
;;;;;;; UNCURB	ebx,PERSEG	; Ensure within current bounds
	mov	ebx,AGROUP:[ebx].PERSEG_CLS ; Get LA of class (PERCLS_STR)
	UNCURB	ebx,PERCLS	; Ensure within current bounds
	mov	ebx,AGROUP:[ebx].PERCLS_PERSEG1ST ; Get LA of 1st segment in class (PERSEG_STR)
	UNCURB	ebx,PERSEG	; Ensure within current bounds
	sub	eax,AGROUP:[ebx].PERSEG_ADRB.BOUND_BEG ; Less base address
	lea	edi,MAP_EXPLINE_START ; Get offset in DGROUP of format area
	add	edi,LaDATA	; Plus LA of DGROUP
	call	DW2HEX		; Convert AX to Hex at ES:EDI

; Clear the export name format area

	lea	edi,MAP_EXPLINE_EXPORT ; Get offset in DGROUP of format area
	add	edi,LaDATA	; Plus LA of DGROUP

	push	edi		; Save for a moment

	mov	ecx,size MAP_EXPLINE_EXPORT ; # bytes to clear
	mov	al,' '          ; Clear to this
    rep stos	AGROUP:[edi].LO ; Clear it

	pop	edi		; Restore

; Copy export name to format area

	push	esi		; Save for a moment

	UNCURB	esi,EXPDEF	; Ensure within current bounds
	lea	esi,AGROUP:[esi].EXPDEF_EXPNAME ; Get LA of symbol (CC_STR)
	UNCURB	esi,EXPDEF	; Ensure within current bounds
	lods	AGROUP:[esi].LO ; Get the length of the symbol
	movzx	ecx,al		; Copy to count register

    rep movs	AGROUP:[edi].LO,AGROUP:[esi].LO ; Copy the segment name

	pop	esi		; Restore

; Clear the internal name format area

	lea	edi,MAP_EXPLINE_ALIAS ; Get offset in DGROUP of format area
	add	edi,LaDATA	; Plus LA of DGROUP

	push	edi		; Save for a moment

	mov	ecx,size MAP_EXPLINE_ALIAS ; # bytes to clear
	mov	al,' '          ; Clear to this
    rep stos	AGROUP:[edi].LO ; Clear it

	pop	edi		; Restore

; Copy internal name to format area

	push	esi		; Save for a moment

	UNCURB	esi,EXPDEF	; Ensure within current bounds
	lea	esi,AGROUP:[esi].EXPDEF_INTNAME ; Get LA of symbol (CC_STR)
	UNCURB	esi,EXPDEF	; Ensure within current bounds
	lods	AGROUP:[esi].LO ; Get the length of the symbol
	movzx	ecx,al		; Copy to count register

    rep movs	AGROUP:[edi].LO,AGROUP:[esi].LO ; Copy the segment name

	pop	esi		; Restore

; Write out the exports line

	push	MAP_EXPLINE_LEN ; Pass the length in bytes
	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MAP_EXPLINE) ; Pass offset of message
	call	U32_DISP_MSGL	; Display the message

	add	esi,type EXPDEF_STR ; Skip to next entry

	jmp	WRITE_MAP_NEXTEXP ; Go around again


WRITE_MAP_ENDEXP:
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;			SYMBOLS BY NAME
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

	test	ARG_FLAG,@ARG_MAP ; Put symbol in this map?
	jz	short WRITE_MAP_ENDNAME ; Jump if not

	test	ARG_FLAG,@ARG_MAPADDR ; Map display by address only?
	jnz	short WRITE_MAP_ENDNAME ; Jump if so

; Write out the by-name header

	push	MAP_NAMHDR_LEN	; Pass the length in bytes
	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MAP_NAMHDR) ; Pass offset of message
	call	U32_DISP_MSGL	; Display the message

; Initialize PUBDEF_SRT indices

	call	INIT_PUBDEF_SRT ; Initialize 'em
				; Return EAX = # entries
	mov	ecx,eax 	; Copy # entries
	jecxz	WRITE_MAP_ENDNAME ; Jump if none to sort

; Sort PUBDEF_STR values by name

	push	offset PGROUP:CMP_BYNAME ; Pass address of compare routine
	call	SORT_PUBDEF	; Sort 'em

; Display PUBDEF_STR entries (by name)

	call	DISP_PUBDEF	; Display ECX PUBDEF_STR entries
	jc	near ptr WRITE_MAP_ERRWRIT ; Jump if something went wrong
WRITE_MAP_ENDNAME:
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;			SYMBOLS BY VALUE
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

	test	ARG_FLAG,@ARG_MAP ; Put symbol in this map?
	jz	short WRITE_MAP_ENDVAL ; Jump if not

; Write out the by-value header

	push	MAP_VALHDR_LEN	; Pass the length in bytes
	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MAP_VALHDR) ; Pass offset of message
	call	U32_DISP_MSGL	; Display the message

; Initialize PUBDEF_SRT indices

	call	INIT_PUBDEF_SRT ; Initialize 'em
				; Return EAX = # entries
	mov	ecx,eax 	; Copy # entries
	jecxz	WRITE_MAP_ENDVAL ; Jump if none to sort

; Sort PUBDEF_STR values by value

	push	offset PGROUP:CMP_BYVALUE ; Pass address of compare routine
	call	SORT_PUBDEF	; Sort 'em

; Display PUBDEF_STR entries (by value)

	call	DISP_PUBDEF	; Display ECX PUBDEF_STR entries
	jc	near ptr WRITE_MAP_ERRWRIT ; Jump if something went wrong
WRITE_MAP_ENDVAL:
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;			LINE NUMBERS
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

	test	ARG_FLAG,@ARG_LINE ; Displaying line numbers?
	jz	near ptr WRITE_MAP_ENDLINE1 ; Jump if not

	mov	esi,LMB_LINNUM.LMB_CURB.BOUND_BEG ; Get starting address
	mov	LAST_PEROBJ,0	; Initialize
	mov	LAST_PERSEG,0	; ...
	xor	edx,edx 	; Initialize field counter
WRITE_MAP_NEXTLINE:
	cmp	esi,LMB_LINNUM.LMB_CURB.BOUND_NXT ; Are we at the end?
	je	near ptr WRITE_MAP_ENDLINE ; Jump if so

; If we're at the start of an .OBJ file, display the header

	UNCURB	esi,LINNUM	; Ensure within current bounds
	mov	eax,AGROUP:[esi].LINNUM_PPEROBJ ; Get LA of PEROBJ_STR
	mov	ebx,AGROUP:[esi].LINNUM_PPERSEG ; ...	  of PERSEG_STR

	xchg	eax,LAST_PEROBJ ; Swap with the last one
	xchg	ebx,LAST_PERSEG ; ...

	cmp	eax,LAST_PEROBJ ; Izit the same as the last time?
	jne	short @F	; Jump if not

	cmp	ebx,LAST_PERSEG ; Izit the same as the last time?
	je	short WRITE_MAP_NOHDR ; Jump if so
@@:
	and	edx,edx 	; Any fields not displayed?
	jz	short @F	; Jump if not

	call	DISP_NUMLINE	; Display and then clear the number line
@@:

; If the Program Entry Point is in the last module, display it now

	cmp	eax,MODEND_PEROBJ ; Izit the same?
	jne	short @F	; Jump if not

; Write out the program entry point if there is one

	call	WritePEP	; Write it out
@@:
	push	MAP_NUMHDR_LEN	; Pass the length in bytes
	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MAP_NUMHDR) ; Pass offset of message
	call	U32_DISP_MSGL	; Display the message

	mov	eax,LAST_PEROBJ ; Get LA of last .OBJ (PEROBJ_STR)
	UNCURB	eax,PEROBJ	; Ensure within current bound
	push	AGROUP:[eax].PEROBJ_PFID ; Point to symbol (CC_STR)
	call	DISP_CNTCHR	; Display CC_STR

; If there's a THEADR record, display that, too

	push	0		; Do not display leading blank
	push	eax		; Pass LA of PEROBJ_STR as argument
	call	DISP_THEADR	; Display the THEADR if present

; Display the segment name

	push	MAP_NUMHDR1_LEN ; Pass the length in bytes
	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MAP_NUMHDR1) ; Pass offset of message
	call	U32_DISP_MSGL	; Display the message

	mov	eax,LAST_PERSEG ; Get LA of segment (PERSEG_STR)
	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_SEGSYM ; Get LA of symbol (SYM_STR)
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	push	AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (CC_STR)
	call	DISP_CNTCHR	; Display CC_STR

	call	U32_NEWLINE	; Goto a new line
	call	U32_NEWLINE	; Goto a new line
WRITE_MAP_NOHDR:

; Format the line #

	UNCURB	esi,LINNUM	; Ensure within current bounds
	mov	eax,AGROUP:[esi].LINNUM_LINNUM ; Get the line #
	imul	edi,edx,MAP_NUMLINE_FLD ; Skip to field
	add	edi,offset DGROUP:MAP_NUMLINE1 ; Plus offset in DGROUP
	add	edi,LaDATA	; Plus LA of DGROUP

	push	0		; No commas, right-justified
	call	DD2DEC		; Convert EAX to decimal ending at ES:EDI

; Format the group/segment

;;;;;;; UNCURB	esi,LINNUM	; Ensure within current bounds
	mov	eax,AGROUP:[esi].LINNUM_PPERGRP ; Get LA of group (PERGRP_STR)

	and	eax,eax 	; Izit invalid?
	jz	short WRITE_MAP_SEGLINE ; Jump if so (try segment)

	UNCURB	eax,PERGRP	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERGRP_ADRB.BOUND_BEG ; Get starting address
	shr	eax,4-0 	; Convert from bytes to paras

	jmp	short WRITE_MAP_SEGCOM ; Join common code


WRITE_MAP_SEGLINE:
	mov	eax,AGROUP:[esi].LINNUM_PPERSEG ; Get LA of segment (PERSEG_STR)

	and	eax,eax 	; Izit invalid?
	jz	short WRITE_MAP_SEGCOM ; Jump if so (call it zero)

	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_ADRB.BOUND_BEG ; Get starting address
	shr	eax,4-0 	; Convert from bytes to paras
WRITE_MAP_SEGCOM:
	imul	edi,edx,MAP_NUMLINE_FLD ; Skip to field
	add	edi,offset DGROUP:MAP_NUMLINE2 ; Plus offset in DGROUP
	add	edi,LaDATA	; Plus LA of DGROUP
	call	DW2HEX		; Convert AX to Hex at ES:EDI

	mov	AGROUP:[edi].LO,':' ; Save separator

; Format the offset

	UNCURB	esi,LINNUM	; Ensure within current bounds
	mov	eax,AGROUP:[esi].LINNUM_NUMOFF ; Get the line # offset
	imul	edi,edx,MAP_NUMLINE_FLD ; Skip to field
	add	edi,offset DGROUP:MAP_NUMLINE3 ; Plus offset in DGROUP
	add	edi,LaDATA	; Plus LA of DGROUP
	call	DW2HEX		; Convert AX to Hex at ES:EDI

	add	esi,type LINNUM_STR ; Skip to next entry
	inc	edx		; Skip to next field

	cmp	edx,4		; Izit at the end?
	jb	short @F	; Jump if not

; Display the line so far

	call	DISP_NUMLINE	; Display and then clear the number line
@@:
	jmp	WRITE_MAP_NEXTLINE ; Go around again


WRITE_MAP_ENDLINE:
	and	edx,edx 	; Any fields not displayed?
	jz	short @F	; Jump if not

	call	DISP_NUMLINE	; Display and then clear the number line
@@:
	jmp	short WRITE_MAP_END ; Join common code


WRITE_MAP_ENDLINE1:
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;			PROGRAM ENTRY POINT
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

; Write out the program entry point if there is one

	call	WritePEP	; Write it out
WRITE_MAP_END:
	call	WRITE_MAPBUF	; Write out the MAPOUT buffer
				; resetting LaMAPOUT in the process
	mov	bx,MAPHNDL	; Get .MAP file handle
	DOSCALL @CLOSF2 	; Close the file

	and	LCL_FLAG,not @LCL_MAPOUT ; Mark as no longer writing to map file

	jmp	short WRITE_MAP_EXIT ; Join common exit code


WRITE_MAP_ERRCREA:
	and	LCL_FLAG,not @LCL_MAPOUT ; Mark as no longer writing to map file

	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_MAPCREA) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	jmp	short WRITE_MAP_ERRCOM ; Join common error code


WRITE_MAP_ERRWRIT:
	call	WRITE_MAPBUF	; Write out the MAPOUT buffer
				; resetting LaMAPOUT in the process
	mov	bx,MAPHNDL	; Get .MAP file handle
	DOSCALL @CLOSF2 	; Close the file

	and	LCL_FLAG,not @LCL_MAPOUT ; Mark as no longer writing to map file

	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_MAPWRIT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message
WRITE_MAP_ERRCOM:
	stc			; Mark as in error
WRITE_MAP_EXIT:
	REGREST <ds>		; Restore
	assume	ds:AGROUP	; Tell the assembler about it
	popad			; ...

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WRITE_MAP endp			; End WRITE_MAP procedure
	NPPROC	WritePEP -- Write Program Entry Point
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Write program entry point

|

	REGSAVE <eax,edi>	; Save registers

	test	LCL_FLAG,@LCL_START ; Is there an entry point?
	jz	short WritePEPExit ; Jump if not

; If EXETYPE WINDOWS, display logical segment #

	mov	eax,NE_HDR.NE_CSIP ; Get NE PEP

	cmp	EXE_WIN,1	; Izit EXETYPE WINDOWS?
	je	short @F	; Jump if so

	mov	eax,100h	; Get program entry point for .COM file

	test	ARG_FLAG,@ARG_TINY ; Izit a .COM file?
	jnz	short @F	; Jump if so

	mov	eax,EXE_HDR.EXE_IP.EDD ; Get program entry point
@@:
	lea	edi,MAP_ENTRY_IP ; Get offset in DGROUP of format area
	add	edi,LaDATA	; Plus LA of DGROUP
	call	DW2HEX		; Convert AX to Hex at ES:EDI

	shr	eax,16		; Shift down the segment
	lea	edi,MAP_ENTRY_CS ; Get offset in DGROUP of format area
	add	edi,LaDATA	; Plus LA of DGROUP
	call	DW2HEX		; Convert AX to Hex at ES:EDI

	push	MAP_ENTRY_LEN	; Pass the length in bytes
	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MAP_ENTRY) ; Pass offset of message
	call	U32_DISP_MSGL	; Display the message
WritePEPExit:
	REGREST <edi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WritePEP endp			; End WritePEP procedure
	NPPROC	DISP_NUMLINE -- Display Number Line
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Display number line

On exit:

EDX	=	 0 (re-initialized field counter)

|

	REGSAVE <eax,ecx,edi>	; Save registers

	push	MAP_NUMLINE_LEN ; Pass the length in bytes
	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MAP_NUMLINE) ; Pass offset of message
	call	U32_DISP_MSGL	; Display the message

	lea	edi,MAP_NUMLINE ; Get offset in DGROUP
	add	edi,LaDATA	; Plus LA of DGROUP
	mov	ecx,MAP_NUMLINE_CLR ; # bytes to clear
	mov	al,' '          ; Clear to this
    rep stos   AGROUP:[edi].LO	; Clear it

	xor	edx,edx 	; Initialize field counter

	REGREST <edi,ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_NUMLINE endp		; End DISP_NUMLINE procedure
	NPPROC	INIT_PUBDEF_SRT -- Initialize PUBDEF_SRT Indices
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Initialize PUBDEF_SRT indices

On exit:

EAX	=	 # entries

|

	REGSAVE <edi>		; Save registers

	mov	edi,LMB_PUBDEF.LMB_CURB.BOUND_BEG ; Get start of data
	xor	eax,eax 	; Initialize index
INIT_PUBDEF_NEXT:
	cmp	edi,LMB_PUBDEF.LMB_CURB.BOUND_NXT ; Are we at the end?
	je	short INIT_PUBDEF_SRT_EXIT ; Jump if so

	UNCURB	edi,PUBDEF	; Ensure within current bounds
	mov	AGROUP:[edi].PUBDEF_SRT,eax ; Initialize the index
	inc	eax		; Skip to next index value

	add	edi,type PUBDEF_STR ; Skip to next entry

	jmp	INIT_PUBDEF_NEXT ; Go around again


INIT_PUBDEF_SRT_EXIT:
	REGREST <edi>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT_PUBDEF_SRT endp		; End INIT_PUBDEF_SRT procedure
	NPPROC	SORT_PUBDEF -- Sort PUBDEF_STR Items
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Sort PUBDEF_STR items (shell sort)

On entry:

ECX	=	 # entries to sort

|

SORT_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
SORT_CMP dd	?		; Offset in PGROUP of compare routine

SORT_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	pushad			; Save registers

	mov	edi,ecx 	; Copy # entries to sort
SORT_PUBDEF1:
	shr	edi,1		; Divide by two to get half index
	jz	short SORT_PUBDEF_EXIT ; Jump if there's no more

	mov	edx,edi 	; Copy half index
	dec	edx		; Undo next instruction
SORT_PUBDEF2:
	inc	edx		; Skip to next entry

	cmp	ecx,edx 	; Are we at the end?
	jbe	short SORT_PUBDEF1 ; Jump if so

	mov	esi,edx 	; Copy current index
SORT_PUBDEF3:
	sub	esi,edi
	jb	short SORT_PUBDEF2

	REGSAVE <esi,edi>	; Save for a moment

	add	edi,esi 	; Add to get ending index

	imul	esi,type PUBDEF_STR ; Get index into PUBDEF_STR
	add	esi,LMB_PUBDEF.LMB_CURB.BOUND_BEG ; Plus starting address
	UNCURB	esi,PUBDEF	; Ensure within current bounds
	mov	esi,AGROUP:[esi].PUBDEF_SRT ; Get index

	imul	edi,type PUBDEF_STR ; Get index into PUBDEF_STR
	add	edi,LMB_PUBDEF.LMB_CURB.BOUND_BEG ; Plus starting address
	UNCURB	edi,PUBDEF	; Ensure within current bounds
	mov	edi,AGROUP:[edi].PUBDEF_SRT ; Get index

	call	[ebp].SORT_CMP	; Compare entries at ESI & EDI
	REGREST <edi,esi>	; Restore
	jbe	short SORT_PUBDEF2 ; Jump if no swap

; Swap the two indices

	REGSAVE <esi,edi>	; Save for a moment

	add	edi,esi 	; Add to get ending index

	imul	esi,type PUBDEF_STR ; Get index into PUBDEF_STR
	add	esi,LMB_PUBDEF.LMB_CURB.BOUND_BEG ; Plus starting address
	UNCURB	esi,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[esi].PUBDEF_SRT ; Get index

	imul	edi,type PUBDEF_STR ; Get index into PUBDEF_STR
	add	edi,LMB_PUBDEF.LMB_CURB.BOUND_BEG ; Plus starting address
	UNCURB	edi,PUBDEF	; Ensure within current bounds
	xchg	eax,AGROUP:[edi].PUBDEF_SRT ; Swap indices
;;;;;;; UNCURB	esi,PUBDEF	; Ensure within current bounds
	mov	AGROUP:[esi].PUBDEF_SRT,eax ; ...

	REGREST <edi,esi>	; Restore

	jmp	short SORT_PUBDEF3 ; Go around again


SORT_PUBDEF_EXIT:
	popad			; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SORT_PUBDEF endp		; End SORT_PUBDEF procedure
	NPPROC	CMP_BYNAME -- Compare Entries By Name
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Compare entries by name

On entry:

ESI	=	 first index
EDI	=	 second index

On exit:

ZF	=	 1 if equal
CF	=	 1 if first < second
ESI,EDI  =	 clobbered

|

	REGSAVE <eax,ebx,ecx>	; Save registers

	imul	esi,type PUBDEF_STR ; Get index into PUBDEF_STR
	add	esi,LMB_PUBDEF.LMB_CURB.BOUND_BEG ; Plus starting address
	UNCURB	esi,PUBDEF	; Ensure within current bounds
	mov	esi,AGROUP:[esi].PUBDEF_PSYM ; Get LA of symbol (SYM_STR)
	UNCURB	esi,SYMBOL	; Ensure within current bounds
	mov	esi,AGROUP:[esi].SYM_PNAM ; Get LA of symbol (CC_STR)
	UNCURB	esi,TXTSTR	; Ensure within current bounds
	mov	al,AGROUP:[esi] ; Get the length of the symbol
	inc	esi		; Skip over it

	imul	edi,type PUBDEF_STR ; Get index into PUBDEF_STR
	add	edi,LMB_PUBDEF.LMB_CURB.BOUND_BEG ; Plus starting address
	UNCURB	edi,PUBDEF	; Ensure within current bounds
	mov	edi,AGROUP:[edi].PUBDEF_PSYM ; Get LA of symbol (SYM_STR)
	UNCURB	edi,SYMBOL	; Ensure within current bounds
	mov	edi,AGROUP:[edi].SYM_PNAM ; Get LA of symbol (CC_STR)
	UNCURB	edi,TXTSTR	; Ensure within current bounds
	mov	ah,AGROUP:[edi] ; Get the length of the symbol
	inc	edi		; Skip over it

	xor	ecx,ecx 	; Zero to use as dword
	mov	cl,al		; Copy to count reigster

	cmp	al,ah		; Use the shorter length
	jbe	short @F	; Jump if shorter

	mov	cl,ah		; Copy to count register
@@:
CMP_BYNAME_AGAIN:
   repe cmps   AGROUP:[esi].LO,AGROUP:[edi].LO ; Compare 'em
	je	short CMP_BYNAME_EQUAL ; Jump if equal

	mov	bl,AGROUP:[esi-1] ; Get last mismatch
	mov	bh,AGROUP:[edi-1] ; ...
	or	bx,2020h	; Convert to lowercase

	cmp	bl,bh		; Now try 'em
	je	short CMP_BYNAME_AGAIN ; Jump if it's only case different

	jmp	short CMP_BYNAME_EXIT ; Join common exit code (note ZF=0, CF significant)


CMP_BYNAME_EQUAL:
	cmp	al,ah		; Break the tie by the name length (note ZF=1)
CMP_BYNAME_EXIT:
	REGREST <ecx,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMP_BYNAME endp 		; End CMP_BYNAME procedure
	NPPROC	CMP_BYVALUE -- Compare Entries By Value
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Compare entries by value

On entry:

ESI	=	 first index
EDI	=	 second index

On exit:

ZF	=	 1 if equal
CF	=	 1 if first < second
ESI,EDI  =	 clobbered

|

	REGSAVE <eax,ebx,ecx,edx> ; Save registers

	mov	ebx,esi 	; Save in case we need to compare by name
	mov	ecx,edi 	; ...

	imul	esi,type PUBDEF_STR ; Get index into PUBDEF_STR
	imul	edi,type PUBDEF_STR ; ...
	add	esi,LMB_PUBDEF.LMB_CURB.BOUND_BEG ; Plus starting address
	add	edi,LMB_PUBDEF.LMB_CURB.BOUND_BEG ; ...

; If EXETYPE WINDOWS, compare using the logical sgment #

	cmp	EXE_WIN,1	; Izit EXETYPE WINDOWS?
	jne	near ptr CMP_BYVALUE_XWIN ; Jump if not

; If this is an imported symbol, use a logical segment # of zero

	UNCURB	esi,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[esi].PUBDEF_PSYM ; Get LA of symbol name (SYM_STR)

	UNCURB	eax,SYMBOL	; Ensure within current bounds
	test	AGROUP:[eax].SYM_FLAG,@SYMFL_IMP ; Izit Imported?
	mov	eax,0		; Assume it is
	jnz	short @F	; Jump if so

;;;;;;; UNCURB	esi,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[esi].PUBDEF_PPERSEG ; Get LA of segment (PERSEG_STR, 0=none)

	and	eax,eax 	; Izit invalid?
	jz	short @F	; Jump if so

	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_CLS ; Get LA of class (PERCLS_STR)
	UNCURB	eax,PERCLS	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERCLS_PERLSEG ; Get LA of logical segment (PERLSEG_STR)
	UNCURB	eax,PERLSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERLSEG_LSEG ; Get logical segment #
@@:

; If this is an imported symbol, use a logical segment # of zero

	UNCURB	edi,PUBDEF	; Ensure within current bounds
	mov	edx,AGROUP:[edi].PUBDEF_PSYM ; Get LA of symbol name (SYM_STR)

	UNCURB	edx,SYMBOL	; Ensure within current bounds
	test	AGROUP:[edx].SYM_FLAG,@SYMFL_IMP ; Izit Imported?
	mov	edx,0		; Assume it is
	jnz	short @F	; Jump if so

;;;;;;; UNCURB	edi,PUBDEF	; Ensure within current bounds
	mov	edx,AGROUP:[edi].PUBDEF_PPERSEG ; Get LA of segment (PERSEG_STR, 0=none)

	and	edx,edx 	; Izit invalid?
	jz	short @F	; Jump if so

	UNCURB	edx,PERSEG	; Ensure within current bounds
	mov	edx,AGROUP:[edx].PERSEG_CLS ; Get LA of class (PERCLS_STR)
	UNCURB	edx,PERCLS	; Ensure within current bounds
	mov	edx,AGROUP:[edx].PERCLS_PERLSEG ; Get LA of logical segment (PERLSEG_STR)
	UNCURB	edx,PERLSEG	; Ensure within current bounds
	mov	edx,AGROUP:[edx].PERLSEG_LSEG ; Get logical segment #
@@:
	cmp	eax,edx 	; Izit same logical segment #?
	jne	short CMP_BYVALUE_EXIT ; Jump if not (note ZF=0, CF significant)

; As a tie breaker, try comparing the offsets

;;;;;;; UNCURB	esi,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[esi].PUBDEF_ADDR ; Get base + offfset address
;;;;;;; UNCURB	esi,PUBDEF	; Ensure within current bounds
	mov	esi,AGROUP:[esi].PUBDEF_BASE ; Get base address to get offset
	and	esi,not (16-1)	; Round down to para boundary *FIXME*
	sub	eax,esi 	; Less base address to get offset

;;;;;;; UNCURB	edi,PUBDEF	; Ensure within current bounds
	mov	edx,AGROUP:[edi].PUBDEF_ADDR ; Get base + offfset address
;;;;;;; UNCURB	edi,PUBDEF	; Ensure within current bounds
	mov	edi,AGROUP:[edi].PUBDEF_BASE ; Get base address to get offset
	and	edi,not (16-1)	; Round down to para boundary *FIXME*
	sub	edx,edi 	; Less base address to get offset

	cmp	eax,edx 	; Izit same logical segment #?
	jne	short CMP_BYVALUE_EXIT ; Jump if not (note ZF=0, CF significant)

; As a further tie breaker, try comparing the names

	jmp	short CMP_BYVALUE_BYNAME ; Join common code


CMP_BYVALUE_XWIN:
	UNCURB	esi,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[esi].PUBDEF_ADDR ; Get base + offset

	UNCURB	edi,PUBDEF	; Ensure within current bounds
	cmp	eax,AGROUP:[edi].PUBDEF_ADDR ; Compare 'em
	jne	short CMP_BYVALUE_EXIT ; Jump if the not same (note ZF=0, CF significant)

; As a tie breaker, try comparing the base addresses

;;;;;;; UNCURB	esi,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[esi].PUBDEF_BASE ; Get base

;;;;;;; UNCURB	edi,PUBDEF	; Ensure within current bounds
	cmp	eax,AGROUP:[edi].PUBDEF_BASE ; Compare 'em
	jne	short CMP_BYVALUE_EXIT ; Jump if the not same (note ZF=0, CF significant)

; As a further tie breaker, try comparing the names

CMP_BYVALUE_BYNAME:
	mov	esi,ebx 	; Restore original values
	mov	edi,ecx 	; ...
	call	CMP_BYNAME	; Compare 'em by name
				; Return with ZF & CF significant
CMP_BYVALUE_EXIT:
	REGREST <edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMP_BYVALUE endp		; End CMP_BYVALUE procedure
	NPPROC	DISP_PUBDEF -- Display PUBDEF_STR Entries
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Display PUBDEF_STR entries

On entry:

ECX	=	# entries to display

|

	pushad			; Save registers

	mov	esi,LMB_PUBDEF.LMB_CURB.BOUND_BEG ; Get starting address
DISP_PUBDEF_NEXT:
	cmp	esi,LMB_PUBDEF.LMB_CURB.BOUND_NXT ; Are we at the end?
	je	near ptr DISP_PUBDEF_EXIT ; Jump if so

	UNCURB	esi,PUBDEF	; Ensure within current bounds
	mov	ebx,AGROUP:[esi].PUBDEF_SRT ; Get next sort index
	imul	ebx,type PUBDEF_STR ; Get index into PUBDEF_STR
	add	ebx,LMB_PUBDEF.LMB_CURB.BOUND_BEG ; Plus starting address

; If this is a temp or local symbol, don't display it

	UNCURB	ebx,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].PUBDEF_PSYM ; Get LA of symbol name (SYM_STR)

	UNCURB	eax,SYMBOL	; Ensure within current bounds
	test	AGROUP:[eax].SYM_FLAG,@SYMFL_TEMP or @SYMFL_LOCAL ; Izit temp or local?
	jnz	near ptr DISP_PUBDEF_LOOP ; Jump if either

	cmp	EXE_WIN,1	; Izit EXETYPE WINDOWS?
	jne	short DISP_PUBDEF1 ; Jump if not

; If this is an imported symbol, use a logical segment # of zero

	lea	edi,MAP_PUBLINE2_SEG ; Get offset in DGROUP of format area

;;;;;;; UNCURB	eax,SYMBOL	; Ensure within current bounds
	test	AGROUP:[eax].SYM_FLAG,@SYMFL_IMP ; Izit Imported?
	mov	eax,0		; Assume it is
	jnz	short DISP_PUBDEF2 ; Jump if so

; Display the logical segment #

;;;;;;; UNCURB	ebx,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].PUBDEF_PPERSEG ; Get LA of segment (PERSEG_STR, 0=none)

	and	eax,eax 	; Izit invalid?
	jz	short DISP_PUBDEF2 ; Jump if so

	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_CLS ; Get LA of class (PERCLS_STR)
	UNCURB	eax,PERCLS	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERCLS_PERLSEG ; Get LA of logical segment (PERLSEG_STR)
	UNCURB	eax,PERLSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERLSEG_LSEG ; Get logical segment #

	jmp	short DISP_PUBDEF2 ; Join common code


DISP_PUBDEF1:
;;;;;;; UNCURB	ebx,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].PUBDEF_BASE ; Get base address
	shr	eax,4-0 	; Convert from paras to bytes

	lea	edi,MAP_PUBLINE1_SEG ; Get offset in DGROUP of format area
DISP_PUBDEF2:
	add	edi,LaDATA	; Plus LA of DGROUP
	call	DW2HEX		; Convert AX to hex at ES:EDI

;;;;;;; UNCURB	ebx,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].PUBDEF_ADDR ; Get base + offfset address
;;;;;;; UNCURB	ebx,PUBDEF	; Ensure within current bounds
	mov	ecx,AGROUP:[ebx].PUBDEF_BASE ; Get base address to get offset
	and	ecx,not (16-1)	; Round down to para boundary *FIXME*
	sub	eax,ecx 	; Less base address to get offset

	lea	edi,MAP_PUBLINE1_OFF ; Get offset in DGROUP of format area

	cmp	EXE_WIN,1	; Izit EXETYPE WINDOWS?
	jne	short @F	; Jump if not

	lea	edi,MAP_PUBLINE2_OFF ; Get offset in DGROUP of format area
@@:
	add	edi,LaDATA	; Plus LA of DGROUP

; Display offset as DW or DD depending upon USE32 attribute

;;;;;;; UNCURB	ebx,PUBDEF	; Ensure within current bounds
	mov	edx,AGROUP:[ebx].PUBDEF_PSYM ; Get LA of symbol name (SYM_STR)

	lea	ecx,DD2HEX	; Assume USE32

	test	DBG_FLAG,@DBG_MAP16 ; Display as USE16 anyway?
	jnz	short @F	; Jump if so

	UNCURB	edx,SYMBOL	; Ensure within current bounds
	test	AGROUP:[edx].SYM_FLAG,@SYMFL_P ; Izit USE32?
	jnz	short DISP_PUBDEF2A ; Jump if so
@@:
	mov	AGROUP:[edi+4].EDD,'    ' ; Clear the trailing text
	lea	ecx,DW2HEX	; It's USE16
DISP_PUBDEF2A:
	call	ecx		; Convert eAX to hex at ES:EDI

; If this symbol is an Absolute Constant, display marker

	push	esi		; Save for a moment

	lea	esi,MAP_REL	; Get offset in DGROUP of text

	UNCURB	edx,SYMBOL	; Ensure within current bounds
	test	AGROUP:[edx].SYM_FLAG,@SYMFL_ABSCON ; Izit Absolute Constant?
	jz	short @F	; Jump if not

	lea	esi,MAP_ABS	; Get offset in DGROUP of text
@@:
	UNCURB	edx,SYMBOL	; Ensure within current bounds
	test	AGROUP:[edx].SYM_FLAG,@SYMFL_IMP ; Izit Imported?
	jz	short @F	; Jump if not

	lea	esi,MAP_IMP	; Get offset in DGROUP of text
@@:
	mov	ecx,MAP_ABS_LEN ; Get # bytes in text
	mov	edi,PMAP_PUBLINE_ABS ; Get offset in DGROUP
	add	edi,LaDATA	; Plus LA of DGROUP
    rep movs	AGROUP:[edi].LO,MAP_ABS[esi] ; Copy to output area

	pop	esi		; Restore

; Display the line so far

	push	PMAP_PUBLINE_LEN ; Pass the length in bytes
	push	fs		; Pass DGROUP segment
	lea	eax,MAP_PUBLINE1 ; Pass offset of message

	cmp	EXE_WIN,1	; Izit EXETYPE WINDOWS?
	jne	short @F	; Jump if not

	lea	eax,MAP_PUBLINE2 ; Pass offset of message
@@:
	push	eax		; Pass offset of message
	call	U32_DISP_MSGL	; Display the message

; Display the name of the symbol

	UNCURB	edx,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[edx].SYM_PNAM ; Pass LA of symbol (CC_STR)
	UNCURB	eax,TXTSTR	; Ensure within current bounds
	movzx	ecx,AGROUP:[eax].CC_COUNT ; Get the count
	add	eax,type CC_COUNT ; Skip over it

	push	ds		; Pass ptr to string
	push	eax		; ...
	push	ecx		; ...  length of ...
	push	@MAP_NAMLINE	; ...  pad length
	push	fs		; ...  ptr to format string
	push	offset DGROUP:MAP_NAMLINE1 ; ...
	push	cs		; ...  ptr to output routine
	push	offset PGROUP:RPRINTF_OUT ; ...
	call	RPRINTF32	; RPrintf it, return with EAX = # chars printed
	add	esp,4*8 	; Strip from stack

; If this is EXE_WIN and the symbol is imported, display the name and
; entry point of the import module.

	cmp	EXE_WIN,1	; Izit EXETYPE WINDOWS?
	jne	near ptr DISP_PUBDEF_XWIN ; Jump if not

	UNCURB	edx,SYMBOL	; Ensure within current bounds
	test	AGROUP:[edx].SYM_FLAG,@SYMFL_IMP ; Izit imported?
	jz	near ptr DISP_PUBDEF_XWIN ; Jump if not

	UNCURB	ebx,PUBDEF	; Ensure within current bounds
	mov	edi,AGROUP:[ebx].PUBDEF_IMPDEF ; Get LA of import (IMPDEF_STR)

; If this symbol is imported by ordinal, display it

	UNCURB	edi,IMPDEF	; Ensure within current bounds
	cmp	AGROUP:[edi].IMPDEF_FLAG,0 ; Izit by name?
	je	short @F	; Jump if so

	push	AGROUP:[edi].IMPDEF_ORDINAL.EDD ; Pass # to format
	push	fs		; ...  ptr to format string
	push	offset DGROUP:MAP_NAMLINE3 ; ...
	push	fs		; ...  ptr to buffer
	push	offset DGROUP:MAP_NAMLINE4 ; ...
	call	SPRINTF32	; Sprintf it, return with EAX = # chars printed
	add	esp,4*5 	; Strip from stack

	mov	ecx,eax 	; Copy # chars sprintfed
	lea	eax,MAP_NAMLINE4 ; DGROUP:EAX ==> buffer
	add	eax,LaDATA	; AGROUP:EAX ==> ...

	jmp	short DISP_PUBDEF_IMP1 ; Join common code


@@:
	UNCURB	edi,IMPDEF	; Ensure within current bounds
	lea	eax,AGROUP:[edi].IMPDEF_ENTRY ; Get LA of entry name (CC_STR)
	UNCURB	eax,IMPDEF	; Ensure within current bounds
	movzx	ecx,AGROUP:[eax].CC_COUNT ; Get the count
	add	eax,type CC_COUNT ; Skip over it
DISP_PUBDEF_IMP1:
	push	ds		; Pass ptr to entry name string
	push	eax		; ...
	push	ecx		; ...  length of

;;;;;;; UNCURB	edi,IMPDEF	; Ensure within current bounds
	mov	eax,AGROUP:[edi].IMPDEF_PPERMOD ; Get LA of module (PERMOD_STR)

	UNCURB	eax,PERMOD	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERMOD_MODSYM ; Get LA of module name (SYM_STR)

	UNCURB	eax,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[eax].SYM_PNAM ; Get LA of module name (CC_STR)
	UNCURB	eax,TXTSTR	; Ensure within current bounds
	movzx	ecx,AGROUP:[eax].CC_COUNT ; Get the count
	add	eax,type CC_COUNT ; Skip over it

	push	ds		; Pass ptr to module name string
	push	eax		; ...
	push	ecx		; ...  length of

	push	fs		; ...  ptr to format string
	push	offset DGROUP:MAP_NAMLINE2 ; ...
	push	cs		; ...  ptr to output routine
	push	offset PGROUP:RPRINTF_OUT ; ...
	call	RPRINTF32	; RPrintf it, return with EAX = # chars printed
	add	esp,4*10	; Strip from stack
DISP_PUBDEF_XWIN:
	call	U32_NEWLINE	; Goto a new line
DISP_PUBDEF_LOOP:
	add	esi,type PUBDEF_STR ; Skip to next entry

	jmp	DISP_PUBDEF_NEXT ; Go around again


DISP_PUBDEF_ERRWRIT:
	stc			; Mark as in error
DISP_PUBDEF_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_PUBDEF endp		; End DISP_PUBDEF procedure
	FPPROC	RPRINTF_OUT -- RPRINTF Output Routine
	assume	ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

RPRINTF output routine

On entry:

DL	=	char to write

|

	REGSAVE <ebx,ecx,ds>	; Save registers

	cmp	dl,0		; Izit EOL?
	je	short RPRINTF_OUT_EXIT ; Jump if so

	push	edx		; Save the char in memory

	mov	edx,ss		; Copy stack selector
	mov	ds,edx		; Address it
	assume	ds:nothing	; Tell the assembler about it

	mov	edx,esp 	; DS:EDX ==> char to write
	mov	ecx,1		; Get # chars to write out

	call	WRITE_OUT	; Write DS:EDX for ECX bytes to output file
				; Return with CF significant
	pop	edx		; Restore
RPRINTF_OUT_EXIT:
	REGREST <ds,ecx,ebx>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RPRINTF_OUT endp		; End RPRINTF_OUT procedure

CODE	ends			; End CODE segment

	MEND			; End QLNK_MAP module
