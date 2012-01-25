.386

	 include QLNK_SEG.INC

NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:NGROUP

	 extrn	 QLINK:near

NCODE	 ends			; End NCODE segment

	 end
