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
readbuffer times 0x500 db 0
writebuffer times 0x500 db 0
symbolbuffer times 0x800 db 0
store times 0x1000 db 0

readfilename db "compile.txt", 0
writefilename db "compile.exe", 0
exefilename db "msl.exe", 0
errorcode1 db "Compile.txt not found", 0
errorcode2 db "Compile.exe not modifiable", 0
errorcode3 db "Invalid syntax", 0
errorcode4 db "Imports must be at the start of the file", 0

intbuffer times 30 db 0



endoftext: times (0x8000-(endoftext-start)) db 0

; CODE
BITS 64
DEFAULT REL
sub rsp, 8

sub rsp, 64						; get stdhandleout for error printing
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
cmp rax, -1
jz error1
mov qword [readfilehandle], rax

lea rcx, [writefilename]		; get write file handle
mov rdx, 0x40000000
xor r8, r8
xor r9, r9
mov dword [rsp+32], 2
mov dword [rsp+40], 0x80
mov qword [rsp+48], 0
call [CreateFileA]
cmp rax, -1
jz error2
mov qword [writefilehandle], rax

lea rcx, [exefilename]			; get executable handle
mov rdx, 0x80000000
xor r8, r8
xor r9, r9
mov dword [rsp+32], 3
mov dword [rsp+40], 0x80
mov qword [rsp+48], 0
call [CreateFileA]
cmp rax, -1
jz error1
add rsp, 64

sub rsp, 64+0x1000				; copy PE headers in the stack
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
add rsp, 64+0x1000



lea rsi, [readbuffer]			; initialize
lea rdi, [writebuffer]
xor rbp, rbp					; status flags
xor r12, r12					; read bytes
xor r13, r13					; written bytes
xor r14, r14					; (runtime) register cycle
xor r15, r15					; (runtime) stack counter

newstatement:
sub rsp, 48						; write previous statement to output file
mov rcx, [writefilehandle]
lea rdx, [writebuffer]
mov r8, rdi
sub r8, rdx
add r13, r8
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [WriteFile]

mov rcx, [readfilehandle]		; move file pointer to next statement
mov rax, rsi
lea rbx, [readbuffer]
sub rax, rbx
add r12, rax
mov rdx, r12
xor r8, r8
xor r9, r9
call [SetFilePointer]

mov rcx, [readfilehandle]		; load new statement in readbuffer
lea rdx, [readbuffer]
mov r8, 0x4FF
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [ReadFile]
mov eax, [rsp+40]
add rsp, 48
test rax, rax
jz exit

lea rsi, [readbuffer]			; initialize read and write addresses and character register
mov byte [rsi+rax], 0			; null-terminate readbuffer
lea rdi, [writebuffer]
mov al, [rsi]



cmp al, '#'						; check if dll statement
jnz nodll
bt rbp, 0
jc error4

dllfirstquote:					; find first quote for dll name
inc rsi
mov al, [rsi]
cmp al, 34
jnz dllfirstquote
inc rsi							; find last quote while copying the name in writebuffer
mov al, [rsi]
mov rbx, rdi					; save current write position to copy the string in the stack later
dlllastquote:
mov [rdi], al
inc rdi
inc rsi
mov al, [rsi]
cmp al, 34
jnz dlllastquote
mov rdx, rdi					; copy dll name in stack
sub rdx, rbx
sub rsp, rdx
and rsp, -16
xor rcx, rcx
dllstackcopy:
mov al, [rbx+rcx]
mov [rsp+rcx], al
inc rcx
cmp rcx, rdx
jnz dllstackcopy
mov byte [rsp+rcx], 0			; null-terminate stack string
lea r11, [dllcreated]			; create dll symbol
jmp createsymbol
dllcreated:						; make symbol description
mov rax, 15						; type field is 15 for dll
mov rbx, r13					; stack/code address field is written bytes (r13)
shl rbx, 32
and rax, rbx
mov [rsp+8], rax

