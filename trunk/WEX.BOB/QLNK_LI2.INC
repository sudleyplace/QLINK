;' $Header$
;
; (C) Copyright 1994-2000 Qualitas, Inc.  All rights reserved.
;
; QLNK_LI2.INC
;
; Command line argument processing
;


LINARG_MA2 macro TXT,MIN_TXT,ACT,LCL
	local	LCL_TXT,LCL_MIN,LCL_MAX

LCL_MIN sizestr <MIN_TXT>       ; Get minimum text count


TEXT	segment use32 byte public 'data' ; Start TEXT segment
	assume	ds:DGROUP

LCL_TXT db	TXT
LCL_MAX equ	$-LCL_TXT

TEXT	ends			; End TEXT segment


DSEGMIN segment use32 dword public 'data' ; Start DSEGMIN segment
	assume	ds:DGROUP

	dd	LCL_MIN-2       ; less leading and trailing quotes

DSEGMIN ends			; End DSEGMIN segment


DSEGMAX segment use32 dword public 'data' ; Start DSEGMAX segment
	assume	ds:DGROUP

	dd	LCL_MAX

DSEGMAX ends			; End DSEGMAX segment


DTAB	segment use32 dword public 'data' ; Start DTAB segment
	assume	ds:DGROUP

	dd	DGROUP:LCL_TXT

DTAB	ends			; End DTAB segment


DSEGACT segment use32 dword public 'data' ; Start DSEGACT segment
	assume	ds:DGROUP

	dd	offset PGROUP:ACT

DSEGACT ends			; End DSEGACT segment


ifb <LCL>
CODE	segment use32 byte public 'prog' ; Start CODE segment
	assume	cs:PGROUP

	extrn	ACT:near

CODE	ends			; End CODE segment
endif				; IFB <LCL>

	endm			; LINARG_MA2


INISEG_MA2 macro NAM		; Initialize segments for switch tables

DTAB	segment use32 dword public 'data' ; Start DTAB segment
	assume	ds:DGROUP

	public	&NAM&ARG_TAB
&NAM&ARG_TAB label dword

DTAB	ends			; End DTAB segment


DSEGMIN segment use32 dword public 'data' ; Start DSEGMIN segment
	assume	ds:DGROUP

	public	&NAM&ARG_MIN
&NAM&ARG_MIN label dword

DSEGMIN ends			; End DSEGMIN segment


DSEGMAX segment use32 dword public 'data' ; Start DSEGMAX segment
	assume	ds:DGROUP

	public	&NAM&ARG_MAX
&NAM&ARG_MAX label dword

DSEGMAX ends			; End DSEGMAX segment


DSEGACT segment use32 dword public 'data' ; Start DSEGACT segment
	assume	ds:DGROUP

	public	&NAM&ARG_ACT
&NAM&ARG_ACT label dword

DSEGACT ends			; End DSEGACT segment

	endm			; INISEG_MA2


ENDSEG_MA2 macro NAM		; End segment macro for switch tables

DTAB	segment use32 dword public 'data' ; Start DTAB segment
	assume	ds:DGROUP

	public	N&NAM&ARGS
N&NAM&ARGS equ	($-&NAM&ARG_TAB)/(type &NAM&ARG_TAB) ; Its length

DTAB ends			; End DTAB segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public  TAB_&NAM&_SW
TAB_&NAM&_SW SWTAB_STR <N&NAM&ARGS,		   \
		     offset DGROUP:&NAM&ARG_TAB,  \
		     offset DGROUP:&NAM&ARG_MIN,  \
		     offset DGROUP:&NAM&ARG_MAX,  \
		     offset DGROUP:&NAM&ARG_ACT>

DATA	ends			; End DATA segment

	endm			; ENDSEG_MA2

