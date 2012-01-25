;' $Header$
; (C) Copyright 1995 Qualitas, Inc.  All rights reserved.
;
; LIB.INC
;
; Library File structures and equates
;

LIBHDR_STR struc		; Library header struc

LIBHDR_TYPE db	 ?		; 00:  Type byte (F0h)
LIBHDR_RLEN dw	 ?		; 01:  Record length
LIBHDR_DOFF dd	 ?		; 03:  Dictionary offset
LIBHDR_DSIZ dw	 ?		; 07:  Dictionary size in blocks
LIBHDR_FLAG db	 ?		; 09:  Flags:  see LIBHDR_REC below

LIBHDR_STR ends

LIBHDR_REC record \
		  $LIBHDR_CASE:1

@LIBHDR_CASE equ (mask $LIBHDR_CASE) ; 01:  Name comparisons are case-sensitive


LIBXHDR_STR struc		; Library ext dict header struc

LIBXHDR_TYPE db  ?		; Type byte (F2h)
LIBXHDR_RLEN dw  ?		; Record length
LIBXHDR_NMOD dw  ?		; # modules in library

LIBXHDR_STR ends


LIBXMOD_STR struc		; Library ext dict module table

LIBXMOD_PGNO dw  ?		; Page #
LIBXMOD_PMOD dw  ?		; Offset from start of extended dictionary
				; to list of dependent modules (null-terminated)
LIBXMOD_STR ends


LIBDEP_STR struc		; Library dependency table in extended dictionary

LIBDEP_MOD dw	 ?		; Dependent module #

LIBDEP_STR ends


