;' $Header$
;
; (C) Copyright 2000 Qualitas, Inc.  All rights reserved.
;
; QLNK_DMP.INC
;
; Dump flags
;

DMP_REC record \
$DMP_FIXUPP:1, \
$DMP_IMPDEF:1, \
$DMP_PUBDEF:1, \
$DMP_PERMOD:1, \
$DMP_PERLSEG:1,\
$DMP_PERCLS:1, \
$DMP_PERGRP:1, \
$DMP_PERSEG:1, \
$DMP_PEROBJ:1

@DMP_FIXUPP  equ (mask $DMP_FIXUPP)	; 00000100:  Dump FIXUPP_STRs
@DMP_IMPDEF  equ (mask $DMP_IMPDEF)	; 00000080:  Dump IMPDEF_STRs
@DMP_PUBDEF  equ (mask $DMP_PUBDEF)	; 00000040:  Dump PUBDEF_STRs
@DMP_PERMOD  equ (mask $DMP_PERMOD)	; 00000020:  Dump PERMOD_STRs
@DMP_PERLSEG equ (mask $DMP_PERLSEG)	; 00000010:  Dump PERLSEG_STRs
@DMP_PERCLS  equ (mask $DMP_PERCLS)	; 00000008:  Dump PERCLS_STRs
@DMP_PERGRP  equ (mask $DMP_PERGRP)	; 00000004:  Dump PERGRP_STRs
@DMP_PERSEG  equ (mask $DMP_PERSEG)	; 00000002:  Dump PERSEG_STRs
@DMP_PEROBJ  equ (mask $DMP_PEROBJ)	; 00000001:  Dump PEROBJ_STRs

@DMP_ALL equ	\
@DMP_FIXUPP or	\
@DMP_IMPDEF or	\
@DMP_PUBDEF or	\
@DMP_PERMOD or	\
@DMP_PERLSEG or \
@DMP_PERCLS or	\
@DMP_PERGRP or	\
@DMP_PERSEG or	\
@DMP_PEROBJ

