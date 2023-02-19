; CMCOMPSUB.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include malloc.inc
include io.inc
include string.inc
include errno.inc
include time.inc
include cfini.inc
include stdlib.inc
include crtl.inc
include tview.inc

__xtol proto :LPSTR

ifdef __WIN95__
MAXHIT equ 100000
else
MAXHIT equ 500000
endif

externdef   IDD_DZCompareDirectories:dword
externdef   IDD_DZRecursiveCompare:dword
externdef   cp_emaxfb:byte
;externdef   cp_formatID:byte
;
; from cmsearch.asm
;
;externdef   ff_basedir:dword
;externdef   DLG_FindFile:dword

ff_close        proto
ff_close_dlg    proto
ff_rsevent      proto :dword, :dword
ff_getcurobj    proto
ff_getcurfile   proto
ff_putcelid     proto :dword
ff_searchpath   proto :dword
ff_event_xcell  proto
ff_event_edit   proto
ff_event_view   proto
ff_event_exit   proto
ff_event_filter proto
ff_deleteobj    proto
ff_update_cellid proto

ID_FILE     equ 13
ID_GOTO     equ 22

OF_MASK     equ 14*16
OF_SOURCE   equ 15*16
OF_TARGET   equ 16*16
OF_SUBD     equ 17*16
OF_EQUAL    equ 18*16
OF_DIFFER   equ 19*16
OF_FIND     equ 20*16
OF_FILT     equ 21*16
OF_SAVE     equ 22*16
OF_GOTO     equ 23*16
OF_QUIT     equ 24*16
OF_MSUP     equ 25*16
OF_MSDN     equ 26*16
OF_GCMD     equ OF_MSUP

    .data

GCMD_search dd KEY_F2,      event_mklist
            dd KEY_F3,      ff_event_view
            dd KEY_F4,      ff_event_edit
            dd KEY_F5,      ff_event_filter
            dd KEY_F6,      event_path
            dd KEY_F7,      event_find
            dd KEY_F8,      event_delete
            dd KEY_F9,      cmfilter_load
            dd KEY_F10,     event_advanced
            dd KEY_DEL,     event_delete
            dd KEY_ALTX,    ff_event_exit
            dd KEY_CTRLF6,  event_flip
            dd 0

ff_basedir      dd 0
DLG_FindFile    dd 0

ff_table        dd 0
ff_count        dd 0
ff_recursive    dd 0
source          dd 0
target          dd 0

cp_formatID     db '[%04d:%04d]',0

flags           dd compare_name or compare_time or compare_size or compare_subdir

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .code

    option proc: private

ff_event_xcell proc
    ff_putcelid(addr cp_formatID)
    dlxcellevent()
    ret
ff_event_xcell endp

ff_getcurobj proc
    xor eax,eax
    mov edx,tdllist
    .if [edx].S_LOBJ.ll_count != eax

        mov eax,[edx].S_LOBJ.ll_index
        add eax,[edx].S_LOBJ.ll_celoff
        shl eax,2
        mov edx,[edx].S_LOBJ.ll_list
        add edx,eax
        mov eax,[edx]
    .endif
    ret
ff_getcurobj endp

ff_getcurfile proc
    ff_getcurobj()
    .ifnz

        add eax,S_SBLK.sb_file
    .endif
    ret
ff_getcurfile endp

ff_putcelid proc uses ebx format

    mov  ebx,DLG_FindFile
    movzx eax,[ebx].S_DOBJ.dl_index
    .if al >= ID_FILE

        xor eax,eax
    .endif
    inc eax
    mov edx,tdllist
    add eax,[edx].S_LOBJ.ll_index
    mov ecx,[edx].S_LOBJ.ll_count
    mov bx,[ebx+4]
    add bx,0F03h
    mov dl,bh
    scputf(ebx, edx, 0, 0, format, eax, ecx)
    ret

ff_putcelid endp

