BITS 64
DEFAULT REL

; MS-DOS STUB
start: db "MZ"
times 0x3A db 0
dd 0x40							; 0x3c offset
db "PE", 0, 0					; signature

; COFF HEADER
dw 0x8664						; Machine
dw 2							; NumberOfSections
dd 0							; TimeDateStamp
dd 0							; PointerToSymbolTable
dd 0							; NumberOfSymbols
dw 0xF0							; SizeOfOptionalHeader
dw 0x22							; Characteristics

; OPTIONAL HEADER
dw 0x20B						; Magic
db 0							; MajorLinkerVersion
db 0							; MinorLinkerVersion
dd 0							; SizeOfCode
dd 0							; SizeOfInitializedData
dd 0							; SizeOfUninitializedData
dd 0x8000						; AddressOfEntryPoint
dd 0							; BaseOfCode

dq 0x140000000					; ImageBase
dd 0x1000						; SectionAlignment
dd 0x200						; FileAlignment
dw 6							; MajorOperatingSystemVersion
dw 0							; MinorOperatingSystemVersion
dw 0							; MajorImageVersion
dw 0							; MinorImageVersion
dw 6							; MajorSubsystemVersion
dw 0							; MinorSubsystemVersion
dd 0							; Win32VersionValue
dd 0x10000						; SizeOfImage
dd 0x1000						; SizeOfHeaders
dd 0							; CheckSum
dw 3							; Subsystem
dw 0x8160						; DllCharacteristics
dq 0x100000						; SizeOfStackReserve
dq 0x1000						; SizeOfStackCommit
dq 0x100000						; SizeOfHeapReserve
dq 0x1000						; SizeOfHeapCommit
dd 0							; LoaderFlags
dd 16							; NumberOfRVAAndSizes

dq 0							; export table
dd idt							; import table RVA
dd 0							; import table size
times 14 dq 0					; other tables

; SECTION HEADERS
dq ".data"						; Name
dd 0x7000						; VirtualSize
dd 0x1000						; VirtualAddress
dd 0x7000						; SizeOfRawData
dd 0x1000						; PointerToRawData
dd 0							; PointerToRelocations
dd 0							; PointerToLineNumbers
dw 0							; NumberOfRelocations
dw 0							; NumberOfLineNumbers
dd 0xC0000040					; Characteristics

dq ".code"						; Name
dd 0x8000						; VirtualSize
dd 0x8000						; VirtualAddress
dd 0x8000						; SizeOfRawData
dd 0x8000						; PointerToRawData
dd 0							; PointerToRelocations
dd 0							; PointerToLineNumbers
dw 0							; NumberOfRelocations
dw 0							; NumberOfLineNumbers
dd 0x60000020					; Characteristics

endofheader: times (0x1000-(endofheader-start)) db 0

; DLL AND FUNCTION NAMES
kernel32dll: db "kernel32.dll"
createfilea: db 0, 0, "CreateFileA"
exitprocess: db 0, 0, "ExitProcess"
getcommandlinea: db 0, 0, "GetCommandLineA"
getstdhandle: db 0, 0, "GetStdHandle"
readfile: db 0, 0, "ReadFile"
setfilepointer: db 0, 0, "SetFilePointer"
writefile: db 0, 0, "WriteFile", 0

; IMPORT ADDRESS TABLE
CreateFileA: dq createfilea
ExitProcess: dq exitprocess
GetCommandLineA: dq getcommandlinea
GetStdHandle: dq getstdhandle
ReadFile: dq readfile
SetFilePointer: dq setfilepointer
WriteFile: dq writefile
dq 0

; IMPORT DIRECTORY TABLE
idt: dd 0						; Import Lookup Table RVA
dd 0							; Time/Date Stamp
dd 0							; Forwarder Chain
dd kernel32dll					; Name RVA
dd CreateFileA					; Import Address Table RVA
times 20 db 0

endofdatadll: times (0x2000-(endofdatadll-start)) db 0

