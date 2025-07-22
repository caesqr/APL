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
store times 0x1000 db 0
store2 times 0x1000 db 0
readbuffer times 0x500 db 0
writebuffer times 0x500 db 0
registerlist times 16 dq 0
symbollist dq 0
relocationlist dq 0
stdhandleout dq 0
readfilehandle dq 0
writefilehandle dq 0
return dq 0
temp dq 0

exponent32:
dd 1.0
dd 0.1
dd 0.01
dd 0.001
dd 0.0001
dd 0.00001
dd 0.000001
dd 0.0000001
dd 0.00000001
dd 0.000000001
dd 0.0000000001
dd 0.00000000001

exponent64:
dq 1.0
dq 0.1
dq 0.01
dq 0.001
dq 0.0001
dq 0.00001
dq 0.000001
dq 0.0000001
dq 0.00000001
dq 0.000000001
dq 0.0000000001
dq 0.00000000001

table:
dq encodeor
dq encodeand
dq encodebitwiseor
dq encodebitwisexor
dq encodebitwiseand
dq encodeequal
dq encodeunequal
dq encodelesser
dq encodegreater
dq encodelesserequal
dq encodegreaterequal
dq encodeshiftleft
dq encodeshiftright
dq encodeadd
dq encodesubstract
dq encodemultiply
dq encodedivide
dq encodemodulo
dq encodenegation
dq encodenot
dq encodebracket

readfilename db "compile.txt", 0
writefilename db "compile.exe", 0
exefilename db "msl.exe", 0
errorcode1 db "Compile.txt not found", 0
errorcode2 db "Compile.exe not modifiable", 0
errorcode3 db "Invalid syntax", 0
errorcode4 db "Imports must be at the start of the file", 0
errorcode5 db "New addresses must be declared before any function", 0
errorcode6 db "Address does not exist", 0

intbuffer times 30 db 0
intbuffer2 times 30 db 0
intbuffer3 times 30 db 0

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
mov r15, 1000					; (runtime) stack counter

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

lea rsi, [readbuffer]			; initialize read and write addresses and al
mov byte [rsi+rax], 255			; add gibberish to the last read character
lea rdi, [writebuffer]
mov al, [rsi]



cmp al, '@'						; check if dll statement
jnz function
bt rbp, 0
jc error4

dllfirstquote:					; find first quote for dll name
inc rsi
mov al, [rsi]
cmp al, 34
jnz dllfirstquote
lea rbx, [store]				; find last quote while copying the name in store
inc rsi
mov al, [rsi]
dlllastquote:
mov [rbx], al
inc rbx
inc rsi
mov al, [rsi]
cmp al, 34
jnz dlllastquote
lea rcx, [store]				; copy dll name in stack
sub rbx, rcx
sub rsp, rbx
and rsp, -16
xor rdx, rdx
dllstackcopy:
mov al, [rcx+rdx]
mov [rsp+rdx], al
inc rdx
cmp rdx, rbx
jnz dllstackcopy
mov byte [rsp+rdx], 0			; null-terminate stack string
lea r8, [dllcreated]			; create dll symbol
mov [return], r8
jmp createsymbol
dllcreated:						; write symbol description
mov qword [rsp+8], 15

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
lea rbx, [store]				; copy function in store
dllfunction:
mov [rbx], al
inc rbx
inc rsi
mov al, [rsi]
cmp al, 33
jc dllfunctionend
cmp al, 41
jz dllfunctionend
cmp al, 44
jz dllfunctionend
jmp dllfunction
dllfunctionend:
lea rcx, [store]				; copy function name in stack
sub rbx, rcx
sub rsp, rbx
and rsp, -16
xor rdx, rdx
dllfunctionstackcopy:
mov al, [rcx+rdx]
mov [rsp+rdx], al
inc rdx
cmp rdx, rbx
jnz dllfunctionstackcopy
mov byte [rsp+rdx], 0			; null-terminate stack string
lea r8, [dllfunctioncreated]	; create dll symbol
mov [return], r8
jmp createsymbol
dllfunctioncreated:
mov qword [rsp+8], 16			; write symbol description
mov al, [rsi]					; check if there's the last parenthesis
cmp al, 41
jnz dllprefunction
inc rsi
jmp poststatement

function:
cmp bl, '$'
jnz call

call:
cmp bl, ':'
jnz if

if:
cmp bl, '?'
jnz address