ff_alloc proc uses esi edi ebx path, fb
    strlen(path)
    add eax,BLOCKSIZE
    mov edi,eax
    .if malloc(eax)
        mov esi,eax
        add eax,S_FBLK.fb_name
        strcpy(eax, path)
        mov ebx,tdllist
        sub edx,edx
        mov eax,[ebx].S_LOBJ.ll_count
        progress_update(edx::eax)
        mov ecx,eax
        mov eax,[ebx].S_LOBJ.ll_count
        inc [ebx].S_LOBJ.ll_count
        mov edx,[ebx].S_LOBJ.ll_count
        .if edx >= ID_FILE
            mov edx,ID_FILE
        .endif
        mov [ebx].S_LOBJ.ll_numcel,edx
        mov ebx,[ebx].S_LOBJ.ll_list
        mov [ebx+eax*4],esi
        mov edi,fb
        xchg    edi,esi
        mov eax,ecx
        mov ecx,4
        rep movsd
        mov dword ptr [edi-8],0
        dec eax
    .endif
    test    eax,eax
    ret
ff_alloc endp

CompareFileData proc uses esi edi ebx A:LPSTR, B:LPSTR

  local h1,h2,b1,b2

    mov b1,alloca(0x8000)
    add eax,0x4000
    mov b2,eax

    .repeat
        mov h1,osopen(A, 0, M_RDONLY, A_OPEN)
        .break  .if eax == -1
        mov h2,osopen(B, 0, M_RDONLY, A_OPEN)
        .if eax == -1

            _close(h1)
            mov eax,-1
            .break
        .endif

        .while osread(h1, b1, 0x4000)

            mov ebx,eax
            .if osread(h2, b2, 0x4000) != ebx

                mov eax,-1
                .break
            .endif

            mov eax,-1
            mov ecx,ebx
            mov esi,b1
            mov edi,b2
            repz cmpsb
            .break .ifnz
        .endw

        mov ebx,eax
        _close(h1)
        _close(h2)
        mov eax,ebx
    .until  1
    ret

CompareFileData endp

ff_fileblock proc uses esi edi ebx directory, wfblk

local path[_MAX_PATH*2]:sbyte, result:dword, found[4]:byte

    xor eax,eax
    mov result,eax

    .repeat

        .break .if eax == ff_count

        mov found,al
        mov edi,wfblk
        mov edx,MAXHIT
        mov result,edx
        mov ebx,tdllist

        .if [ebx].S_LOBJ.ll_count >= edx

            stdmsg(&cp_warning, &cp_emaxfb, edx, edx)
            mov result,2
            .break
        .endif

        mov result,eax
        .break  .if !filter_wblk(edi)

        add edi,WIN32_FIND_DATA.cFileName
        strfcat(&path, directory, edi)
        .break .if !cmpwarg(edi, fp_maskp)

        mov result,test_userabort()
        .break .ifnz

        .for ebx = wfblk, edi = ff_count, esi = ff_table : edi : edi--, esi += 4

            .if flags & compare_size ; Compare File Size

                mov edx,[esi]
                mov eax,dword ptr [edx].S_FBLK.fb_size
                .continue .if eax != [ebx].WIN32_FIND_DATA.nFileSizeLow
                mov eax,dword ptr [edx].S_FBLK.fb_size[4]
                .continue .if eax != [ebx].WIN32_FIND_DATA.nFileSizeHigh
            .endif

            .if flags & compare_attrib ; Compare File Attributes

                mov eax,[edx].S_FBLK.fb_flag
                .continue .if eax != [ebx].WIN32_FIND_DATA.dwFileAttributes
            .endif

            .if flags & compare_time ; Compare Last modification time

                FileTimeToTime(&[ebx].WIN32_FIND_DATA.ftLastWriteTime)
                mov edx,[esi]
                .continue .if eax != [edx].S_FBLK.fb_time
            .endif

            .if flags & compare_create ; Compare File creation time

                .if osopen(&[edx].S_FBLK.fb_name, 0, M_RDONLY, A_OPEN) != -1

                    push eax
                    getftime_create(eax)
                    pop ecx
                    push eax
                    _close(ecx)
                    FileTimeToTime(&[ebx].WIN32_FIND_DATA.ftCreationTime)
                    pop ecx
                    .continue .if eax != ecx
                .endif
                mov edx,[esi]
            .endif

            .if flags & compare_access ; Compare Last access time

                .if osopen(&[edx].S_FBLK.fb_name, 0, M_RDONLY, A_OPEN) != -1

                    push eax
                    getftime_access(eax)
                    pop ecx
                    push eax
                    _close(ecx)
                    FileTimeToTime(&[ebx].WIN32_FIND_DATA.ftLastAccessTime)
                    pop ecx
                    .continue .if eax != ecx
                .endif
                mov edx,[esi]
            .endif

            .if flags & compare_name ; Compare File names

                mov ecx,strfn(&[edx].S_FBLK.fb_name)
                .continue .if _stricmp(&[ebx].WIN32_FIND_DATA.cFileName, ecx)
            .endif

            .if flags & compare_data ; Compare File content

                .continue .if CompareFileData(&[edx].S_FBLK.fb_name, &path)
                mov edx,[esi]
            .endif

            mov found,1
            .break
        .endf

        mov eax,DLG_FindFile
        movzx eax,[eax].S_TOBJ.to_flag[OF_EQUAL]
        and eax,_O_RADIO

        .break .if eax && !found
        .break .if !eax && found

        .if !ff_alloc(&path, edx)

            clear_table()
            ermsg(0, _sys_errlist[ENOMEM*4])
            mov result,-1
        .endif

    .until  1
    mov eax,result
    ret

