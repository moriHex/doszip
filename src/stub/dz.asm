; DZ.ASM--
; Copyright (C) 2022 Doszip Developers -- see LICENSE.TXT

.186
.model small

S_DZDS		STRUC
dz_envlen	dw ?
dz_envseg	dw ?
dz_command	dw 2 dup(?)
dz_fcb_0P	dw 2 dup(?)
dz_fcb_1P	dw 2 dup(?)
dz_dzmain	db 80 dup(?)
dz_dzcommand	db 128 dup(?)
dz_fcb_160	db 16 dup(?)
dz_fcb_161	db 16 dup(?)
dz_exeproc	db 80 dup(?)
dz_execommand	db 128 dup(?)
dz_errno	dw ?
dz_eflag	dw ?
dz_count	dw ?
dz_exename	dw ?
dz_oldintF1	dd ?
S_DZDS		ENDS	; 474 byte

PROGRAMSIZE equ 1024

VesionString macro
%	exitm<@CatStr(%VERSION/100+'0',<,>,'.',<,>,((%VERSION mod 100)/10)+'0',<,>, (%VERSION mod 10)+'0')>
	endm

	.code

exec	label S_DZDS
start	PROC
	jmp	around
	db	10
copy	db	'The Doszip Commander Version ',VesionString(),', '
	db	'Copyright (c) 1997-2022 Doszip Developers',13,10,13,10,'$'
errenv	db	'Environment invalid',13,10,'$'
around:
	mov	ax,cs
	mov	ds,ax
	ASSUME	DS:_TEXT
	mov	ah,9
	mov	dx,offset copy
	int	21h
	mov	si,offset exec
	mov	bx,002Ch
	mov	bp,es
	mov	ax,es:[bx]
	mov	exec.dz_envseg,ax
	mov	ax,3306h	; DOS 5+
	int	21h
	cmp	bl,7
	mov	bx,PROGRAMSIZE/16
	jne	@F
	add	bx,bx
     @@:
	mov	ah,4Ah
	int	21h
	mov	cl,4
	shl	bx,cl
	sub	bx,256
	mov	ax,cs
	mov	ss,ax
	mov	sp,bx
	mov	bx,exec.dz_envseg
	mov	es,bx
	xor	ax,ax
	mov	di,ax
	mov	cx,7FFFh
	cld
     @@:
	repnz	scasb
	test	cx,cx
	jz	errorlevel_10
	cmp	es:[di],al
	jne	@B
	or	ch,80h
	neg	cx
	jmp	init_vector
errorlevel_10:
	mov	dx,offset errenv
	mov	ah,9
	int	21h
	mov	ax,4C0Ah
	int	21h
init_vector:
	mov	ax,ds
	mov	vector+6,ax
	mov	vector+4,offset exec.dz_exeproc
	mov	exec.dz_fcb_0P[2],ax
	mov	exec.dz_fcb_1P[2],ax
	mov	exec.dz_fcb_0P,offset exec.dz_fcb_160
	mov	exec.dz_fcb_1P,offset exec.dz_fcb_161
	mov	exec.dz_command[2],ax
	mov	dx,ax
	mov	di,cx
	add	di,2
	mov	si,di
	mov	cx,-1
	xor	ax,ax
	repnz	scasb
	not	cx
	mov	es,dx
	mov	di,offset exec.dz_dzmain
	mov	ds,bx
	rep	movsb
	mov	ds,dx
	mov	bx,di ; rename dx.exe to dz.dos
	mov	di,offset exec.dz_fcb_160
	mov	si,offset exec.dz_dzmain
	mov	ax,2901h
	int	21h
ifdef DOSEMU
	mov	al,'\' ; if the name is not dz.exe
	cmp	al,[bx-8]
	je	emu_done
	lea	di,[bx-8]
     @@:
	cmp	di,si
	jbe	emu_done
	dec	di
	cmp	al,[di]
	jne	@B
	lea	bx,[di+8]
	mov	word ptr [bx-7],'ZD'
	mov	byte ptr [bx-5],'.'
emu_done:
endif
	mov	word ptr [bx-4],'OD'
	mov	word ptr [bx-2],'S'
	mov	cx,128
	mov	di,offset exec.dz_dzcommand
	mov	si,cx
	mov	ds,bp
	rep	movsb
	mov	ds,dx
	mov	ax,4300h
	mov	dx,offset exec.dz_dzmain
	int	21h
	jnc	file_found
file_not_found:
	mov	di,bx
	mov	dx,offset cp_file_not_found
	mov	cx,15
	call	write
	mov	dx,offset exec.dz_dzmain
	mov	cx,di
	sub	cx,dx
	call	write
	mov	ax,2
	jmp	exit
write:	mov	ah,40h
	mov	bx,2
	int	21h
	ret
	db	13,10
%	db	'$Id: DZ.ASM &@Date',10
file_found:
	xor	ax,ax
	mov	vector+8,ax
	jmp	doszip
	db	13,10
	db	'DOS (errorlevel):',10
	db	' 2 '
cp_file_not_found label byte
	db	'File not found DZ.DOS',13,10
	db	' 5 Access',10
	db	' 8 Memory',10
	db	'10 Environment'
	org	S_DZDS - 14
	dw	0
	dw	0	; dz_errno
	dw	0	; dz_eflag
	dw	0	; dz_count
	dw	0A00h	; dz_exename
	dw	4F44h	; dz_oldintF1
	dw	3A53h
START	ENDP

doszip:
	mov	ax,35F1h
	int	21h
	mov	word ptr exec.dz_oldintF1,bx
	mov	word ptr exec.dz_oldintF1[2],es
	mov	ax,25F1h
	mov	dx,offset vector
	int	21h
	mov	exec.dz_exename,offset exec.dz_dzmain
	mov	exec.dz_command,offset exec.dz_dzcommand
execute:
	mov	ax,cs
	mov	es,ax
	mov	ds,ax
	mov	di,offset exec.dz_fcb_161
	mov	si,exec.dz_exename
	mov	ax,2901h
	int	21h
	mov	bx,offset exec.dz_envseg
	mov	dx,exec.dz_exename
	mov	ax,4B00h
	int	21h
	mov	dx,cs
	mov	ds,dx
	jc	execute_error
	xor	ax,ax
    execute_error:
	mov	si,ax
	mov	ax,4D00h
	int	21h
	mov	exec.dz_eflag,si
	mov	exec.dz_errno,ax
	cmp	exec.dz_exename,offset exec.dz_dzmain
	jne	doszip
	mov	di,ax
	mov	si,offset exec
	mov	ax,25F1h
	lds	dx,exec.dz_oldintF1
	int	21h
	mov	ax,cs
	mov	ds,ax
	mov	ax,di
	cmp	al,23
	jne	exit
	inc	exec.dz_count
	mov	exec.dz_exename,offset exec.dz_exeproc
	mov	exec.dz_command,offset exec.dz_execommand
	jmp	execute
exit:
	mov	ah,4Ch
	int	21h

vector	label word
	dd	495A440Ah
	dd	564A4A50h
	db	VesionString()
	.stack	64
	end	start
