;' $Header:   P:/PVCS/MISC/QLINK/QLNK_LIN.INV   1.1   17 Jul 1997 12:36:48   BOB  $
;
; (C) Copyright 1994-2000 Qualitas, Inc.  All rights reserved.
;
; QLNK_LIN.INC
;
; Command line argument processing
;


SWTAB_STR struc 		; Switch table structure

SWTAB_NARGS dd	?		; # arguments in tables
SWTAB_TAB dd	?		; Offset to text table
SWTAB_MIN dd	?		; ...	    minimum byte length ...
SWTAB_MAX dd	?		; ...	    maximum byte length ...
SWTAB_ACT dd	?		; ...	    action routine ...

SWTAB_STR ends


LINARG_MAC macro TXT,MIN_TXT,ACT,LCL
	local	LCL_TXT,LCL_MIN,LCL_MAX

LCL_MIN sizestr <MIN_TXT>	; Get minimum text count


NTEXT	segment use16 byte public 'ncode' ; Start NTEXT segment
	assume	ds:NGROUP

LCL_TXT db	TXT
LCL_MAX equ	$-LCL_TXT

NTEXT	ends			; End NTEXT segment


NSEGMIN segment use16 word public 'ncode' ; Start NSEGMIN segment
	assume	ds:NGROUP

	dw	LCL_MIN-2	; less leading and trailing quotes

NSEGMIN ends			; End NSEGMIN segment


NSEGMAX segment use16 word public 'ncode' ; Start NSEGMAX segment
	assume	ds:NGROUP

	dw	LCL_MAX

NSEGMAX ends			; End NSEGMAX segment


NSEGTAB segment use16 dword public 'ncode' ; Start NSEGTAB segment
	assume	ds:NGROUP

	dd	NGROUP:LCL_TXT

NSEGTAB ends			; End NSEGTAB segment


NSEGACT segment use16 word public 'ncode' ; Start NSEGACT segment
	assume	ds:NGROUP

	dw	offset NGROUP:ACT

NSEGACT ends			; End NSEGACT segment


ifb <LCL>
NCODE	segment use16 byte public 'ncode' ; Start NCODE segment
	assume	cs:NGROUP

	extrn	ACT:near

NCODE	ends			; End NCODE segment
endif				; IFB <LCL>

	endm			; LINARG_MAC


INISEG_MAC macro NAM		; Initialize segments for switch tables

NSEGTAB segment use16 dword public 'ncode' ; Start NSEGTAB segment
	assume	ds:NGROUP

	public	&NAM&ARG_TAB
&NAM&ARG_TAB label dword

NSEGTAB ends			; End NSEGTAB segment


NSEGMIN segment use16 word public 'ncode' ; Start NSEGMIN segment
	assume	ds:NGROUP

	public	&NAM&ARG_MIN
&NAM&ARG_MIN label word

NSEGMIN ends			; End NSEGMIN segment


NSEGMAX segment use16 word public 'ncode' ; Start NSEGMAX segment
	assume	ds:NGROUP

	public	&NAM&ARG_MAX
&NAM&ARG_MAX label word

NSEGMAX ends			; End NSEGMAX segment


NSEGACT segment use16 word public 'ncode' ; Start NSEGACT segment
	assume	ds:NGROUP

	public	&NAM&ARG_ACT
&NAM&ARG_ACT label word

NSEGACT ends			; End NSEGACT segment

	endm			; INISEG_MAC


ENDSEG_MAC macro NAM		; End segment macro for switch tables

NSEGTAB segment use16 dword public 'ncode' ; Start NSEGTAB segment
	assume	ds:NGROUP

	public	N&NAM&ARGS
N&NAM&ARGS equ	($-&NAM&ARG_TAB)/(type &NAM&ARG_TAB) ; Its length

NSEGTAB ends			; End NSEGTAB segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public	TAB_&NAM&_SW
TAB_&NAM&_SW SWTAB_STR <N&NAM&ARGS,		   \
		     offset NGROUP:&NAM&ARG_TAB,  \
		     offset NGROUP:&NAM&ARG_MIN,  \
		     offset NGROUP:&NAM&ARG_MAX,  \
		     offset NGROUP:&NAM&ARG_ACT>

DATA	ends			; End DATA segment

	endm			; ENDSEG_MAC