ff_fileblock endp

clear_table proc
    mov eax,ff_count
    mov edx,ff_table
    .while  eax
        free ([edx])
        add edx,4
        dec eax
    .endw
    mov ff_count,eax
    ret
clear_table endp

clear_list proc
    mov eax,tdllist
    mov edx,[eax].S_LOBJ.ll_list
    mov eax,[eax].S_LOBJ.ll_count
    .while  eax
        free ([edx])
        add edx,4
        dec eax
    .endw
    mov edx,tdllist
    mov [edx].S_LOBJ.ll_celoff,eax
    mov [edx].S_LOBJ.ll_index,eax
    mov [edx].S_LOBJ.ll_numcel,eax
    mov [edx].S_LOBJ.ll_count,eax
    ret
clear_list endp

ff_addfileblock proc uses esi edi ebx directory, wfblk

local path[512]:byte
local fsize:qword

    mov edi,wfblk
    mov eax,[edi].WIN32_FIND_DATA.nFileSizeHigh
    mov dword ptr fsize[4],eax
    mov eax,[edi].WIN32_FIND_DATA.nFileSizeLow
    mov dword ptr fsize,eax

    .if filter_wblk(edi)
        strfcat(&path, directory, &[edi].WIN32_FIND_DATA.cFileName)
        mov eax,ff_count
        .if eax < MAXHIT
            FileTimeToTime(&[edi].WIN32_FIND_DATA.ftLastWriteTime)
            mov ecx,eax
            .if fballoc(&path, ecx, fsize, [edi].WIN32_FIND_DATA.dwFileAttributes)
                mov ecx,ff_count
                inc ff_count
                shl ecx,2
                add ecx,ff_table
                mov [ecx],eax
                xor ecx,ecx
                mov eax,ff_count
                progress_update(ecx::eax)
            .else
                clear_table()
                ermsg(0, _sys_errlist[ENOMEM*4])
                mov eax,1
            .endif
        .else
            stdmsg(&cp_warning, &cp_emaxfb, eax, eax)
            mov eax,2
        .endif
    .endif
    ret
ff_addfileblock endp

clear_slash proc string
    mov eax,string
    mov ecx,[eax+1]
    and ecx,00FFFFFFh
    .if ecx == 00005C3Ah ; ":\"
        mov byte ptr [eax+2],0
    .endif
    ret
clear_slash endp

ff_directory proc directory
    mov eax,1
    .if ff_recursive != eax
        mov edx,source
        strlen(edx)
        push eax
        strlen(directory)
        pop ecx
        .if eax >= ecx
            mov eax,ecx
        .endif
        .if !_strnicmp(directory, edx, eax)
            rsmodal(IDD_DZRecursiveCompare)
        .endif
    .endif
    .if eax
        mov ff_recursive,1
        .if !progress_set(0, directory, 0)
            scan_files(directory)
        .endif
    .endif
    ret
