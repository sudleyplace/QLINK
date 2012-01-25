
DGROUP	group	DATA1
FLAT	group	DATA2

DATA	segment '___code'
DATA	ends

DATA1	segment 'begdata'
DATA1	ends

DATA2	segment 'bss'
DATA2	ends

DATA3	segment 'stack'
DATA3	ends

_TEXT	segment
_TEXT	ends

	end