address:						; check if address statement
cmp al, 'A'
jc error3
cmp al, 'Z'+1
jc addressvalid
cmp al, 95						; underscore
jz addressvalid
cmp al, 'a'
jc error3
cmp al, 'z'+1
jc addressvalid
jmp error3
addressvalid:
mov rbx, rsi					; save rsi if the destination already exists
lea rcx, [store]
addresscheck:					; check if statement is an initialization by finding non-alphabetical characters
mov [rcx], al
inc rcx
inc rsi
mov al, [rsi]
cmp al, '0'
jc addressupdate
cmp al, '9'+1
jc addresscheck
cmp al, 58
jz addressupdate
cmp al, 'A'
jc addressupdate
cmp al, 'Z'+1
jc addresscheck
cmp al, 91
jz addressinitialization
cmp al, 95
jz addresscheck
cmp al, 'a'
jc addressupdate
cmp al, 'z'+1
jc addresscheck
jmp addressupdate

addressinitialization:			; create new address
mov byte [rcx], 0
sub rbx, rsi					; create new symbol for the destination
neg rbx
sub rsp, rbx
and rsp, -16
lea rbx, [store]
xor rcx, rcx
mov al, [rbx]
addresscopy:					; copy destination name in rsp
mov [rsp+rcx], al
inc rcx
mov al, [rbx+rcx]
test al, al
jnz addresscopy
mov byte [rsp+rcx], 0
lea rax, [addresssymbolcreated]
mov [return], rax
jmp createsymbol
addresssymbolcreated:
xor rbx, rbx
addressgetsize:					; get address size
inc rsi
movzx rax, byte [rsi]
cmp al, 93
jz addressgotsize
lea rbx, [rbx+rbx]
lea rbx, [rbx+rbx*4]
sub al, 48
add rbx, rax
jmp addressgetsize
addressgotsize:
sub r15, rbx					; update symbol
mov qword [rsp+8], r15
inc rsi
jmp poststatement

addressupdate:					; the destination already exists
mov rsi, rbx
lea rax, [addressdestinationdone]
mov [return], rax
jmp arithmetic
addressdestinationdone:

poststatement:					; skip whitespaces
mov al, [rsi]
cmp al, 33
jnc newstatement
inc rsi
jmp poststatement

arithmetic:						; transform the arithmetic sequence at rsi into machine code in rdi, until a character that doesn't make sense is read, then jumps to r11
lea rbx, [store2]				; load store2 index in rbx
xor rcx, rcx					; track priority boost from brackets and parenthesis
mathfirstchar:					; get operand type based on the first character of the operand
mov al, [rsi]
cmp al, 33
jz mathnot
cmp al, 40
jz mathopenparenthesis
cmp al, 41
jz mathclosedparenthesis
cmp al, 45
jz mathnegation
cmp al, 46
jz mathimmediate
cmp al, '0'
jc error3
cmp al, '9'+1
jc mathimmediate
cmp al, 'A'
jc error3
cmp al, 'Z'+1
jc mathaddress
cmp al, 91
jz mathopenbracket
cmp al, 93
jz mathclosedbracket
cmp al, 95
jz mathaddress
cmp al, 'a'
jc error3
cmp al, 'z'+1
jc mathaddress
cmp al, 33						; whitespace
jnc error3
inc rsi
jmp mathfirstchar

mathnot:						; unary !
mov al, [rsi+1]					; check if unary operator preceeds variable or immediate
cmp al, 46
jz mathimmediate
cmp al, '0'
jc mathaddress
cmp al, '9'+1
jc mathimmediate
mathnotvariable:
mov rax, 20
shl rax, 8
add rax, 11
add rax, rcx
mov [rbx], rax
add rbx, 16
inc rsi
jmp mathfirstchar

mathnegation:					; unary -
mov al, [rsi+1]					; check if unary operator preceeds variable or immediate
cmp al, 46
jz mathimmediate
cmp al, '0'
jc mathnegationvariable
cmp al, '9'+1
jc mathimmediate
mathnegationvariable:
mov rax, 19
shl rax, 8
add rax, 11
add rax, rcx
mov [rbx], rax
add rbx, 16
inc rsi
jmp mathfirstchar