ff_directory endp

ffsearchinitpath proc private path

    mov esi,path
    mov ah,0
    mov dl,' '
    .if [esi] == dl

        inc esi
    .endif
    .if byte ptr [esi] == '"'

        inc esi
        mov dl,'"'
    .endif
    push esi
    .repeat
        mov  al,[esi]
        test al,al
        jz   @F
        inc  esi
    .until  al == dl
    mov [esi-1],ah
@@:
    pop eax
    ret
ffsearchinitpath endp

ff_searchpath proc uses esi edi ebx directory

  local path[_MAX_PATH]:byte

    strcpy(addr path, directory)
    xor ecx,ecx
    xor ebx,ebx
    mov ff_basedir,eax
    .if path == cl

        mov path,'"'
        inc eax
        mov edx,com_wsub
        strcpy(eax, [edx].S_WSUB.ws_path)
    .endif

    .repeat
        ;
        ; Multi search using quotes:
        ; Find Files: ["Long Name.type" *.c *.asm.......]
        ; Location:   ["D:\My Documents" c: f:\doc......]
        ;
        ffsearchinitpath(ff_basedir)
        mov ff_basedir,eax
        push esi
        .if strlen(eax)
            push eax
            add eax,ff_basedir
            .if byte ptr [eax-1] == '\'

                mov byte ptr [eax-1],0
            .endif
            mov eax,DLG_FindFile
            mov edi,[eax+OF_SUBD]
            mov eax,[eax].S_TOBJ.to_data[OF_MASK]
            mov fp_maskp,eax
            .repeat
                ffsearchinitpath(fp_maskp)
                mov  fp_maskp,eax
                push edx
                .if edi & _O_FLAGB

                    scan_directory(1, ff_basedir)
                .else
                    push ff_basedir
                    call fp_directory
                .endif
                mov ebx,eax
                pop edx
                mov fp_maskp,esi
                .if dl == '"'

                    mov [esi-1],dl
                .endif
                .break .if byte ptr [esi] == 0
                mov [esi-1],dl
            .until eax
            pop eax
        .endif
        pop esi
        mov ff_basedir,esi
        .break .if ebx
        .break .if byte ptr [esi] == 0
    .until !eax
    mov eax,ebx
    ret
ff_searchpath endp

event_find proc uses esi edi ebx
  local cursor:S_CURSOR
    CursorGet(&cursor)
    CursorOff()
    clear_table()
    clear_list()
    mov ebx,DLG_FindFile
    dlinit(ebx)
    clear_slash(source)
    mov esi,eax
    clear_slash(target)
    mov fp_directory,ff_directory
    mov fp_fileblock,ff_addfileblock
    mov ff_recursive,1
    progress_open("Read Source", 0)
    progress_set(esi, 0, MAXHIT)
    mov fp_maskp,offset cp_stdmask
    mov al,[ebx+OF_SUBD]
    .if al & _O_FLAGB
        scan_directory(1, esi)
    .else
        ff_directory(esi)
    .endif
    progress_close()
    xor eax,eax
    mov ff_recursive,eax
    mov fp_fileblock,ff_fileblock
    .if ff_count != eax && !([ebx].S_TOBJ.to_flag[OF_GOTO] & _O_STATE)
        mov ax,[ebx+4]
        add ax,0F03h
        mov dl,ah
        scputw(eax, edx, 15, 00C4h)
        progress_open("Compare", 0)
        mov eax,target
        push eax
        progress_set(eax, 0, MAXHIT+2)
        ff_searchpath()
        progress_close()
        clear_table()
        mov edx,tdllist
        mov eax,[edx].S_LOBJ.ll_count
        .if eax >= ID_FILE
            mov eax,ID_FILE
        .endif
        mov [edx].S_LOBJ.ll_numcel,eax
        update_cellid()
    .endif
    CursorSet(&cursor)
    ret
event_find endp


event_help proc

    view_readme(HELPID_14)
    ret

event_help endp


