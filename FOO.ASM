
CODE	segment
	assume	cs:CODE,ds:CODE

	dw	?
	db	10000 dup (?)
	dw	?

CODE	ends

	end
