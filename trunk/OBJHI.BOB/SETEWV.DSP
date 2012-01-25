DISPOBJ   -- Version 1.74 -- An Object Module Displayer
   (C) Copyright 1985-2000 Qualitas, Inc.  All rights reserved.
ðð Object module listing of RET\SETEWV.OBJ (694 bytes) ðð
THEADR:  Type 80, Offset 0000
         Name SETEWV.ASM
LNAMES:  Type 96, Offset 000F
            1: Name 
            2: Name DGROUP
            3: Name DATA
            4: Name CODE
            5: Name _DATA
            6: Name _TEXT
SEGDEF:  Type 98, Offset 0031
         Reloc word-aligned, combine type public, length 0018
         Segment name _DATA, class DATA
SEGDEF:  Type 98, Offset 003B
         Reloc word-aligned, combine type public, length 0112
         Segment name _TEXT, class CODE
GRPDEF:  Type 9A, Offset 0045
         Group DGROUP is Seg _DATA
EXTDEF:  Type 8C, Offset 004C
            1: Name GETCURRENTTASK
PUBDEF:  Type 90, Offset 0060
         Segment _TEXT
         Name WINMAIN, offset 0000
         Name BASE2BIN, offset 00A6
PUBDEF:  Type 90, Offset 007D
         Group DGROUP, Segment _DATA
         Name PMODNAME, offset 0000
PUBDEF:  Type 90, Offset 008F
         Segment _TEXT
         Name STRCMPNI, offset 00DD
PUBDEF:  Type 90, Offset 00A1
         Group DGROUP, Segment _DATA
         Name WVERSION, offset 0004
PUBDEF:  Type 90, Offset 00B3
         Segment _TEXT
         Name SKIPBLACK, offset 008B
         Name LOWERCASE, offset 009F
         Name SKIPWHITE, offset 007B
PUBDEF:  Type 90, Offset 00E0
         Group DGROUP, Segment _DATA
         Name CON16, offset 0006
         Name NUMBERS_LO, offset 0008
COMENT:  Type 88, Offset 00FD
         Comment type A2 ==> Linker pass 2 marker
LEDATA:  Type A0, Offset 0104
         Segment _DATA, offset 0000, length 0018
    0000:00 00 00 00 00 00 10 00-30 31 32 33 34 35 36 37 ð ........01234567
    0010:38 39 61 62 63 64 65 66-                        ð 89abcdef
LEDATA:  Type A0, Offset 0123
         Segment _TEXT, offset 0000, length 0112
    0000:55 8B EC 66 83 7E 06 00-74 69 C4 7E 06 E8 00 00 ð U.ìf.~..tiÄ~.è..
    0010:26 80 3D 00 74 5D 89 3E-00 00 8C 06 00 00 E8 00 ð &.=.t].>......è.
    0020:00 26 80 3D 00 74 4C 26-C6 05 00 47 E8 00 00 26 ð .&.=.tL&Æ..Gè..&
    0030:80 3D 00 74 3E B9 10 00-E8 00 00 A3 00 00 3D 00 ð .=.t>¹..è..£..=.
    0040:03 72 30 9A 00 00 00 00-23 D2 74 27 66 FF 36 00 ð .r0.....#Òt'fÿ6.
    0050:00 52 68 F2 00 6A 08 E8-00 00 74 09 8E C2 26 8B ð .Rhò.j.è..t..Â&.
    0060:16 00 00 EB E3 8E C2 26-8E 06 1E 00 A1 00 00 26 ð ...ëã.Â&....¡..&
    0070:A3 3E 00 33 C0 8B E5 5D-C2 0A 00 50 26 8A 05 47 ð £>.3À.å]Â..P&..G
    0080:3C 20 74 F8 3C 09 74 F4-4F 58 C3 50 26 8A 05 47 ð < tø<.tôOXÃP&..G
    0090:3C 00 74 08 3C 20 74 04-3C 09 75 F0 4F 58 C3 3C ð <.t.< t.<.uðOXÃ<
    00A0:40 72 02 0C 20 C3 53 52-56 E8 00 00 26 8A 05 33 ð @r.. ÃSRVè..&..3
    00B0:DB E8 00 00 51 33 F6 3A-84 00 00 74 03 46 E2 F7 ð Ûè..Q3ö:...t.Fâ÷
    00C0:59 75 12 8B C3 F7 E1 72-10 8B D8 03 DE 72 0A 26 ð Yu..Ã÷ár..Ø.Þr.&
    00D0:8A 05 47 EB DC 4F 8B C3-F8 5E 5A 5B C3 55 8B EC ð ..GëÜO.Ãø^Z[ÃU.ì
    00E0:50 51 56 57 1E 06 C5 76-06 C4 7E 0A 8B 4E 04 3A ð PQVW..Åv.Ä~..N.:
    00F0:C0 F3 A6 74 13 8A 44 FF-E8 00 00 26 8A 65 FF 86 ð Àó¦t..Dÿè..&.eÿ.
    0100:C4 E8 00 00 3A C4 74 E7-07 1F 5F 5E 59 58 5D C2 ð Äè..:Ätç.._^YX]Â
    0110:0A 00                                           ð ..
FIXUPP:  Type 9C, Offset 023C
         Self-relative word offset location 00E (00E), Frame segment _TEXT,
           Target segment _TEXT, offset 007B
         Segment-relative word offset location 018 (018), Frame group DGROUP,
           Target segment _DATA
         Segment-relative word offset location 01C (01C), Frame group DGROUP,
           Target segment _DATA, offset 0002
         Self-relative word offset location 01F (01F), Frame segment _TEXT,
           Target segment _TEXT, offset 008B
         Self-relative word offset location 02D (02D), Frame segment _TEXT,
           Target segment _TEXT, offset 007B
         Self-relative word offset location 039 (039), Frame segment _TEXT,
           Target segment _TEXT, offset 00A6
         Segment-relative word offset location 03C (03C), Frame group DGROUP,
           Target segment _DATA, offset 0004
         Segment-relative ptr16:16 location 044 (044), 
         Frame external GETCURRENTTASK,
           Target external GETCURRENTTASK
         Segment-relative word offset location 04F (04F), Frame group DGROUP,
           Target segment _DATA
         Self-relative word offset location 058 (058), Frame segment _TEXT,
           Target segment _TEXT, offset 00DD
         Segment-relative word offset location 06D (06D), Frame group DGROUP,
           Target segment _DATA, offset 0004
         Self-relative word offset location 0AA (0AA), Frame segment _TEXT,
           Target segment _TEXT, offset 007B
         Self-relative word offset location 0B2 (0B2), Frame segment _TEXT,
           Target segment _TEXT, offset 009F
         Segment-relative word offset location 0B9 (0B9), Frame group DGROUP,
           Target segment _DATA, offset 0008
         Self-relative word offset location 0F9 (0F9), Frame segment _TEXT,
           Target segment _TEXT, offset 009F
         Self-relative word offset location 102 (102), Frame segment _TEXT,
           Target segment _TEXT, offset 009F
MODE32:  Type 8B, Offset 02AA
         Main module, start address is Frame segment _TEXT,
           Target segment _TEXT, offset 00000000