event_mklist proc uses esi edi

    mov esi,tdllist
    xor eax,eax

    .if [esi].S_LOBJ.ll_count != eax

        .if mklistidd()

            xor edi,edi

            .while edi < [esi].S_LOBJ.ll_count

                mov edx,[esi].S_LOBJ.ll_list
                mov edx,[edx+edi*4]
                push edx
                strfn(&[edx].S_FBLK.fb_name)
                pop edx
                lea ecx,[edx].S_FBLK.fb_name
                sub eax,ecx
                mov mklist.mkl_offspath,eax
                mov mklist.mkl_offset,0
                lea eax,[edx].S_FBLK.fb_name
                mklistadd()
                inc edi
            .endw

            _close(mklist.mkl_handle)
            mov eax,_C_NORMAL
        .endif
    .endif
    ret

event_mklist endp

event_list proc uses esi edi
    dlinit(DLG_FindFile)
    mov eax,DLG_FindFile
    movzx esi,[eax].S_DOBJ.dl_rect.rc_x
    add   esi,4
    movzx edi,[eax].S_DOBJ.dl_rect.rc_y
    add edi,2
    mov eax,tdllist
    mov edx,[eax].S_LOBJ.ll_index
    shl edx,2
    add edx,[eax].S_LOBJ.ll_list
    mov ecx,[eax].S_LOBJ.ll_numcel
    .while  ecx
        mov eax,[edx]
        add eax,S_FBLK.fb_name
        scpath(esi, edi, 68, eax)
        inc edi
        add edx,4
        dec ecx
    .endw
    mov eax,1
    ret
event_list endp

update_cellid proc
    ff_putcelid(&cp_formatID)
    event_list()
    jmp ff_update_cellid
update_cellid endp

event_delete proc
    ff_deleteobj()
    update_cellid()
    mov eax,_C_NORMAL
    ret
event_delete endp

event_path proc
    mov eax,panela ; Source - Panel-A
    mov ecx,[eax].S_PANEL.pn_wsub
    strcpy(source, [ecx].S_WSUB.ws_path)
    mov eax,panelb ; Target - Panel-B
    mov ecx,[eax].S_PANEL.pn_wsub
    strcpy(target, [ecx].S_WSUB.ws_path)
    mov eax,DLG_FindFile
    .if eax
        dlinit(eax)
    .endif
    mov eax,_C_NORMAL
    ret
event_path endp

event_advanced proc

    CompareOptions(&flags)
    mov eax,_C_NORMAL
    ret

event_advanced endp

event_flip proc

    mov eax,DLG_FindFile
    .if eax
        mov ecx,[eax].S_TOBJ.to_data[OF_SOURCE]
        mov edx,[eax].S_TOBJ.to_data[OF_TARGET]
        mov [eax].S_TOBJ.to_data[OF_SOURCE],edx
        mov [eax].S_TOBJ.to_data[OF_TARGET],ecx
        mov [eax].S_DOBJ.dl_index,ID_FILE
        dlinit(eax)
        PushEvent(KEY_ENTER)
    .endif
    mov eax,_C_NORMAL
    ret

event_flip endp

ff_event_edit proc
    ff_getcurfile()
    jz event_normal
    push eax
    dlhide(DLG_FindFile)
    pop eax
    tedit(eax, [eax-8])
    dlshow(DLG_FindFile)
event_normal:
    mov eax,_C_NORMAL
    ret
ff_event_edit endp

ff_event_exit proc
    mov eax,_C_ESCAPE
    ret
ff_event_exit endp

ff_event_view proc
    mov eax,DLG_FindFile
    cmp [eax].S_DOBJ.dl_index,ID_FILE
    jnb event_normal
    ff_getcurfile()
    jz  event_normal
    tview(eax, [eax-4]) ; .S_SBLK.sb_offs
event_normal:
    mov eax,_C_NORMAL
    ret
ff_event_view endp

ff_event_filter proc
    cmfilter()
    mov edx,DLG_FindFile
    mov dx,[edx+4]
    add dx,1410h
    mov cl,dh
    mov eax,filter
    test eax,eax
    mov eax,7
    .if ZERO?
        mov al,' '
    .endif
    scputw(edx, ecx, 1, eax)
    mov eax,_C_NORMAL
    ret
