; CMTOGGLE.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc

    .code

cmatoggle proc
    panel_toggle(panela)
    ret
cmatoggle endp

cmbtoggle proc
    panel_toggle(panelb)
    ret
cmbtoggle endp

cmtoggleon proc uses rsi rdi

    mov esi,panel_state(panela)
    mov edi,panel_state(panelb)
    .if !edi && esi
        cmatoggle()
    .elseif edi && !esi
        cmbtoggle()
    .elseif edi
        mov rsi,cpanel
        mov rdi,panela
        .if rsi == rdi
            mov rdi,panelb
        .endif
        panel_hide(rsi)
        panel_hide(rdi)
    .else
        comhide()
        mov rsi,cpanel
        mov rdi,panela
        .if rsi == rdi
            mov rdi,panelb
        .endif
        panel_show(rdi)
        panel_show(rsi)
        panel_setactive(rsi)
    .endif
    xor eax,eax
    ret
cmtoggleon endp

cmtogglehz proc
    mov eax,config.c_panelsize
    mov ecx,cflag
    .if ecx & _C_WIDEVIEW && ecx & _C_HORIZONTAL
        and ecx,not _C_WIDEVIEW
        shl al,1
    .elseif ecx & _C_HORIZONTAL
        and ecx,not _C_HORIZONTAL
        shl al,1
    .else
        or  ecx,_C_WIDEVIEW or _C_HORIZONTAL
    .endif
    mov cflag,ecx
    mov config.c_panelsize,eax
    redraw_panels()
    ret
cmtogglehz endp

cmtogglesz proc
    xor eax,eax
    .if eax == config.c_panelsize
        mov eax,_scrrow
        shr eax,1
        dec eax
    .endif
    mov config.c_panelsize,eax
    redraw_panels()
    ret
cmtogglesz endp

cmxorcmdline proc
    xor cflag,_C_COMMANDLINE
    apiupdate()
    ret
cmxorcmdline endp

cmxorkeybar proc
    xor cflag,_C_STATUSLINE
    apiupdate()
    ret
cmxorkeybar endp

cmxormenubar proc
    xor cflag,_C_MENUSLINE
    apiupdate()
    ret
cmxormenubar endp

    END
