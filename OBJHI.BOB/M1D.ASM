;MODULE1
.386p

perty group code3

;;code3 segment word public use32 'blah'
code3 segment word use32 'blah'
 db 2000 dup (6)
public shocker
 shocker label DWORD
code3 ends

assume cs:_code
_code segment para use16 'code'
main:

lea bx,perty:[shocker]
;lea cx,perty:[LARGE shocker]

_code ends
end main
