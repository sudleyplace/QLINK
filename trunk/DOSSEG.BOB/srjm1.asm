
segment seg1 align=16
 dw 4040h
 fud:
 dw 9090h
 db 90h

segment seg2 align=1
 jmp fud WRT seg1