; DATA
readbuffer: times 0x1000 db 0
writebuffer: times 0x1000 db 0
stdhandleout: dq 0
readfilehandle: dq 0
writefilehandle: dq 0

readfilename: db "compile.txt", 0
writefilename: db "compile.exe", 0
exefilename: db "msl.exe", 0

dd 0.1
pow: dd 0
dd 10.0

endofdata: times (0x8000-(endofdata-start)) db 0

; CODE
sub rsp, 56						; get stdhandleout for printing
mov rcx, -11
call [GetStdHandle]
mov [stdhandleout], rax

lea rcx, [readfilename]			; get read file handle
mov rdx, 0x80000000
xor r8, r8
xor r9, r9
mov dword [rsp+32], 3
mov dword [rsp+40], 0x80
mov qword [rsp+48], 0
call [CreateFileA]
mov [readfilehandle], rax

lea rcx, [writefilename]		; get write file handle
mov rdx, 0x10000000
xor r8, r8
xor r9, r9
mov dword [rsp+32], 2
mov dword [rsp+40], 0x80
mov qword [rsp+48], 0
call [CreateFileA]
mov [writefilehandle], rax

lea rcx, [exefilename]			; get executable handle
mov rdx, 0x80000000
xor r8, r8
xor r9, r9
mov dword [rsp+32], 3
mov dword [rsp+40], 0x80
mov qword [rsp+48], 0
call [CreateFileA]

mov rcx, rax					; copy PE headers in writebuffer
lea rdx, [writebuffer]
mov r8, 0x1000
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [ReadFile]
add rsp, 56

xor r12, r12					; read bytes
xor r13, r13					; written bytes
lea rsi, [readbuffer]			; read address
lea rdi, [writebuffer+0x1000]	; write address
lea rbp, [dll]

readwrite:
sub rsp, 56						; write writebuffer
mov rcx, [writefilehandle]
lea rdx, [writebuffer]
mov r8, rdi
sub r8, rdx
add r13, r8
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [WriteFile]
mov rcx, [readfilehandle]		; update readbuffer
lea rdx, [readbuffer]
sub rdx, rsi
neg rdx
add rdx, r12
mov r12, rdx
xor r8, r8
xor r9, r9
call [SetFilePointer]
mov rcx, [readfilehandle]
lea rdx, [readbuffer]
mov r8, 0x1000
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [ReadFile]
mov eax, [rsp+40]
add rsp, 56
lea rdi, [writebuffer]
lea rsi, [readbuffer]			; move rsi at first nonwhitespace character and exit if the end is reached
mov byte [rsi+rax], 255
sub rsi, 1
whitespace:
add rsi, 1
mov al, [rsi]
cmp al, 33
jc whitespace
jmp rbp

dll:							; dll imports
cmp al, '$'
jnz init
sub rsp, 16						; make dll symbol
mov qword [rsp], 0
mov qword [rsp+8], r13
add rsi, 1						; copy dll name
mov al, [rsi]
dllcopy:
mov [rdi], al
add rdi, 1
add rsi, 1
mov al, [rsi]
cmp al, 33
jnc dllcopy
mov byte [rdi], 0
add rdi, 1
lea rbp, [dllprefunction]
jmp readwrite
dllprefunction:
lea rbp, [dll]
mov al, [rsi]
cmp al, '$'
jz readwrite
cmp al, 'A'
jc dllIATpad
cmp al, 'Z'+1
jc dllfunction
cmp al, '_'
jz dllfunction
cmp al, 'a'
jc dllIATpad
cmp al, 'z'+1
jc dllfunction
jmp dllIATpad
dllfunction:					; make dll function symbol
sub rsp, 16
mov rcx, r13
sub rcx, 1
mov [rsp+8], rcx
mov byte [rdi], 0
add rdi, 1
mov rcx, 1099511628211			; copy and hash dll function name
mov rdx, 0x9E3779B185EBCA87
dllfunctioncopy:
xor cl, al
imul rcx, rdx
rol rcx, 27
mov [rdi], al
add rdi, 1
add rsi, 1
mov al, [rsi]
cmp al, 33
jnc dllfunctioncopy
mov [rsp], rcx
mov byte [rdi], 0
add rdi, 1
lea rbp, [dllprefunction]
jmp readwrite

