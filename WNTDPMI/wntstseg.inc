;'$Header$

; Segment definitions for WNTDPMI.EXE

; WNTSEG.INC

; Define segments and groups

;;;;PGROUP  group   LDATA,CODE,CODE16,CODE32,NDATA,NCODE,STACK
PGROUP	group	LDATA,CODE,CODE16,NDATA,NCODE,STACK
DGROUP	group	DATA


DATA	segment use16 para public 'data' ; Start DATA segment
DATA	ends			; End DATA segment


CODE	segment use16 byte public 'code' ; Start CODE segment
CODE	ends			; End CODE segment


LDATA	segment use16 dword public 'prog' ; Start LDATA segment
LDATA	ends			; End LDATA segment


CODE16	segment use16 byte public 'prog' ; Start CODE16 segment
CODE16	ends			; End CODE16 segment


;;;; CODE32  segment use32 byte public 'prog' ; Start CODE32 segment
;;;; CODE32  ends		     ; End CODE32 segment


NDATA	segment use16 dword public 'ndata' ; Start NDATA segment
NDATA	ends			; End NDATA segment


NCODE	segment use16 byte public 'ndata' ; Start NCODE segment
NCODE	ends			; End NCODE segment


STACK	segment use16 dword stack 'ndata' ; Start STACK segment
STACK	ends			; End STACK segment


