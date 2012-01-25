;' $Header:   P:/PVCS/MISC/QLINK/QLNK_IWF.INV   1.1   07 Aug 1998 16:00:10   BOB  $
;
; (C) Copyright 1994-2000 Qualitas, Inc.  All rights reserved.
;
; QLNK_IWF.INC
;
; Argument flags
;

@IWF_IGN equ	 00b		; Ignore this event
@IWF_WRN equ	 01b		; Warn about this event
@IWF_FAL equ	 10b		; Fail this event
@IWF_ACT equ	 @IWF_WRN or @IWF_FAL ; Take some action if either set


IWF_REC  record  \
		 $IWF_OMFIGN :2=@IWF_FAL, \
		 $IWF_OMFUNK :2=@IWF_FAL, \
		 $IWF_CSUMINV:2=@IWF_FAL, \
		 $IWF_CTYPINV:2=@IWF_FAL, \
		 $IWF_ALININV:2=@IWF_FAL, \
		 $IWF_ALINDIF:2=@IWF_FAL, \
		 $IWF_USEDIF :2=@IWF_FAL, \
		 $IWF_GRPINV :2=@IWF_FAL, \
		 $IWF_GRPDIF :2=@IWF_FAL, \
		 $IWF_SEGBIG :2=@IWF_FAL, \
		 $IWF_GRPBIG :2=@IWF_FAL, \
		 $IWF_GRPMIX :2=@IWF_FAL, \
		 $IWF_FIXOVF :2=@IWF_FAL, \
		 $IWF_ABSOVF :2=@IWF_FAL, \
		 $IWF_ABSDIF :2=@IWF_FAL, \
		 $IWF_TYPDIF :2=@IWF_FAL

@IWF_OMFIGN  equ (mask $IWF_OMFIGN)	; Ignorable OMF record
@IWF_OMFUNK  equ (mask $IWF_OMFUNK)	; Unknown ...
@IWF_CSUMINV equ (mask $IWF_CSUMINV)	; Invalid checksum in OMF record
@IWF_CTYPINV equ (mask $IWF_CTYPINV)	; Invalid combine type in SEGDEF
@IWF_ALININV equ (mask $IWF_ALININV)	; ...	  alignment ...
@IWF_ALINDIF equ (mask $IWF_ALINDIF)	; Differing alignment types
					; between SEGDEF records
@IWF_USEDIF  equ (mask $IWF_USEDIF)	; Differing USE16 and USE32 attributes
					; between SEGDEF records
@IWF_GRPINV  equ (mask $IWF_GRPINV)	; Invalid group component descriptor
					; in GRPDEF record
@IWF_GRPDIF  equ (mask $IWF_GRPDIF)	; Differing group owners
					; between GRPDEF records
@IWF_SEGBIG  equ (mask $IWF_SEGBIG)	; Segment exceeds 64KB
@IWF_GRPBIG  equ (mask $IWF_GRPBIG)	; Group   ...
@IWF_GRPMIX  equ (mask $IWF_GRPMIX)	; Group mixes abs and rel segments
@IWF_FIXOVF  equ (mask $IWF_FIXOVF)	; Fixup overflow
@IWF_ABSOVF  equ (mask $IWF_ABSOVF)	; Absolute fixup overflow
@IWF_ABSDIF  equ (mask $IWF_ABSDIF)	; Group mixes abs segs with differing bases
@IWF_TYPDIF  equ (mask $IWF_TYPDIF)	; Type indices differ between
					; references to a symbol


IW2_REC  record  \
		 $IW2_EXTMAT :2=@IWF_IGN, \
		 $IW2_SEGEXT :2=@IWF_FAL, \
		 $IW2_SEGEXT0:2=@IWF_FAL, \
		 $IW2_GRPEXT :2=@IWF_FAL, \
		 $IW2_GRPEXT0:2=@IWF_FAL, \
		 $IW2_RELSEG :2=@IWF_FAL, \
		 $IW2_RELGRP :2=@IWF_FAL, \
		 $IW2_RELSEGX:2=@IWF_FAL, \
		 $IW2_RELGRPX:2=@IWF_FAL, \
		 $IW2_PUBDIF :2=@IWF_FAL, \
		 $IW2_LINDIF :2=@IWF_FAL, \
		 $IW2_FIXDIF :2=@IWF_FAL, \
		 $IW2_FIXDIFX:2=@IWF_FAL, \
		 $IW2_FRMSEG :2=@IWF_FAL, \
		 $IW2_THRINV :2=@IWF_IGN, \
		 $IW2_BAKPAT :2=@IWF_FAL

@IW2_EXTMAT  equ (mask $IW2_EXTMAT)	; Check on all EXTDEFs matched
@IW2_SEGEXT  equ (mask $IW2_SEGEXT)	; Fixup error of external target in
					; frame segment
@IW2_SEGEXT0 equ (mask $IW2_SEGEXT0)	; Fixup error of external target in
					; frame segment w/no segment for target
@IW2_GRPEXT  equ (mask $IW2_GRPEXT)	; Fixup error of external target in
					; frame group
@IW2_GRPEXT0 equ (mask $IW2_GRPEXT0)	; Fixup error of external target in
					; frame group w/no group for target
@IW2_RELSEG  equ (mask $IW2_RELSEG)	; Self-relative fixup error of fixup
					; segment not same as frame segment
@IW2_RELGRP  equ (mask $IW2_RELGRP)	; Self-relative fixup error of fixup
					; segment not in frame group
@IW2_RELSEGX equ (mask $IW2_RELSEGX)	; Self-relative fixup error of fixup
					; segment not same as external frame segment
@IW2_RELGRPX equ (mask $IW2_RELGRPX)	; Self-relative fixup error of fixup
					; segment not in external frame group
@IW2_PUBDIF  equ (mask $IW2_PUBDIF)	; PUBDEF segment not contained in group
@IW2_LINDIF  equ (mask $IW2_LINDIF)	; LINNUM ...
@IW2_FIXDIF  equ (mask $IW2_FIXDIF)	; In a FIXUPP record, a segment is not
					; contained in the referenced group
@IW2_FIXDIFX equ (mask $IW2_FIXDIFX)	; In a FIXUPP record, a segment is not
					; contained in any group, but there's
					; a Target group
@IW2_FRMSEG  equ (mask $IW2_FRMSEG)	; Frame segment fixup should be group
@IW2_THRINV  equ (mask $IW2_THRINV)	; Thread # invalid
@IW2_BAKPAT  equ (mask $IW2_BAKPAT)	; Invalid location type field in BAKPAT


IW3_REC  record  \
		 $IW3_FRMSEG0:2=@IWF_IGN, \
		 $IW3_BLKDEF :2=@IWF_IGN, \
		 $IW3_BLKEND :2=@IWF_IGN, \
		 $IW3_TYPDEF :2=@IWF_IGN

@IW3_FRMSEG0 equ (mask $IW3_FRMSEG0)	; Frame segment fixup should be group,
					;   but segment is first in group
@IW3_BLKDEF  equ (mask $IW3_BLKDEF)	; Block definition record
@IW3_BLKEND  equ (mask $IW3_BLKEND)	; Block end record
@IW3_TYPDEF  equ (mask $IW3_TYPDEF)	; Type definition record



; Remember to create a function for each new entry with IWF_FCNMAC
; and a command line entry with LINARG_MAC, both in QLNK_FCN.ASM.

