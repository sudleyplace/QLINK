PGROUP	group	SEG1,SEG2

SEG1	segment byte 'code'
	assume	cs:PGROUP

	call	far ptr cs:L1	   ; Yes
	call	far ptr cs:L2	   ; No

	public	L1
L1:
	retf

;;;;;;; db	5 dup (90h)	; For alignment

SEG1	ends


SEG2	segment byte 'code'
	assume	cs:PGROUP

	call	far ptr cs:L1	   ; No
	call	far ptr cs:L2	   ; No

	public	L2
L2:
	retf

;;;;;;; db	5 dup (90h)	; For alignment

SEG2	ends

	end