ff_event_filter endp

ff_update_cellid proc uses edi ebx

    mov ebx,DLG_FindFile
    mov edi,tdllist
    mov ecx,ID_FILE
    mov eax,_O_STATE
    .repeat
        add ebx,16
        or  [ebx],ax
    .untilcxz
    mov ebx,DLG_FindFile
    mov eax,not _O_STATE
    mov ecx,[edi].S_LOBJ.ll_numcel
    .while ecx
        add ebx,16
        and [ebx],ax
        dec ecx
    .endw
    mov eax,_C_NORMAL
    ret

ff_update_cellid endp

ff_deleteobj proc uses ebx

    ff_getcurobj()
    .if !ZERO?
        .repeat
            mov ecx,[edx+4]
            mov [edx],ecx
            add edx,4
        .until !ecx

        free(eax)
        mov ebx,tdllist
        dec [ebx].S_LOBJ.ll_count
        mov eax,[ebx].S_LOBJ.ll_count
        mov edx,[ebx].S_LOBJ.ll_index
        mov ecx,[ebx].S_LOBJ.ll_celoff
        .if ZERO?

            mov edx,eax
            mov ecx,eax
        .else
            .if edx

                mov ebx,eax
                sub ebx,edx
                .if ebx < ID_FILE
                    dec edx
                    inc ecx
                .endif
            .endif
            sub eax,edx
            .if eax >= ID_FILE

                mov eax,ID_FILE
            .endif
            .if ecx >= eax

                dec ecx
            .endif
        .endif
        mov ebx,tdllist
        mov [ebx].S_LOBJ.ll_index,edx
        mov [ebx].S_LOBJ.ll_celoff,ecx
        mov [ebx].S_LOBJ.ll_numcel,eax
        mov ebx,DLG_FindFile
        test eax,eax
        mov al,cl
        .if ZERO?
            mov al,ID_FILE
        .endif
        mov [ebx].S_DOBJ.dl_index,al
        mov eax,1
    .endif
    ret

ff_deleteobj endp

ff_close proc uses esi edi

    mov edi,tdllist
    mov esi,[edi].S_LOBJ.ll_list
    .if esi
        mov edi,[edi].S_LOBJ.ll_count
        .while  edi
            lodsd
            free(eax)
            dec edi
        .endw
        mov edi,tdllist
        free([edi].S_LOBJ.ll_list)
    .endif
    ret

ff_close endp

