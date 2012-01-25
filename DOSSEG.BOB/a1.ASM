CODE	segment byte public 'code'
	assume	cs:CODE

	extrn	FOW:near

	call	FOW

CODE	ends

	end
