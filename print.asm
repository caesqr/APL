BITS 64
DEFAULT REL

start:

; MS-DOS STUB
db "MZ"
times 0x3A db 0
dd 0x40					; 0x3c offset
dd "PE"					; signature

; COFF HEADER
dw 0x8664				; Machine
dw 2					; NumberOfSections
dd 1749503318			; TimeDateStamp
dq 0					; PointerToSymbolTable
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
dw 0					; MajorOperatingSystemVersion
dw 0					; MinorOperatingSystemVersion
dw 0					; MajorImageVersion
dw 0					; MinorImageVersion
dw 6					; MajorSubsystemVersion
dw 0					; MinorSubsystemVersion
dd 0					; Win32VersionValue
dd 0x3000				; SizeOfImage
dd 0x400				; SizeOfHeaders
dd 0					; CheckSum
dw 3					; Subsystem
dw 0					; DllCharacteristics
dq 0x100000				; SizeOfStackReserve
dq 0x1000				; SizeOfStackCommit
dq 0					; SizeOfHeapReserve
dq 0					; SizeOfHeapCommit
dd 0					; LoaderFlags
dd 16					; NumberOfRVAAndSizes

; DATA DIRECTORIES
dq 0					; export table
dd 0x1000				; import table RVA
dd 0x100				; import table size
times 14 dq 0			; other tables

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
dd 0x40000040			; Characteristics

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
dd 0x1028				; Import Lookup Table RVA
dd 0					; Time/Date Stamp
dd 0					; Forwarder Chain
dd 0x108A				; Name RVA
dd 0x1072				; Import Address Table RVA
times 20 db 0
; IMPORT LOOKUP TABLE
dq 0x104A				; GetStdHandle
dq 0x105A				; WriteFile
dq 0x1066				; ExitProcess
dq 0
; HINT/NAME TABLE
dw 0					; GetStdHandle
db "GetStdHandle", 0, 0
dw 0					; WriteFile
db "WriteFile", 0
dw 0					; ExitProcess
db "ExitProcess", 0
; IMPORT ADDRESS TABLE
GetStdHandle: dq 0
WriteFile: dq 0
ExitProcess: dq 0
; NAME RVA
db "kernel32.dll", 0, 0

endoftext: times (0x2000-(endoftext-start)) db 0

; CODE
sub rsp, 40
mov ecx, 0
call [ExitProcess]

endofcode: times (0x3000-(endofcode-start)) db 0