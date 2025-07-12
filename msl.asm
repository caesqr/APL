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
dd 0x8000						; SizeOfCode
dd 0x7000						; SizeOfInitializedData
dd 0							; SizeOfUninitializedData
dd 0x8000						; AddressOfEntryPoint
dd 0x8000						; BaseOfCode

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
dd 0x10C0						; import table RVA
dd 0							; import table size
times 14 dq 0					; other tables

; SECTION HEADERS
dq ".text"						; Name
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
db "kernel32.dll"
db 0, 0, "CloseHandle"
db 0, 0, "CreateFileA"
db 0, 0, "ExitProcess"
db 0, 0, "GetCommandLineA"
db 0, 0, "GetStdHandle"
db 0, 0, "ReadFile"
db 0, 0, "SetFilePointer"
db 0, 0, "WriteFile", 0

; IMPORT ADDRESS TABLE
CloseHandle: dq 0x100C
CreateFileA: dq 0x1019
ExitProcess: dq 0x1026
GetCommandLineA: dq 0x1033
GetStdHandle: dq 0x1044
ReadFile: dq 0x1052
SetFilePointer: dq 0x105C
WriteFile: dq 0x106C
dq 0

; IMPORT DIRECTORY TABLE
dd 0							; Import Lookup Table RVA
dd 0							; Time/Date Stamp
dd 0							; Forwarder Chain
dd 0x1000						; Name RVA
dd 0x1078						; Import Address Table RVA
times 20 db 0

; DATA
stdhandleout dq 0
readfilehandle dq 0
writefilehandle dq 0
writecounter dq 0
stackcounter dq 0
symbolcounter dq 0
readbuffer times 0x500 db 0
writebuffer times 0x500 db 0
symbolbuffer times 0x2000 db 0
logicbuffer times 0x1000 db 0

readfilename db "compile.txt", 0
writefilename db "compile.exe", 0
exefilename db "msl.exe", 0
errorcode1 db "Compile.txt not found", 0
errorcode2 db "Compile.exe not modifiable", 0
errorcode3 db "Invalid syntax", 0

buffer: times 16 db 0

endoftext: times (0x8000-(endoftext-start)) db 0

; CODE
BITS 64
DEFAULT REL

sub rsp, 56						; get stdhandleout for error printing
mov rcx, -11
call [GetStdHandle]
mov [stdhandleout], rax
add rsp, 56

sub rsp, 56						; get read file handle
lea rcx, [readfilename]
mov rdx, 0x80000000
xor r8, r8
xor r9, r9
mov dword [rsp+32], 3
mov dword [rsp+40], 0x80
mov qword [rsp+48], 0
call [CreateFileA]
add rsp, 56
cmp rax, -1
jz error1
mov qword [readfilehandle], rax

sub rsp, 56						; get write file handle
lea rcx, [writefilename]
mov rdx, 0x40000000
xor r8, r8
xor r9, r9
mov dword [rsp+32], 2
mov dword [rsp+40], 0x80
mov qword [rsp+48], 0
call [CreateFileA]
add rsp, 56
cmp rax, -1
jz error2
mov qword [writefilehandle], rax

sub rsp, 56						; get executable handle
lea rcx, [exefilename]
mov rdx, 0x80000000
xor r8, r8
xor r9, r9
mov dword [rsp+32], 3
mov dword [rsp+40], 0x80
mov qword [rsp+48], 0
call [CreateFileA]
add rsp, 56
cmp rax, -1
jz error1

sub rsp, 56+0x1000				; copy PE headers in the stack
mov rcx, rax
lea rdx, [rsp+56]
mov r8, 0x1000
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [ReadFile]

mov rcx, [writefilehandle]		; copy stack to output file
lea rdx, [rsp+56]
mov r8, 0x1000
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [WriteFile]
add rsp, 56+0x1000

xor rbp, rbp					; initialize
xor r12, r12
xor r13, r13
xor r14, r14
mov r15, 0x1000
xor rbp, rbp
xor rsi, rsi
xor rdi, rdi

