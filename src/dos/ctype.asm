; _CTYPE.ASM--
; Copyright (C) 2015 Doszip Developers

include libc.inc
include ctype.inc

PUBLIC	__ctype

	.data

__ctype label BYTE
	db	0			; -1
	db	_CONTROL		; 00 (NUL)
	db	_CONTROL		; 01 (SOH)
	db	_CONTROL		; 02 (STX)
	db	_CONTROL		; 03 (ETX)
	db	_CONTROL		; 04 (EOT)
	db	_CONTROL		; 05 (ENQ)
	db	_CONTROL		; 06 (ACK)
	db	_CONTROL		; 07 (BEL)
	db	_CONTROL		; 08 (BS)
	db	_SPACE + _CONTROL	; 09 (HT)
	db	_SPACE + _CONTROL	; 0A (LF)
	db	_SPACE + _CONTROL	; 0B (VT)
	db	_SPACE + _CONTROL	; 0C (FF)
	db	_SPACE + _CONTROL	; 0D (CR)
	db	_CONTROL		; 0E (SI)
	db	_CONTROL		; 0F (SO)
	db	_CONTROL		; 10 (DLE)
	db	_CONTROL		; 11 (DC1)
	db	_CONTROL		; 12 (DC2)
	db	_CONTROL		; 13 (DC3)
	db	_CONTROL		; 14 (DC4)
	db	_CONTROL		; 15 (NAK)
	db	_CONTROL		; 16 (SYN)
	db	_CONTROL		; 17 (ETB)
	db	_CONTROL		; 18 (CAN)
	db	_CONTROL		; 19 (EM)
	db	_CONTROL		; 1A (SUB)
	db	_CONTROL		; 1B (ESC)
	db	_CONTROL		; 1C (FS)
	db	_CONTROL		; 1D (GS)
	db	_CONTROL		; 1E (RS)
	db	_CONTROL		; 1F (US)
	db	_SPACE + _BLANK		; 20 SPACE
	db	_PUNCT			; 21 !
	db	_PUNCT			; 22 "
	db	_PUNCT			; 23 #
	db	_PUNCT			; 24 $
	db	_PUNCT			; 25 %
	db	_PUNCT			; 26 &
	db	_PUNCT			; 27 '
	db	_PUNCT			; 28 (
	db	_PUNCT			; 29 )
	db	_PUNCT			; 2A *
	db	_PUNCT			; 2B +
	db	_PUNCT			; 2C ,
	db	_PUNCT			; 2D -
	db	_PUNCT			; 2E .
	db	_PUNCT			; 2F /
	db	_DIGIT + _HEX		; 30 0
	db	_DIGIT + _HEX		; 31 1
	db	_DIGIT + _HEX		; 32 2
	db	_DIGIT + _HEX		; 33 3
	db	_DIGIT + _HEX		; 34 4
	db	_DIGIT + _HEX		; 35 5
	db	_DIGIT + _HEX		; 36 6
	db	_DIGIT + _HEX		; 37 7
	db	_DIGIT + _HEX		; 38 8
	db	_DIGIT + _HEX		; 39 9
	db	_PUNCT			; 3A :
	db	_PUNCT			; 3B ;
	db	_PUNCT			; 3C <
	db	_PUNCT			; 3D =
	db	_PUNCT			; 3E >
	db	_PUNCT			; 3F ?
	db	_PUNCT			; 40 @
	db	_UPPER + _HEX		; 41 A
	db	_UPPER + _HEX		; 42 B
	db	_UPPER + _HEX		; 43 C
	db	_UPPER + _HEX		; 44 D
	db	_UPPER + _HEX		; 45 E
	db	_UPPER + _HEX		; 46 F
	db	_UPPER			; 47 G
	db	_UPPER			; 48 H
	db	_UPPER			; 49 I
	db	_UPPER			; 4A J
	db	_UPPER			; 4B K
	db	_UPPER			; 4C L
	db	_UPPER			; 4D M
	db	_UPPER			; 4E N
	db	_UPPER			; 4F O
	db	_UPPER			; 50 P
	db	_UPPER			; 51 Q
	db	_UPPER			; 52 R
	db	_UPPER			; 53 S
	db	_UPPER			; 54 T
	db	_UPPER			; 55 U
	db	_UPPER			; 56 V
	db	_UPPER			; 57 W
	db	_UPPER			; 58 X
	db	_UPPER			; 59 Y
	db	_UPPER			; 5A Z
	db	_PUNCT			; 5B [
	db	_PUNCT			; 5C \
	db	_PUNCT			; 5D ]
	db	_PUNCT			; 5E ^
	db	_PUNCT			; 5F _
	db	_PUNCT			; 60 `
	db	_LOWER + _HEX		; 61 a
	db	_LOWER + _HEX		; 62 b
	db	_LOWER + _HEX		; 63 c
	db	_LOWER + _HEX		; 64 d
	db	_LOWER + _HEX		; 65 e
	db	_LOWER + _HEX		; 66 f
	db	_LOWER			; 67 g
	db	_LOWER			; 68 h
	db	_LOWER			; 69 i
	db	_LOWER			; 6A j
	db	_LOWER			; 6B k
	db	_LOWER			; 6C l
	db	_LOWER			; 6D m
	db	_LOWER			; 6E n
	db	_LOWER			; 6F o
	db	_LOWER			; 70 p
	db	_LOWER			; 71 q
	db	_LOWER			; 72 r
	db	_LOWER			; 73 s
	db	_LOWER			; 74 t
	db	_LOWER			; 75 u
	db	_LOWER			; 76 v
	db	_LOWER			; 77 w
	db	_LOWER			; 78 x
	db	_LOWER			; 79 y
	db	_LOWER			; 7A z
	db	_PUNCT			; 7B {
	db	_PUNCT			; 7C |
	db	_PUNCT			; 7D }
	db	_PUNCT			; 7E ~
	db	_CONTROL		; 7F (DEL)

	; and the rest are 0...

	db	257 - ($ - offset __ctype) dup(?)

	.code

getctype PROC PUBLIC USES bx
	sub	bx,bx
	mov	bl,al
	mov	ah,ss:[bx+__ctype+1]
	test	al,al
	ret
getctype ENDP

islabel PROC PUBLIC USES ax
	call	getctype
	test	ah,_UPPER or _LOWER or _DIGIT
	jnz	islabel_end
	cmp	al,'_'
	je	islabel_ok
    islabel_no:
	xor	al,al
	jmp	islabel_end
    islabel_ok:
	test	al,al
    islabel_end:
	ret
islabel ENDP

isspace PROC PUBLIC USES ax
	call	getctype
	test	ah,_SPACE
	ret
isspace ENDP

isupper PROC PUBLIC USES ax
	call	getctype
	test	ah,_UPPER
	ret
isupper ENDP

ftolower PROC _CType PUBLIC
	cmp	al,'Z'
	ja	@F
	cmp	al,'A'
	jb	@F
	add	al,'a' - 'A'
      @@:
	ret
ftolower ENDP

	END

