;' $Header:   P:/PVCS/MISC/QLINK/QLNK_SEG.INV   1.1   17 Jul 1997 12:36:52   BOB  $
;
; (C) Copyright 1994-2000 Qualitas, Inc.  All rights reserved.
;
; QLNK_SEG.INC
;
; All segments in QLINK in order of appearance
;


PGROUP	group	RCODE,CODE,CODEZ
DGROUP	group	DATA,TEXT,DTAB
NGROUP	group	NCODE,NDATA,NTEXT,NSEGMIN,NSEGMAX,NSEGTAB,NSEGACT,NTAIL
SGROUP	group	STACK


RCODE	segment use16 byte public 'code' ; Start RCODE segment
RCODE	ends			; End RCODE segment


CODE	segment use32 byte public 'code' ; Start CODE segment
CODE	ends			; End CODE segment


CODEZ	segment use32 byte public 'code' ; Start CODEZ segment
CODEZ	ends			; End CODEZ segment


DATA	segment use32 dword public 'data' ; Start DATA segment
DATA	ends			; End DATA segment


TEXT	segment use32 byte public 'data' ; Start TEXT segment
TEXT	ends			; End TEXT segment


DTAB	segment use32 dword public 'data' ; Start DTAB segment
DTAB	ends			; End DTAB segment


STACK	segment use32 para stack 'stack' ; Start STACK segment
STACK	ends			; End STACK segment


NCODE	segment use16 byte public 'ncode' ; Start NCODE segment
NCODE	ends			; End NCODE segment


NDATA	segment use16 dword public 'ncode' ; Start NDATA segment
NDATA	ends			; End NDATA segment


NTEXT	segment use16 byte public 'ncode' ; Start NTEXT segment
NTEXT	ends			; End NTEXT segment


NSEGMIN segment use16 word public 'ncode' ; Start NSEGMIN segment
NSEGMIN ends			; End NSEGMIN segment


NSEGMAX segment use16 word public 'ncode' ; Start NSEGMAX segment
NSEGMAX ends			; End NSEGMAX segment


NSEGTAB segment use16 dword public 'ncode' ; Start NSEGTAB segment
NSEGTAB ends			; End NSEGTAB segment


NSEGACT segment use16 word public 'ncode' ; Start NSEGACT segment
NSEGACT ends			; End NSEGACT segment


NTAIL	segment use16 para public 'ncode' ; Start NTAIL segment
NTAIL	ends			; End NTAIL segment


