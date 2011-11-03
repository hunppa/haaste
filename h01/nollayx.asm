; print square of zeros and ones

%ifidn __OUTPUT_FORMAT__, elf32

%elifidn __OUTPUT_FORMAT__, elf64

%else
  %fatal -f elf32 or elf64 required!

%endif


section .data
      uinput:     db    0
      buf_sz:     db    255
      zerone:     dw    0x3031
      onezer:     dw    0x3130

      mem_at:     dd    0
      mem_sz:     dd    0

      inputmsg:   db    'input> '
      inputlen:   equ   $ - inputmsg

      errormsg:   db    'error.', 0x0a
      errorlen:   equ   $ - errormsg

section .bss
      buffer:     resb  255

section .text
      global _start


_start:
      mov   eax, 4            ; sys_write
      mov   ebx, 1            ; stdout
      mov   ecx, inputmsg
      mov   edx, inputlen
      int   80h

      mov   eax, 3            ; sys_read
      mov   ebx, 2            ; stdin
      mov   ecx, buffer
      mov   edx, buf_sz
      int   80h

      test  eax, eax
      js    .error            ; jump on error (-1)

      mov   ecx, 0            ; ecx is next used as
                              ; exit code or counter
      sub   eax, 1
      test  eax, eax
      jz    .quit             ; no input given :-(

      mov   esi, buffer
.nextint:
      mov   dl, byte [esi]    ; take a byte
      inc   esi               ; (*buffer)++

      sub   dl, 48            ; cheap atoi(3)
      imul  ecx, 10
      add   cl, dl

      sub   eax, 1            ; if there's
      test  eax, eax          ; more to read,
      jnz   .nextint          ; read more

      test  ecx, ecx          ; user gave zero, bail out
      jz    .quit             ; jecxz jumps too short!

      mov   [uinput], cl      ; save user input

      mov   eax, ecx          ; calc required memory
      inc   eax               ; sidenote: n(n+1) is always even
      mul   ecx

      mov   ecx, eax
      mov   [mem_sz], eax     ; save for later

.bork:
      mov   eax, 45
      mov   ebx, 0
      int   80h               ; get original break..

      mov   edi, eax          ; ..and keep it

      add   eax, ecx
      mov   ebx, eax
      mov   eax, 45
      int   80h               ; new break at eax if success

      test  edi, eax          ; old and new break
      je    .quit             ; should NOT be equal (brk(2))

      mov   [mem_at], edi     ; save mem ptr

      mov   ax, word [zerone] ; lets initialize memory we have
      shr   ecx, 1
      rep   stosw             ; now it should read 010101...

      mov   bl, [uinput]
      and   ebx, 0x01

      test  ebx, ebx
      jz    .even

      mov   bl, [uinput]
      shr   bl, 1
      mov   ax, [onezer]
      mov   edi, [mem_at]
.odds:
      mov   cl, [uinput]
      add   edi, ecx
      inc   edi
      shr   ecx, 1
      inc   ecx
      rep   stosw

      dec   ebx
      test  ebx, ebx
      jnz   .odds

.even:
      mov   eax, 0x0a         ; newlines for the masses
      mov   edi, [mem_at]
      mov   cl, [uinput]
      mov   edx, ecx
      inc   edx
.newline:
      add   edi, edx
      mov   [edi], al
      loop  .newline

.prnt:
      mov   eax, 4
      mov   ebx, 1
      mov   ecx, [mem_at]
      mov   edx, [mem_sz]
      inc   ecx
      int   80h

.quit:
      mov   ebx, ecx          ; exit(ecx)
      mov   eax, 1
      int   80h

.error:
      mov   eax, 4            ; print err msg
      mov   ebx, 1
      mov   ecx, errormsg
      mov   edx, errorlen
      int   80h
      mov   eax, 1            ; sys_exit
      mov   ebx, 1            ; exit code 1
      int   80h
