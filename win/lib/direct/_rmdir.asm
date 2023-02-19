; _RMDIR.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include direct.inc
include errno.inc
include winbase.inc

__allocwpath proto :LPSTR

    .code

_rmdir proc directory:LPSTR

    .if !RemoveDirectoryA(directory)

        RemoveDirectoryW(__allocwpath(directory))
        mov esp,ebp
    .endif

    .if !eax
        osmaperr()
    .else
        xor eax,eax
    .endif
    ret

_rmdir endp

    END