ff_close_dlg proc

    mov byte ptr fsflag,ah
    movzx eax,[ebx].S_DOBJ.dl_index
    dlclose(ebx)

    .if edx == ID_GOTO

        mov ebx,tdllist
        .if [ebx].S_LOBJ.ll_count

            .if panel_state(cpanel)

                mov eax,[ebx].S_LOBJ.ll_index
                add eax,[ebx].S_LOBJ.ll_celoff
                mov ebx,[ebx].S_LOBJ.ll_list
                mov ebx,[ebx+eax*4]
                add ebx,S_SBLK.sb_file

                .if strrchr(ebx, '\')

                    mov byte ptr [eax],0
                    cpanel_setpath(ebx)
                .endif
            .endif
        .endif
    .endif
    ret
ff_close_dlg endp

ff_rsevent proc idd, find

    .repeat
        mov [edx],eax
        add edx,sizeof(S_TOBJ)
    .untilcxz
    dlshow(ebx)
    dlinit(ebx)

    mov filter,0
    .while rsevent(idd, ebx)

        mov esi,eax
        mov edi,ecx
        mov al,[ebx].S_DOBJ.dl_index
        .if al < ID_FILE

            .break .if ff_event_view() != _C_NORMAL
        .else
            .break .if al == ID_GOTO
            find()
        .endif
    .endw
    mov ah,byte ptr fsflag
    ret
ff_rsevent endp

cmcompsub proc PUBLIC uses esi edi ebx

  local cursor:S_CURSOR,
        ll:S_LOBJ,
        old_thelp:dword,
        fmask[_MAX_PATH]:sbyte,
        tpath[_MAX_PATH]:sbyte,
        spath[_MAX_PATH]:sbyte

    lea eax,tpath
    mov target,eax
    lea eax,spath
    mov source,eax
    mov DLG_FindFile,0
    strcpy(&fmask, &cp_stdmask)
    event_path()

    .if CFGetSection(".compsubdir")
        mov ebx,eax
        .if INIGetEntryID(ebx, 0)
            mov flags,__xtol(eax)
        .endif
        .if INIGetEntryID(ebx, 1)
            strcpy(&fmask, eax)
        .endif
        .if INIGetEntryID(ebx, 2)
            strcpy(source, eax)
        .endif
        .if INIGetEntryID(ebx, 3)
            strcpy(target, eax)
        .endif
    .endif

    mov ff_count,0
    mov eax,thelp
    mov old_thelp,eax
    mov thelp,event_help
    clrcmdl()
    CursorGet(&cursor)
    lea edx,ll
    mov tdllist,edx
    mov edi,edx
    mov ecx,sizeof(S_LOBJ)
    xor eax,eax
    rep stosb
    mov [edx].S_LOBJ.ll_dcount,ID_FILE
    mov [edx].S_LOBJ.ll_proc,event_list

    .if malloc((MAXHIT * 8) + 4)

        mov ll.ll_list,eax
        add eax,(MAXHIT*4)+4
        mov ff_table,eax

        .if rsopen(IDD_DZCompareDirectories)

            mov DLG_FindFile,eax
            mov ebx,eax
            mov [ebx].S_TOBJ.to_data[OF_GCMD],offset GCMD_search
            mov [ebx].S_TOBJ.to_count[OF_MASK],256/16
            mov [ebx].S_TOBJ.to_count[OF_SOURCE],256/16
            mov [ebx].S_TOBJ.to_count[OF_TARGET],256/16
            lea eax,fmask
            mov [ebx].S_TOBJ.to_data[OF_MASK],eax
            mov eax,source
            mov [ebx].S_TOBJ.to_data[OF_SOURCE],eax
            mov eax,target
            mov [ebx].S_TOBJ.to_data[OF_TARGET],eax
            mov [ebx].S_TOBJ.to_proc[OF_FIND],event_find
            mov [ebx].S_TOBJ.to_proc[OF_FILT],ff_event_filter
            mov [ebx].S_TOBJ.to_proc[OF_SAVE],event_mklist

            mov ecx,flags
            mov al,_O_RADIO
            .if ecx & compare_equal
                or [ebx+OF_EQUAL],al
            .else
                or [ebx+OF_DIFFER],al
            .endif

            and fsflag,not IO_SEARCHSUB
            .if ecx & compare_subdir

                or byte ptr [ebx+OF_SUBD],_O_FLAGB
                or fsflag,IO_SEARCHSUB
            .endif

            lea edx,[ebx].S_TOBJ.to_proc[sizeof(S_TOBJ)]
            mov ecx,ID_FILE
            mov eax,ff_event_xcell

            ff_rsevent(IDD_DZCompareDirectories, event_find)

            and ah,not IO_SEARCHSUB
            and flags,NOT (compare_equal or compare_subdir)
            .if byte ptr [ebx+OF_EQUAL] & _O_RADIO

                or flags,compare_equal
            .endif
            .if byte ptr [ebx+OF_SUBD] & _O_FLAGB

                or flags,compare_subdir
                or ah,IO_SEARCHSUB
            .endif

            ff_close_dlg()
            clear_list()
            clear_table()
        .else
            ermsg(0, _sys_errlist[ENOMEM*4])
        .endif
        free(ll.ll_list)
    .endif

    .if CFAddSection(".compsubdir")

        mov ebx,eax
        INIAddEntryX(ebx, "0=%X", flags)
        INIAddEntryX(ebx, "1=%s", &fmask)
        INIAddEntryX(ebx, "2=%s", &spath)
        INIAddEntryX(ebx, "3=%s", &tpath)
    .endif

    CursorSet(&cursor)
    mov eax,old_thelp
    mov thelp,eax

    xor eax,eax
    ret

cmcompsub endp

    END