dllopenparenthesis:				; find open parenthesis
inc rsi
mov al, [rsi]
cmp al, 40
jnz dllopenparenthesis
dllprefunction:					; find function name by skipping whitespaces and commas
inc rsi
mov al, [rsi]
cmp al, 33
jc dllprefunction
cmp al, 44
jz dllprefunction
mov word [rdi], 0				; add function to writebuffer
add rdi, 2
mov rbx, rdi					; save rdi to put in stack/code address field and copy function to stack later
mov al, [rsi]
dllfunction:
mov [rdi], al
inc rsi
inc rdi
mov al, [rsi]
cmp al, 33
jc dllfunctionend
cmp al, 41
jz dllfunctionend
cmp al, 44
jz dllfunctionend
jmp dllfunction
dllfunctionend:
mov rdx, rdi					; copy the function name in stack
sub rdx, rbx
sub rsp, rdx
and rsp, -16
xor rcx, rcx
dllfunctionstackcopy:
mov al, [rbx+rcx]
mov [rsp+rcx], al
inc rcx
cmp rcx, rdx
jnz dllfunctionstackcopy
lea r11, [dllfunctioncreated]
jmp createsymbol
dllfunctioncreated:				; make symbol description
mov rax, 16						; type field is 16 for dllfunctions
sub rbx, 2						; stack/code address field is written bytes (r13) plus relative position in writebuffer
lea rcx, [writebuffer]
sub rbx, rcx
add rbx, r13
sub rbx, 2
shl rbx, 32
and rax, rbx
mov [rsp+8], rax
mov al, [rsi]					; check if there's the last parenthesis
cmp al, 41
jnz dllprefunction
mov byte [rdi], 0				; null-terminate last function name
inc rdi

dllnextstatement:				; go to next statement after dll statement
inc rsi
mov al, [rsi]
test al, al
jz newstatement
cmp al, 33
jc dllnextstatement
cmp al, 35
jz newstatement
								; next statement is not a dll statement (to be continued)
jmp newstatement
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

createsymbol:					; links the symbol name pointed by rsp to the symbol table (new symbol is at rsp, after doing rsp-32) and returns to r11
mov r10, rsp
mov r9, 5381					; hash the string in r10
movzx r8, byte [r10]
hash9:
lea r9, [r9+r9*8+0]
add r9, r8
inc r10
movzx r8, byte [r10]
test r8, r8
jnz hash9
and r9, 0xFF
lea r10, [symbolbuffer]			; find last symbol in respective bucket
lea r10, [r10+r9*8+0]
searchlastsymbol:
mov r9, r10
mov r10, [r10]
test r10, r10
jnz searchlastsymbol
sub rsp, 16						; create new symbol and link to last symbol
mov [r9], rsp
mov qword [rsp], 0
jmp r11

exit:							; exit
sub rsp, 32
xor rcx, rcx
call [ExitProcess]

error1:							; compile.txt not found
sub rsp, 48
mov rcx, [stdhandleout]
lea rdx, [errorcode1]
mov r8, 21
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [WriteFile]
add rsp, 48
jmp exit

error2:							; compile.txt not modifiable
sub rsp, 48
mov rcx, [stdhandleout]
lea rdx, [errorcode2]
mov r8, 26
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [WriteFile]
add rsp, 48
jmp exit

error3:							; invalid syntax
sub rsp, 48
mov rcx, [stdhandleout]
lea rdx, [errorcode3]
mov r8, 14
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [WriteFile]
add rsp, 48
jmp exit

error4:							; imports must be at the start of the file
sub rsp, 48
mov rcx, [stdhandleout]
lea rdx, [errorcode4]
mov r8, 40
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [WriteFile]
add rsp, 48
jmp exit

intstring:						; debug!!
mov rbx, 10
lea rcx, [intbuffer]
loopstring:
xor rdx, rdx
div rbx
add rdx, 48
mov [rcx], dl
inc rcx
test rax, rax
jnz loopstring
sub rsp, 48
mov rcx, [stdhandleout]
lea rdx, [intbuffer]
mov r8, 30
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [WriteFile]
add rsp, 48
jmp exit

endofcode: times (0x10000-(endofcode-start)) db 0