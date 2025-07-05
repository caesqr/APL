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
buffer1 times 0x1000 db 0
buffer2 times 0x1000 db 0
buffer3 times 0x4000 db 0

readfilename db "compile.txt", 0
writefilename db "compile.exe", 0
exefilename db "msl.exe", 0
errorcode1 db "Compile.txt not found", 0
errorcode2 db "Compile.exe not modifiable", 0
errorcode3 db "Invalid syntax", 0

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

sub rsp, 56						; copy PE headers in buffer2
mov rcx, rax
lea rdx, [buffer2]
mov r8, 0x1000
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [ReadFile]
add rsp, 56

xor r12, r12					; initialize
mov r14, 0x1000
xor r15, r15

readloop:						; update buffer1
mov r13, -1
sub rsp, 56
mov qword rcx, [readfilehandle]
lea rdx, [buffer1]
mov r8, 0x1000
lea r9, [rsp+40]
mov qword [rsp+32], 0
mov r10, 0x1000
call [ReadFile]
mov r15, [rsp+40]
add rsp, 56

decodeloop:						; find decode path of each statement
test r15, r15					; check if bytes read is 0
jz writeloop
cmp r14, 0xC00					; check if write is needed
jnc writeloop
inc r13
cmp r13, r15					; check if read buffer needs to update
jz readloop
lea r8, [buffer1]
add r8, r13
mov bl, [r8]
cmp rbp, 1						; check if dlllogic is processing
jz dlllogic
cmp bl, 33						; check if whitespace
jc decodeloop
cmp bl, '#'						; check if dll
jz dlllogic
cmp bl, '['						; check if label
jz labellogic
cmp bl, '?'						; check if if statement
jz iflogic
cmp bl, 'A'						; check if function
jc error3
cmp bl, 91
jc functionlogic
cmp bl, 'a'
jc error3
cmp bl, 123
jc functionlogic
jmp error3

dlllogic:						; dll logic
lea rdi, [buffer2]
mov [rdi+r14*1+0], bl
inc r14
mov rbp, 1
jmp decodeloop

labellogic:						; label logic

iflogic:						; if statement logic

functionlogic:					; function logic

writeloop:						; write buffer2 to file
cmp r14, 0
jz exit
sub rsp, 56
mov rcx, [writefilehandle]
lea rdx, [buffer2]
mov r8, r14
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [WriteFile]
add rsp, 56
mov rax, [writecounter]
add rax, r14
mov qword [writecounter], rax
xor r14, r14
jmp decodeloop


; EXIT
exit:
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