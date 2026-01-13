; MS-DOS STUB
start: db "MZ"
times 0x3A db 0
dd 0x40							; 0x3c offset
db "PE", 0, 0					; signature

; COFF HEADER
dw 0x8664						; Machine
dw 2							; NumberOfSections
dd 1749503318					; TimeDateStamp
dd 0							; PointerToSymbolTable
dd 0							; NumberOfSymbols
dw 0xF0							; SizeOfOptionalHeader
dw 0x222						; Characteristics

; OPTIONAL HEADER
dw 0x20B						; Magic
db 0							; MajorLinkerVersion
db 0							; MinorLinkerVersion
dd 0x1000						; SizeOfCode
dd 0x1000						; SizeOfInitializedData
dd 0							; SizeOfUninitializedData
dd 0x2000						; AddressOfEntryPoint
dd 0x2000						; BaseOfCode

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
dd 0x3000						; SizeOfImage
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
dd 0x1093						; import table RVA
dd 0							; import table size
times 14 dq 0					; other tables

; SECTION HEADERS
dq ".text"						; Name
dd 0x1000						; VirtualSize
dd 0x1000						; VirtualAddress
dd 0x1000						; SizeOfRawData
dd 0x1000						; PointerToRawData
dd 0							; PointerToRelocations
dd 0							; PointerToLineNumbers
dw 0							; NumberOfRelocations
dw 0							; NumberOfLineNumbers
dd 0xC0000040					; Characteristics

dq ".code"						; Name
dd 0x1000						; VirtualSize
dd 0x2000						; VirtualAddress
dd 0x1000						; SizeOfRawData
dd 0x2000						; PointerToRawData
dd 0							; PointerToRelocations
dd 0							; PointerToLineNumbers
dw 0							; NumberOfRelocations
dw 0							; NumberOfLineNumbers
dd 0x60000020					; Characteristics

endofheader: times (0x1000-(endofheader-start)) db 0

; TEXT

; DLL AND FUNCTION NAMES
db "kernel32.dll"
db 0, 0, "CreateFileA"
db 0, 0, "ExitProcess"
db 0, 0, "GetCommandLineA"
db 0, 0, "GetStdHandle"
db 0, 0, "ReadFile"
db 0, 0, "WriteFile", 0

; IMPORT ADDRESS TABLE
CreateFileA: dq 0x100C
ExitProcess: dq 0x1019
GetCommandLineA: dq 0x1026
GetStdHandle: dq 0x1037
ReadFile: dq 0x1045
WriteFile: dq 0x104F
dq 0

; IMPORT DIRECTORY TABLE
dd 0							; Import Lookup Table RVA
dd 0							; Time/Date Stamp
dd 0							; Forwarder Chain
dd 0x1000						; Name RVA
dd 0x105B						; Import Address Table RVA
times 20 db 0

; DATA
filename db "file.txt", 0
buffer times 256 db 0

endoftext: times (0x2000-(endoftext-start)) db 0

; CODE
BITS 64
DEFAULT REL

; READ CONSOLE
sub rsp, 56
call [GetCommandLineA]

mov rbx, rax
STRING:
mov cl, [rax]
inc rax
test cl, cl
jnz STRING
sub rax, rbx
mov rbp, rax
dec rbp

; WRITE CONSOLE
lea rcx, [filename]				; lpFileName
mov edx, 0x40000000				; dwDesiredAccess
xor r8d, r8d					; dwShareMode
xor r9d, r9d					; lpSecurityAttributes
mov dword [rsp+32], 2			; dwCreationDisposition
mov dword [rsp+40], 0x80		; dwFlagsAndAttributes
mov qword [rsp+48], 0			; hTemplateFile
call [CreateFileA]

mov rcx, rax					; hFile
mov rdx, rbx					; lpBuffer
mov r8, rbp						; nNumberOfBytesToWrite
lea r9, [rsp+40]				; lpNumberOfBytesWritten
mov qword [rsp+32], 0			; lpOverlapped
call [WriteFile]

xor ecx, ecx
call [ExitProcess]


endofcode: times (0x3000-(endofcode-start)) db 0
