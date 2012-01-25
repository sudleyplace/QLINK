;MODULE1
.386p
nosmart

group perty code3

code3 segment word public use32 'blah'
 db 2000 dup (6)
 shocker label DWORD
code3 ends

assume cs:_code
_code segment para private use16 'code'
main:

lea bx,perty:[SMALL shocker]
;lea cx,perty:[LARGE shocker]

_code ends
end main