dllIATpad:						; pad to 8-byte before IAT
xor rax, rax
mov [rdi], rax
mov rax, r13
neg rax
and rax, 7
add rdi, rax
mov rbx, rsp					; write IAT
lea rbp, [dllIAT]
jmp readwrite
dllIAT:
mov rax, [rbx+8]
mov rcx, [rbx]
mov rdx, rax
test rcx, rcx
cmovz rax, rcx
mov [rdi], rax
add rdi, 8
test rcx, rcx
cmovnz rdx, r13
mov [rbx+8], rdx
add rbx, 16
lea rbp, [dllIAT]
lea rcx, [dllIDT]
mov rax, [rbx-8]
cmp rax, 0x1000
cmovz rbp, rcx
jmp readwrite
dllIDT:							; write IDT
mov rbx, rsp
dllIDTloop:
mov rax, [rbx+8]
dllIDTdll:
add rbx, 16
mov rcx, [rbx]
test rcx, rcx
jnz dllIDTdll
xor rcx, rcx
mov [rdi], rcx
mov [rdi+8], rcx
mov rcx, [rbx+8]
mov [rdi+12], ecx
mov [rdi+16], eax
add rdi, 20
add rbx, 16
lea rbp, [dllIDTloop]
cmp rcx, 0x1000
jnz readwrite
xor r11, r11
mov [rdi], r11					; IDT end
mov [rdi+8], r11
mov [rdi+16], r11
add rdi, 20
mov rax, r13
neg rax
and rax, 7
add rax, rdi
lea rbp, [init]
jmp readwrite

init:							; initialized data
cmp al, '#'
jnz uninit
add rsi, 1						; hash name
mov al, [rsi]
mov rcx, 1099511628211
mov rdx, 0x9E3779B185EBCA87
inithash:
xor cl, al
imul rcx, rdx
rol rcx, 27
add rsi, 1
mov al, [rsi]
cmp al, 33
jnc inithash
sub rsp, 16						; make symbol with name
mov [rsp], rcx
mov [rsp], r13
xor rbx, rbx
add rsi, 1						; check if repeat data
mov al, [rsi]
cmp al, '`'
jnz initdata
add rsi, 1
lea rbp, [initrepeat]
jmp number
initrepeat:
mov rbx, r11
shl rbx, 32
or rbx, r13
add rsi, 1
mov al, [rsi]
initdata:
cmp al, '"'
jz initstring
lea rbp, [initnumber]
cmp al, '-'
jz number
cmp al, '.'
jz number
cmp al, '0'
jc initend
cmp al, '9'+1
jc number
jmp initend

initstring:						; handle initialized string
add rsi, 1
lea rbp, [initstringinner]
initstringinner:
lea rcx, [readbuffer+0xFFF]
lea rdx, [writebuffer+0xFFF]
initstringloop:
mov al, [rsi]
cmp al, '"'
jnz initstringloopnoend
add rsi, 2
mov al, [rsi]
lea rbp, [initdata]
jmp readwrite
initstringloopnoend:
mov [rdi], al
add rdi, 1
cmp rsi, rcx
jz readwrite
cmp rdi, rdx
jz readwrite
add rsi, 1
jmp initstringloop

initnumber:						; handle initialized number
mov rax, r11
xor rax, -1
test r11, r11
cmovns rax, r11
mov rcx, 8
mov rdx, 4
mov r8d, 0x80000000
cmp rax, r8
cmovc rcx, rdx
mov rdx, 1
cmp r11, 256
cmovc rcx, rdx
mov [rdi], r11
add rdi, rcx
lea rbp, [initdata]
jmp readwrite

