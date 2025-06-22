BITS 64
DEFAULT REL

; MS-DOS STUB
start: 	db "MZ"
times 0x3A db 0
dd 0x40					; 0x3c offset
db "PE", 0, 0			; signature

; COFF HEADER
dw 0x8664				; Machine
dw 2					; NumberOfSections
dd 1749503318			; TimeDateStamp
dd 0					; PointerToSymbolTable
dd 0					; NumberOfSymbols
dw 0xF0					; SizeOfOptionalHeader
dw 0x222				; Characteristics

; OPTIONAL HEADER
dw 0x20B				; Magic
db 0					; MajorLinkerVersion
db 0					; MinorLinkerVersion
dd 0x1000				; SizeOfCode
dd 0x1000				; SizeOfInitializedData
dd 0					; SizeOfUninitializedData
dd 0x2000				; AddressOfEntryPoint
dd 0x2000				; BaseOfCode

dq 0x140000000			; ImageBase
dd 0x1000				; SectionAlignment 
dd 0x200				; FileAlignment
dw 6					; MajorOperatingSystemVersion
dw 0					; MinorOperatingSystemVersion
dw 0					; MajorImageVersion
dw 0					; MinorImageVersion
dw 6					; MajorSubsystemVersion
dw 0					; MinorSubsystemVersion
dd 0					; Win32VersionValue
dd 0x3000				; SizeOfImage
dd 0x1000				; SizeOfHeaders
dd 0					; CheckSum
dw 3					; Subsystem
dw 0x8160				; DllCharacteristics
dq 0x100000				; SizeOfStackReserve
dq 0x1000				; SizeOfStackCommit
dq 0x100000				; SizeOfHeapReserve
dq 0x1000				; SizeOfHeapCommit
dd 0					; LoaderFlags
dd 16					; NumberOfRVAAndSizes

dq 0					; export table
dd 0x1000				; import table RVA
dd 0xA4					; import table size
times 10 dq 0
dd 0x1058				; import address table RVA
dd 0x20					; import address table size
times 3 dq 0

; SECTION HEADERS
dq ".text"				; Name
dd 0x1000				; VirtualSize
dd 0x1000				; VirtualAddress
dd 0x1000				; SizeOfRawData
dd 0x1000				; PointerToRawData
dd 0					; PointerToRelocations
dd 0					; PointerToLineNumbers
dw 0					; NumberOfRelocations
dw 0					; NumberOfLineNumbers
dd 0xC0000040			; Characteristics

dq ".code"				; Name
dd 0x1000				; VirtualSize
dd 0x2000				; VirtualAddress
dd 0x1000				; SizeOfRawData
dd 0x2000				; PointerToRawData
dd 0					; PointerToRelocations
dd 0					; PointerToLineNumbers
dw 0					; NumberOfRelocations
dw 0					; NumberOfLineNumbers
dd 0x60000020			; Characteristics

endofheader: times (0x1000-(endofheader-start)) db 0

; TEXT
; IMPORT DIRECTORY TABLE
dd 0x1038				; Import Lookup Table RVA
dd 0					; Time/Date Stamp
dd 0					; Forwarder Chain
dd 0x1028				; Name RVA
dd 0x1058				; Import Address Table RVA
times 20 db 0

; NAME RVA
db "kernel32.dll", 0, 0, 0, 0

; IMPORT LOOKUP TABLE
dq 0x1078				; GetStdHandle
dq 0x1088				; WriteFile
dq 0x1094				; ExitProcess
dq 0

; IMPORT ADDRESS TABLE
GetStdHandle: dq 0x1078	; GetStdHandle
WriteFile: dq 0x1088	; WriteFile
ExitProcess: dq 0x1094	; ExitProcess
dq 0

; HINT/NAME TABLE
dw 0					; GetStdHandle
db "GetStdHandle", 0, 0
dw 0					; WriteFile
db "WriteFile", 0
dw 0					; ExitProcess
db "ExitProcess", 0

; DATA
endoftext: times (0x2000-(endoftext-start)) db 0

; CODE
; TRANSFORM RSP TO STRING
mov rax, rsp
sub rsp, 24
mov ebx, 10
mov ecx, 24
divide1:
xor edx, edx
div rbx
add edx, "0"
mov [rsp+rcx], dl
sub ecx, 1
test rax, rax
jnz divide1
xor ebx, ebx
shift:
add ecx, 1
mov al, [rsp+rcx]
mov [rsp+rbx], al
add ebx, 1
cmp ecx, 24
jnz shift
push 0

; PRINT RSP STRING
sub rsp, 32
mov ecx, -11
call [GetStdHandle]
add rsp, 32
mov rcx, rax
lea rdx, [rsp+8]
mov r8d, ebx
push 0
lea r9, [rsp]
push 0
sub rsp, 32
call [WriteFile]
add rsp, 48

wat: jmp wat

endofcode: times (0x3000-(endofcode-start)) db 0