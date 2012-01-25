;' $Header$
;
; (C) Copyright 2000-2003 Qualitas, Inc.  All rights reserved.
;
; QLNK_DBG.INC
;
; Debug flags
;

DBG_REC record \
$DBG_STMSGS:1,	\
$DBG_MAP16:1,	\
$DBG_BOUND:1,	\
$DBG_PUBDEF:1,	\
$DBG_LIB:1,	\
$DBG_FIXUP:1,	\
$DBG_MSGS:1,	\
$DBG_ERROR:1,	\
$DBG_STATS:1

@DBG_STMSGS equ (mask $DBG_STMSGS)	; 00000100:  Display DEBUG Status Messages
@DBG_MAP16  equ (mask $DBG_MAP16)	; 00000080:  Display .MAP as USE16
@DBG_BOUND  equ (mask $DBG_BOUND)	; 00000040:  Debugging BOUND errors
@DBG_PUBDEF equ (mask $DBG_PUBDEF)	; 00000020:  Display PUBDEF symbol messages
@DBG_LIB    equ (mask $DBG_LIB) 	; 00000010:  Debugging LIB hashing
@DBG_FIXUP  equ (mask $DBG_FIXUP)	; 00000008:  Display debugging fixup msgs
@DBG_MSGS   equ (mask $DBG_MSGS)	; 00000004:  Display debugging messages
@DBG_ERROR  equ (mask $DBG_ERROR)	; 00000002:  Send errors to .ERR file
@DBG_STATS  equ (mask $DBG_STATS)	; 00000001:  Send statistics ...


; Note we omit MAP16 from the ALL category as it is a
; very specific action.

@DBG_ALL equ	\
@DBG_STMSGS or	\
@DBG_BOUND  or	\
@DBG_PUBDEF or	\
@DBG_LIB    or	\
@DBG_FIXUP  or	\
@DBG_MSGS   or	\
@DBG_ERROR  or	\
@DBG_STATS


DEBUGMSG macro	TXT
	local	L1,L2
if DEBUG

DATA	segment use32 dword public 'data' ; Start DATA segment

L2	db	TXT,EOS

DATA	ends			; End DATA segment


	pushfd			; Save flags

	test	DBG_FLAG,@DBG_STMSGS ; Display DEBUG Status Messages?
	jz	short L1	; Jump if not

; *FIXME* Ensure DS points to data segment

	REGSAVE <eax,edx>	; Save registers
	xor	edx,edx 	; Zero to use as dword
	DOSCALL @STROUT,L2	; Display DEBUG Status Message
	REGREST <edx,eax>	; Restore
L1:
	popfd			; Restore
endif
	endm			; End DEBUGMSG macro