mathimmediate:					; immediate as operand
xor r9, r9						; exponent tracker
xor r10, r10					; integer tracker
xor rdx, rdx					; decimal tracker
xor r8, r8						; negative & type tracker
mov al, [rsi]
cmp al, 45						; check if negative
jnz mathimmediatetype
bts r8, 63
inc rsi
mathimmediatetype:				; check prefix zeros for type
inc r8
movzx rax, byte [rsi]
cmp al, '0'
jnz mathimmediateinteger
inc rsi
jmp mathimmediatetype
mathimmediateinteger:			; calculate integer part
movzx rax, byte [rsi]
cmp al, 46
jz mathimmediatedecimaltype
cmp al, '0'
jc mathimmediateintegerend
cmp al, '9'+1
jnc mathimmediateintegerend
lea r10, [r10+r10]
lea r10, [r10+r10*4]
sub al, 48
add r10, rax
inc rsi
jmp mathimmediateinteger
mathimmediatedecimaltype:		; calculate decimal part
add r8, 4
mathimmediatedecimal:
inc rsi
movzx rax, byte [rsi]
cmp al, '0'
jc mathimmediatedecimalend
cmp al, '9'+1
jnc mathimmediatedecimalend
lea rdx, [rdx+rdx]
lea rdx, [rdx+rdx*4]
sub al, 48
add rdx, rax
inc r9
jmp mathimmediatedecimal
mathimmediatedecimalend:		; compile the float
bt r8, 63
jnc mathimmediatedecimalendpositive
neg r10
btr r8, 63
mathimmediatedecimalendpositive:
cmp r8, 6
jz mathimmediatedecimalendfloat32
cvtsi2sd xmm0, r10				; float64
cvtsi2sd xmm1, rdx
lea r10, [exponent64]
movsd xmm2, qword [r10+r8*8]
mulsd xmm1, xmm2
addsd xmm0, xmm1
movsd qword [rbx+8], xmm0
shl r8, 16
mov [rbx], r8
jmp mathoperator
mathimmediatedecimalendfloat32:	; float32
cvtsi2ss xmm0, r10
cvtsi2ss xmm1, rdx
lea r10, [exponent32]
movss xmm2, dword [r10+r8*4]
mulss xmm1, xmm2
addss xmm0, xmm1
movss dword [rbx+8], xmm0
shl r8, 16
mov [rbx], r8
jmp mathoperator
mathimmediateintegerend:		; compile the integer
bt r8, 63
jnc mathimmediateintegerendpositive
neg r10
btr r8, 63
mathimmediateintegerendpositive:
shl r8, 16
mov [rbx], r8
mov [rbx+8], r10
jmp mathoperator

mathaddress:					; address as operand
lea r8, [store]					; copy address in store
mov al, [rsi]
mathaddresscopy:
mov [r8], al
inc r8
inc rsi
mov al, [rsi]
cmp al, '0'
jc mathaddresscopyend
cmp al, '9'+1
jc mathaddresscopy
cmp al, 'A'
jc mathaddresscopyend
cmp al, 'Z'+1
jc mathaddresscopy
cmp al, 95
jz mathaddresscopy
cmp al, 'a'
jc mathaddresscopyend
cmp al, 'z'+1
jc mathaddresscopy
mathaddresscopyend:
mov byte [r8], 0
lea rdx, [store]				; find the symbol of the address
mov rax, [return]
lea r11, [mathaddresssymbolfound]
mov [return], r11
jmp findsymbol
mathaddresssymbolfound:			; check if symbol didn't exist
test rdx, rdx
jz error6
jmp mathoperator

mathopenbracket:				; [
add rcx, 12
mov rax, 21
shl rax, 8
add rax, rcx
mov [rbx], rax
add rbx, 16
inc rsi
jmp mathfirstchar

mathopenparenthesis:			; (
add rcx, 12
inc rsi
jmp mathfirstchar

mathoperator:					; add operator and its priority to the arithmetic entry
mov al, [rsi]
cmp al, '|'
jz mathor
cmp al, '&'
jz mathand
cmp al, '='
jz mathequal
cmp al, '~'
jz mathunequal
cmp al, '<'
jz mathlesser
cmp al, '>'
jz mathgreater
cmp al, '+'
jz mathadd
cmp al, '-'
jz mathsubstract
cmp al, '*'
jz mathmultiply
cmp al, '/'
jz mathdivide
cmp al, '%'
jz mathmodulo
cmp al, ']'
jz mathclosedbracket
cmp al, ')'
jz mathclosedparenthesis
cmp al, 33						; whitespace
jnc encode
inc rsi
jmp mathoperator

mathclosedbracket:				; ]
sub rcx, 12
inc rsi
jmp mathoperator
mathclosedparenthesis:			; )
sub rcx, 12
inc rsi
jmp mathoperator