statement_new:
sub rsp, 56						; write previous statement to output file
mov rcx, [writefilehandle]
lea rdx, [writebuffer]
mov r8, r14
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [WriteFile]
add r15, r14
xor r14, r14

add r12, r13					; move file pointer to next statement
mov rcx, [readfilehandle]
mov rdx, r12
xor r8, r8
xor r9, r9
call [SetFilePointer]
xor r13, r13

mov rcx, [readfilehandle]		; load new statement in readbuffer
lea rdx, [readbuffer]
mov r8, 0x500
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [ReadFile]
mov r8, [rsp+40]
add rsp, 56
test r8, r8
jz exit

xor rcx, rcx					; find end of new statement
xor rdx, rdx
lea rax, [readbuffer]
statement_findend:
inc rdx
cmp rdx, r8						; check if read ended
jz statement_endfound
mov bl, [rax+rdx*1+0]
cmp bl, 92						; quote and blackslash management (92 is backslash, 34 is quote)
jnz statement_nobackslash
btc rcx, 1
jmp statement_findend
statement_nobackslash:
cmp bl, 34
jnz statement_noquote
bt rcx, 1
jnc statement_acceptquote
btr rcx, 1
jmp statement_findend
statement_acceptquote:
btc rcx, 0
statement_noquote:
btr rcx, 1
bt rcx, 0
jc statement_findend
cmp bl, '#'
jz statement_endfound
cmp bl, '@'
jz statement_endfound
cmp bl, '$'
jz statement_endfound
cmp bl, ':'
jz statement_endfound
cmp bl, '?'
jz statement_endfound
jmp statement_findend
statement_endfound:
mov byte [rax+rdx*1+0], 0		; replace statement end with null byte
mov bl, [rax]
lea rcx, [writebuffer]

cmp bl, '#'
jnz nodll
inc r13							; copy dll name in logicbuffer
xor rax, rax
dllname:



nodll:
cmp bl, '@'
jnz noaddress

noaddress:
cmp bl, '$'
jnz nofunction

nofunction:
cmp bl, ':'
jnz nocall

nocall:
cmp bl, '?'
jnz error3



linksymbol:						; links the symbol name pointed by rax (at location rsp) to the symbol table and returns to r8
mov rcx, 5381					; hash the string in rax
movzx rdx, byte [rax]
hash9:
lea rcx, [rcx+rcx*8+0]
add rcx, rdx
inc rax
movzx rdx, byte [rax]
test dl, dl
jnz hash9
and rcx, 0xFF
lea rax, [symbolbuffer]			; find last symbol in respective bucket
lea rcx, [rcx*8]
lea rax, [rax+rcx*4+32]
searchlastsymbol:
mov rcx, [rax+8]
test rcx, rcx
jnz searchlastsymbol
mov rsp, [rax+8]				; link last symbol to rsp
jmp r8

findsymbol:						; returns the address of the symbol whose name is pointed by rax
mov rcx, 5381					; hash the string in rax
movzx rdx, byte [rax]
hash92:
lea rcx, [rcx+rcx*8+0]
add rcx, rdx
inc rax
movzx rdx, byte [rax]
test dl, dl
jnz hash9
and rcx, 0xFF
lea rax, [symbolbuffer]			; find symbol in respective bucket
lea rcx, [rcx*8]
lea rax, [rax+rcx*4+32]
searchsymbol:
mov rcx, [rax-8]
test rcx, rcx
jnz searchsymbol
mov rsp, [rax-8]
jmp r8



exit:							; exit
sub rsp, 56
xor rcx, rcx
call [ExitProcess]

; ERRORS
error1:
sub rsp, 56
mov rcx, [stdhandleout]
lea rdx, [errorcode1]
mov r8, 21
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [WriteFile]
add rsp, 56
jmp exit

error2:
sub rsp, 56
mov rcx, [stdhandleout]
lea rdx, [errorcode2]
mov r8, 26
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [WriteFile]
add rsp, 56
jmp exit

error3:
sub rsp, 56
mov rcx, [stdhandleout]
lea rdx, [errorcode3]
mov r8, 14
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [WriteFile]
add rsp, 56
jmp exit

endofcode: times (0x10000-(endofcode-start)) db 0