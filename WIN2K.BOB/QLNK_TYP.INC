;' $Header:   P:/PVCS/MISC/QLINK/QLNK_TYP.INV   1.1   17 Jul 1997 12:36:54   BOB  $
;
; (C) Copyright 1994-2000 Qualitas, Inc.  All rights reserved.
;
; QLNK_TYP.INC
;
; OMF types
; * = ignored
; + = has 32-bit definition

@OMF1ST equ	06Eh		; The first valid OMF record

@OMF_RHEADR  equ 06Eh		; * R-module header record
@OMF_REGINT  equ 070h		; * Register initialization record
@OMF_REDATA  equ 072h		; * Relocatable enumerated data record
@OMF_RIDATA  equ 074h		; * Relocatable iterated data record
@OMF_OVLDEF  equ 076h		; * Overlay definition record
@OMF_ENDREC  equ 078h		; * End record
@OMF_BLKDEF  equ 07Ah		; * Block definition record
@OMF_BLKEND  equ 07Ch		; * Block end record
@OMF_DEBSYM  equ 07Eh		; * Debug symbols record
@OMF_THEADR  equ 080h		;   Translator header record
@OMF_LHEADR  equ 082h		;   Library module header record
@OMF_PEDATA  equ 084h		; * Physical enumerated data record
@OMF_PIDATA  equ 086h		; * Physical iterated data record
@OMF_COMENT  equ 088h		;   Comment record
@OMF_MODEND  equ 08Ah		; + Module end record
@OMF_EXTDEF  equ 08Ch		;   External names definition record
@OMF_TYPDEF  equ 08Eh		;   Type definition record
@OMF_PUBDEF  equ 090h		; + Public names definition record
@OMF_LOCSYM  equ 092h		; * Local symbols record
@OMF_LINNUM  equ 094h		; + Line numbers record
@OMF_LNAMES  equ 096h		;   List of names record
@OMF_SEGDEF  equ 098h		; + Segment definition record
@OMF_GRPDEF  equ 09Ah		;   Group definition record
@OMF_FIXUPP  equ 09Ch		; + Fixup record
@OMF_IGNORE  equ 09Eh		; * Undefined record
@OMF_LEDATA  equ 0A0h		; + Logical enumerated data record
@OMF_LIDATA  equ 0A2h		; + Logical iterated data record
@OMF_LIBHED  equ 0A4h		; * Library header record
@OMF_LIBNAM  equ 0A6h		; * Library module names record
@OMF_LIBLOC  equ 0A8h		; * Library module locations record
@OMF_LIBDIC  equ 0AAh		; * Library dictionary record
;;;		 0ACh		; * (unknown)
;;;		 0AEh		; * (unknown)
@OMF_COMDEF  equ 0B0h		;   Communal names definition record
@OMF_BAKPAT  equ 0B2h		; + Backpatch record
@OMF_LEXTDEF equ 0B4h		; + Local external names definition record
@OMF_LPUBDEF equ 0B6h		; + Local public names definition record
@OMF_LCOMDEF equ 0B8h		;   Local communal names definition record
@OMF_COMFIX  equ 0BAh		; + Communal fixup record
@OMF_CEXTDEF equ 0BCh		;   COMDAT external names definition record
;;;		 0BEh		; * (unknown)
@OMF_SELDEF  equ 0C0h		;   Selector definition record (never implemented)
@OMF_COMDAT  equ 0C2h		; + Initialized communal data record
@OMF_LINSYM  equ 0C4h		; + Symbol line numbers record
@OMF_ALIAS   equ 0C6h		;   Alias definition record
@OMF_NBKPAT  equ 0C8h		; + Named backpatch record
@OMF_LLNAMES equ 0CAh		;   Local logical names definition record

@OMFLAST equ	0CAh		; The last valid OMF record


; The following two types occur in .LIB files, not .OBJ files

@OMF_LIBHDR  equ 0F0h		; Library header record
@OMF_LIBEND  equ 0F1h		; Library end record
@OMF_LIBEXT  equ 0F2h		; Library extended dictionary


; The following equates are for COMENT classes

@OMF_COMENT_TNAME    equ  00h	; Translator name
@OMF_COMENT_ICOPY    equ  01h	; Intel copyright
@OMF_COMENT_LIBSPEC  equ  81h	; Library specifier
@OMF_COMENT_MSDOSVER equ  9Ch	; MSDOS version #
@OMF_COMENT_MEMMODEL equ  9Dh	; Memory model marker
@OMF_COMENT_DOSSEG   equ  9Eh	; DOSSEG switch
@OMF_COMENT_DEFLIB   equ  9Fh	; Default library search filename
@OMF_COMENT_OMFEXT   equ 0A0h	; OMF extensions
@OMF_COMENT_NOMFEXT  equ 0A1h	; New OMF extensions
@OMF_COMENT_LINKPASS equ 0A2h	; LINK pass marker
@OMF_COMENT_LIBMOD   equ 0A3h	; LIBMOD comment
@OMF_COMENT_EXESTR   equ 0A4h	; EXESTR
@OMF_COMENT_INCERR   equ 0A6h	; Incremental compilation error
@OMF_COMENT_NOPAD    equ 0A7h	; No segment padding
@OMF_COMENT_WEAKEXT  equ 0A8h	; Weak extrns
@OMF_COMENT_LZEXT    equ 0A9h	; Lazy extrns
@OMF_COMENT_COMMENT  equ 0DAh	; Actual comment
@OMF_COMENT_PRGCOMP  equ 0DBh	; Pragma comment(compiler); version #
@OMF_COMENT_PRGDATE  equ 0DCh	; Pragma comment(date string)
@OMF_COMENT_PRGTIME  equ 0DDh	; Pragma comment(timestamp)
@OMF_COMENT_PRGUSER  equ 0DFh	; Pragma comment(user)
@OMF_COMENT_BORDEP   equ 0E9h	; Borland dependency file


; The following equates are subtypes for COMENT class OMF extensions

@OMF_COMENT_OMF_IMPDEF equ 01h	; IMPDEF record
@OMF_COMENT_OMF_EXPDEF equ 02h	; EXPDEF record
@OMF_COMENT_OMF_INCOMP equ 03h	; Incremental compilation record
@OMF_COMENT_OMF_CPP    equ 05h	; C++ directives record