mathor:							; (1) or
mov al, [rsi+1]
cmp al, '|'
jz mathbitwiseor
cmp al, '&'
jz mathbitwisexor
mov rax, 1
shl rax, 8
add rax, 1
jmp mathoperatorend
mathand:						; (2) and
mov al, [rsi+1]
cmp al, '&'
jz mathbitwiseand
mov rax, 2
shl rax, 8
add rax, 2
jmp mathoperatorend
mathbitwiseor:					; (3) bitwise or
mov rax, 3
shl rax, 8
add rax, 3
inc rsi
jmp mathoperatorend
mathbitwisexor:					; (4) bitwise xor
mov rax, 4
shl rax, 8
add rax, 4
inc rsi
jmp mathoperatorend
mathbitwiseand:					; (5) bitwise and
mov rax, 5
shl rax, 8
add rax, 5
inc rsi
jmp mathoperatorend
mathequal:						; (6) equal
mov rax, 6
shl rax, 8
add rax, 6
jmp mathoperatorend
mathunequal:					; unequal
mov rax, 7
shl rax, 8
add rax, 6
jmp mathoperatorend
mathlesser:						; (7) lesser
mov al, [rsi+1]
cmp al, '='
jz mathlesserorequal
cmp al, '<'
jz mathshiftleft
mov rax, 8
shl rax, 8
add rax, 7
jmp mathoperatorend
mathgreater:					; greater
mov al, [rsi+1]
cmp al, '='
jz mathgreaterorequal
cmp al, '>'
jz mathshiftright
mov rax, 9
shl rax, 8
add rax, 7
jmp mathoperatorend
mathlesserorequal:				; lesser or equal
mov rax, 10
shl rax, 8
add rax, 7
inc rsi
jmp mathoperatorend
mathgreaterorequal:				; greater or equal
mov rax, 11
shl rax, 8
add rax, 7
inc rsi
jmp mathoperatorend
mathshiftleft:					; (8) shift left
mov rax, 12
shl rax, 8
add rax, 8
inc rsi
jmp mathoperatorend
mathshiftright:					; shift right
mov rax, 13
shl rax, 8
add rax, 8
inc rsi
jmp mathoperatorend
mathadd:						; (9) add
mov rax, 14
shl rax, 8
add rax, 9
jmp mathoperatorend
mathsubstract:					; substract
mov rax, 15
shl rax, 8
add rax, 9
jmp mathoperatorend
mathmultiply:					; (10) multiply
mov rax, 16
shl rax, 8
add rax, 10
jmp mathoperatorend
mathdivide:						; divide
mov rax, 17
shl rax, 8
add rax, 10
jmp mathoperatorend
mathmodulo:						; modulo
mov rax, 18
shl rax, 8
add rax, 10
jmp mathoperatorend
mathoperatorend:				; end of operator to avoid repetition of code
add rax, rcx
mov rdx, [rbx]
add rdx, rax
mov [rbx], rdx
add rbx, 16
inc rsi
jmp mathfirstchar

mathends:					; translate arithmetic table to machine code
lea rbx, [store2]
check:
movzx rax, byte [rbx]
mov r8, 10
lea r9, [intbuffer]
loopstring2:
xor rdx, rdx
div r8
add rdx, 48
mov [r9], dl
inc r9
test rax, rax
jnz loopstring2
mov byte [r9], '-'
sub rsp, 48
mov rcx, [stdhandleout]
lea rdx, [intbuffer]
mov r8, 3
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [WriteFile]
add rsp, 48
add rbx, 16
mov rax, [rbx]
test rax, rax
jnz check
jmp exit

encode:							; translate arithmetic table to machine code
mov byte [rbx], 1				; put last arithmetic entry at priority 1
encodestart:
lea rax, [store2-16]
mathfindoperand1:				; get first operand
add rax, 16
mov bl, [rax]
test bl, bl
jz mathfindoperand1
mov rbx, rax
mov cl, [rax]
mathfindoperand2:				; get second operand or go to mathend
add rbx, 16
lea rdx, [store2+0x1000]
cmp rbx, rdx
jz mathend
mov dl, [rbx]
test dl, dl
jz mathfindoperand2
cmp cl, dl						; check if second operand's priority is equal or lower
jc mathfindoperand1
mov cl, [rax+1]					; find encode path with operator

mov qword [rax], 0
mov qword [rax+8], 0

cmp cl, 1
jz encodeor
cmp cl, 2
jz encodeand
cmp cl, 3
jz encodebitwiseor
cmp cl, 4
jz encodebitwisexor
cmp cl, 5
jz encodebitwiseand
cmp cl, 6
jz encodeequal
cmp cl, 7
jz encodeunequal
cmp cl, 8
jz encodelesser
cmp cl, 9
jz encodegreater
cmp cl, 10
jz encodelesserequal
cmp cl, 11
jz encodegreaterequal
cmp cl, 12
jz encodeshiftleft
cmp cl, 13
jz encodeshiftright
cmp cl, 14
jz encodeadd
cmp cl, 15
jz encodesubstract
cmp cl, 16
jz encodemultiply
cmp cl, 17
jz encodedivide
cmp cl, 18
jz encodemodulo
cmp cl, 19
jz encodenegation
cmp cl, 20
jz encodenot
cmp cl, 21
jz encodebracket