initend:						; check if repeat sequence
test rbx, rbx
jz init
sub rsp, 56
mov rcx, [writefilehandle]
mov edx, ebx
sub rdx, r13
neg rdx
shr rbx, 32
sub rbx, 1
shl rbx, 32
or rbx, rdx
neg rdx
xor r8, r8
mov r9, 2
call [SetFilePointer]
mov rcx, [writefilehandle]
lea rdx, [writebuffer]
mov r8, 0x1000
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [ReadFile]
initendrepeat:
mov rcx, [writefilehandle]
lea rdx, [writebuffer]
mov r8d, ebx
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [WriteFile]
ror rbx, 32
sub rbx, 1
mov eax, ebx
rol rbx, 32
test rax, rax
jnz initendrepeat
add rsp, 56
jmp init

uninit:

exit:							; exit
sub rsp, 40
xor rcx, rcx
call [ExitProcess]

number:
xor rcx, rcx					; rcx: -1 if negative number
mov r11, -1
cmp al, '-'
cmovz rcx, r11
sub rsi, rcx
xor r11, r11					; r11: number
mov rax, [rsi]
and rax, 0xFFFF
add rsi, 1
cmp rax, '0b'
jz numberbase2
cmp rax, '0x'
jz numberbase16
sub rsi, 2
xor rdx, rdx					; rdx: exponent
xor r8, r8						; r8: float indicator
mov r9, 1
numberbase10:
add rsi, 1
movzx rax, byte [rsi]
cmp al, '_'
jz numberbase10
cmp al, 33
jc numberbase10finish
cmp al, 'e'
jz numberexponent
cmp al, '.'
cmovz r8, r9
jz numberbase10
shl r11, 1
lea r11, [r11+r11*4]
sub rax, 48
xor rax, rcx
sub rax, rcx
add r11, rax
test r8, r8
jz numberbase10
sub rdx, 1
jmp numberbase10
numberexponent:
xor r8, r8						; r8: -1 if negative exponent
mov r9, -1
add rsi, 1
mov al, [rsi]
cmp al, '-'
cmovz r8, r9
xor r9, r9						; r9: e exponent
numberexponentloop:
add rsi, 1
movzx rax, byte [rsi]
cmp rax, 33
jc numberexponentefinish
shl r9, 1
lea r9, [r9+r9*4]
sub rax, 48
xor rax, r8
sub rax, r8
add r9, rax
jmp numberexponentloop
numberexponentefinish:
add rdx, r9
mov r8, 1
numberbase10finish:
test r8, r8
jz return						; return integer
vcvtsi2ss xmm0, xmm0, r11
mov rax, 1
mov rcx, -1
bt rdx, 63
cmovc rax, rcx
lea rcx, [pow]
vmovd xmm1, [rcx+rax*4]
numberexponentmultiply:
test rdx, rdx
jz numberexponentmultiplyend
vmulps xmm0, xmm0, xmm1
sub rdx, rax
jmp numberexponentmultiply
numberexponentmultiplyend:
vmovd r11d, xmm0
jmp rbp							; return float

numberbase2:
add rsi, 1
movzx rax, byte [rsi]
cmp al, '_'
jz numberbase2
cmp al, 33
jc return						; return binary
shl r11, 1
sub rax, 48
xor rax, rcx
sub rax, rcx
add r11, rax
jmp numberbase2

numberbase16:
add rsi, 1
movzx rax, byte [rsi]
cmp al, '_'
jz numberbase16
cmp al, 33
jc return						; return hexadecimal
shl r11, 4
mov rdx, 87
mov r8, 48
cmp al, 'a'
cmovnc r8, rdx
sub rax, r8
xor rax, rcx
sub rax, rcx
add r11, rax
jmp numberbase16

return:
jmp rbp

endofcode: times (0x10000-(endofcode-start)) db 0
