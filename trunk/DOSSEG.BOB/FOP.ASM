SEG1	segment para
	assume	cs:SEG1

	dw	4040h
FUD:
	dw	9090h
	db	90h

SEG1	ends

SEG2	segment byte
	assume	cs:SEG2

	jmp	near ptr SEG1:FUD

SEG2	ends

	end