encodeor:
mov byte [intbuffer], '|'
jmp here
encodeand:
mov byte [intbuffer], '&'
jmp here
encodebitwiseor:
mov word [intbuffer], '||'
jmp here
encodebitwisexor:
mov word [intbuffer], '|&'
jmp here
encodebitwiseand:
mov word [intbuffer], '&&'
jmp here
encodeequal:
mov byte [intbuffer], '='
jmp here
encodeunequal:
mov byte [intbuffer], '~'
jmp here
encodelesser:
mov byte [intbuffer], '<'
jmp here
encodegreater:
mov byte [intbuffer], '>'
jmp here
encodelesserequal:
mov word [intbuffer], '<='
jmp here
encodegreaterequal:
mov word [intbuffer], '<='
jmp here
encodeshiftleft:
mov word [intbuffer], '<<'
jmp here
encodeshiftright:
mov word [intbuffer], '>>'
jmp here
encodeadd:
mov byte [intbuffer], '+'
jmp here
encodesubstract:
mov byte [intbuffer], '-'
jmp here
encodemultiply:
mov byte [intbuffer], '*'
jmp here
encodedivide:
mov byte [intbuffer], '/'
jmp here
encodemodulo:
mov byte [intbuffer], '%'
jmp here
encodenegation:
mov byte [intbuffer], '-'
jmp here
encodenot:
mov byte [intbuffer], '!'
jmp here
encodebracket:
mov byte [intbuffer], '['
jmp here

here:
mov qword [rax], 0
mov qword [rax+8], 0
sub rsp, 48
mov rcx, [stdhandleout]
lea rdx, [intbuffer]
mov r8, 4
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [WriteFile]
add rsp, 48
jmp encodestart


mathend:
jmp exit

createsymbol:					; links the name pointed by rsp (null-terminated) to the symbol list (new symbol is at rsp, after doing rsp-16) and returns to return
lea r11, [symbollist]
searchlastsymbol:
mov r10, r11
mov r11, [r11]
test r11, r11
jnz searchlastsymbol
sub rsp, 16
mov [r10], rsp
mov qword [rsp], 0
mov r11, [return]
jmp r11

findsymbol:						; returns the address of the symbol with the name pointed by rdx (null-terminated) in rdx and returns to return. if no symbol is found, rdx is 0
lea r11, [symbollist]
searchsymbol:
mov r11, [r11]
test r11, r11
jz symbolnotfound
xor r10, r10
matchsymbolcharacter:
mov r9b, [r11+r10+16]
cmp r9b, byte [rdx+r10]
jnz searchsymbol
inc r10
test r9b, r9b
jnz matchsymbolcharacter
mov rdx, r11
mov r11, [return]
jmp r11
symbolnotfound:
xor rdx, rdx
mov r11, [return]
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

error5:							; new addresses must be declared before any function
sub rsp, 48
mov rcx, [stdhandleout]
lea rdx, [errorcode5]
mov r8, 50
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [WriteFile]
add rsp, 48
jmp exit

error6:							; address does not exist
sub rsp, 48
mov rcx, [stdhandleout]
lea rdx, [errorcode6]
mov r8, 22
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

printsymbolstring:
mov rbx, [symbollist]
printsymbolinit:
mov rcx, rbx
add rcx, 16
lea r8, [intbuffer]
mov al, [rcx]
symbolprintloop:
mov [r8], al
inc r8
inc rcx
mov al, [rcx]
test al, al
jnz symbolprintloop
mov byte [r8], 0
sub rsp, 48
mov rcx, [stdhandleout]
lea rdx, [intbuffer]
mov r8, 30
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [WriteFile]
add rsp, 48
mov rbx, [rbx]
test rbx, rbx
jnz printsymbolinit
jmp exit

printsymboladdress:
mov rbx, [symbollist]
printsymbolinit2:
mov rcx, 10
lea r8, [intbuffer]
mov rax, [rbx+8]
symbolprintloop2:
xor rdx, rdx
div rcx
add rdx, 48
mov [r8], dl
inc r8
test rax, rax
jnz symbolprintloop2
sub rsp, 48
mov rcx, [stdhandleout]
lea rdx, [intbuffer]
mov r8, 30
lea r9, [rsp+40]
mov qword [rsp+32], 0
call [WriteFile]
add rsp, 48
mov rbx, [rbx]
test rbx, rbx
jnz printsymbolinit2
jmp exit

endofcode: times (0x10000-(endofcode-start)) db 0