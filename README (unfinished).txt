MSL, modern syntaxic language, is an assembly language that's centered around interpreting symbols (non-alphanumerical characters) as x86-64 instructions, which are bundled in a ready Windows executable. as for the MSL instruction set, I retained the most useful and performant instructions from the x86-64 Intel instruction set. despite this reduction, most developer needs are still covered

the file to compile must be named "compile.txt" and must share the parent directory of the MSL compiler. to compile, open command prompt, navigate to the parent directory, and run "msl.exe". an executable named "compile.exe" will appear

--- OFFICIAL GUIDE ---
all code interpreted by msl.exe follow this format: [non-alphanumerical symbol(s)][operand(s)] (no spaces unless between two operands of the same symbol)
below are the definitions of possible operands:
a: address - a letter (uppercase or lowercase) followed by alphanumerical characters. addresses are case sensitive
n: number - a decimal (50), hexadecimal (0x32) or binary (0b110010) integer, or a float (50.0)
r: register - a digit or uppercase letter (0-7, A-H) representing one of the sixteen 64-bit registers
s: string - a double-quote followed by any characters, followed by a double-quote. to have a double-quote in the character sequence, write it twice

below is the structure of the code inside "compile.txt". there are 4 sections: DLL imports, initialized data, uninitialized data and code. a section ends when a symbol from the next section is detected. the compiler will not misinterpretate the same symbol across different sections. all symbols inside the same section can appear in any order

symbol			operand			name - description
DLL IMPORTS
$				a a..			import - import DLL a (first one) with its functions a.. (separated by spaces)

INITIALIZED DATA
#				a n/s..			initialize - in order, write the numbers n and strings s in the initialized section of the executable. address a marks the beginning of that data. positive integers will take the smallest representable size between 1, 4 and 8 bytes. negative integers are limited to 4 and 8 bytes. all floats are 4 bytes. strings will not have padding after their end
#				a `n n/s..		initialize and repeat - do the same thing as above, except the number after the tilde (`) is how many times the data should be repeated

UNINITIALIZED DATA
^				a n				uninitialize - allocate n bytes of space after the initialized section. address a marks the beginning of that space

CODE, special symbols (these symbols are not encoded, so using them does not slow down the final executable)
[				r				main register change (MR) - change the compiler's implicit "main" register. because most x86-64 instructions target two registers, MSL will use the main register and a written register as targets
#				a				address declaration - assign the current code address (or location) to the address a, which can be used later

CODE, base symbols
+				n				add - add number n (8/32-bit) to MR
+'				r				addr - add register r to MR
&				n				and - bitwise AND with number n (8/32-bit) and MR
&'				r				andr - bitwise AND with register r and MR
$				a				dll call - call the dll function a that was declared in the DLL imports section
$#				a				code call - call the code address a
?/'				r				move if above - move register r to MR if a prior comparison is greater (unsigned)
?/='			r				move if above equal - move register r to MR if a prior comparison is greater-or-equal (unsigned)
?\'				r				move if below - move register r to MR if a prior comparison is lesser (unsigned)
?\='			r				move if below equal - move register r to MR if a prior comparison is lesser-equal (unsigned)
?>'				r				move if greater - move register r to MR if a prior comparison is greater (signed)
?>='			r				move if greater equal - move register r to MR if a prior comparison is greater-or-equal (signed)
?<'				r				move if below - move register r to MR if a prior comparison is lesser (signed)
?<='			r				move if below equal - move register r to MR if a prior comparison is lesser-equal (signed)
?~'				r				move if unequal - move register r to MR if a prior comparison is unequal
?='				r				move if equal - move register r to MR if a prior comparison is equal

W 0F BC /r						bsf				`<'		r		1 0xBC0FC0 /
W 0F BD /r						bsr				`>'		r		1 0xBD0FC0 /
W 0F BA /4 imm8					bt				`.		n		0 0xBA0FE4

W 0F 4F /r						cmovg			?>'		r		1 0x4F0FC0 /
W 0F 4D /r						cmovge			?>='	r		1 0x4D0FC0 /
W 0F 4C /r						cmovl			?<'		r		1 0x4C0FC0 /
W 0F 4E /r						cmovle			?<='	r		1 0x4E0FC0 /


W 0F 45 /r						cmovnz			?~'		r		1 0x450FC0 /
W 0F 44 /r						cmovz			?='		r		1 0x440FC0 /
W 83 /7 imm8					cmp				~		n		0 0x8387 /
W 81 /7 imm32									~		n		0 0x8387 /
W 3B /r											~'		r		1 0x3B80 /
0F A2							cpuid			`#		[*]		. /
W F7 /6							div				`/		[*]		2 0xF786 /
W F7 /7							idiv			/		[*]		2 0xF787 /
W 6B /r imm8					imul			*		n		0 0x6B90 /
W 69 /r imm32									*		n		0 0x6B90 /
W 0F AF /r										*'		r		1 0xAF0FC0 /
0F 87 disp32					ja				@/		a		3 0x870F80 /
0F 83 disp32					jae				@/=		a		3 0x830F80 /
0F 82 disp32					jb				@\		a		3 0x820F80 /
0F 86 disp32					jbe				@\=		a		3 0x860F80 /
0F 8F disp32					jg				@>		a		3 0x8F0F80 /
0F 8D disp32					jge				@>=		a		3 0x8D0F80 /
0F 8C disp32					jl				@<		a		3 0x8C0F80 /
0F 8E disp32					jle				@<=		a		3 0x8E0F80 /
E9 disp32						jmp				@		a		3 0xE900 /
FF /4											@'		r		2 0xFF04 /
0F 85 disp32					jnz				@~		a		3 0x850F80 /
0F 84 disp32					jz				@=		a		3 0x840F80 /
W 8D /r							lea				`=		r+		4 0x8D80 / `=5'68,32 5'68 5,32
W F7 /4							mul				`*		[*]		2 0xF784 /
W B8+rd imm64					mov				=		n		. /
W C7 /0 imm32 (signed)							=		n		. /
C7 /0 imm32 (unsigned)							=		n		. /
W 8B /r (r, r)									='		r		1 0x8B80 /
W 89 /r (r/m, r)								:		r+		4 0x8980 /
89 /r											::		r+		4 0x8900 /
66 89 /r										:::		r+		4 0x896640 /
88 /r											::::	r+		4 0x8800 /
W 8B /r (r, r/m)								.		r+		4 0x8B80 /
8B /r											..		r+		4 0x8B00 /
W 0F BF /r (16)					movsx			..,		r+		4 0xBF0FC0 /
W 0F BE /r (8)									...,	r+		4 0xBE0FC0 /
W 63 /r							movsxd			.,		r+		4 0x6380 /
0F B7 /r (16)					movzx			...		r+		4 0xB70F40 /
0F B6 /r (8)									....	r+		4 0xB60F40 /
W F7 /3							neg				!!		[*]		2 0xF783 /
W F7 /2							not				!		[*]		2 0xF782 /
W 83 /1 imm8					or				|		n		0 0x8381 /
W 81 /1 imm32									|		n		0 0x8381 /
W 0B /r											|'		r		1 0x0B80 /
0F 01 F9						rdtscp			`%		[*]		. /
F3 A4							rep movsb		`"		[*]		. /
C3								ret				`$		[*]		. /
W C1 /0 imm8					rol				<<		n		0 0xC1A0 /
W D3 /0											<<'		[*]		2 0xD380 /
C1 /0 imm8										<<<		n		0 0xC120 /
D3 /0											<<<'	[*]		2 0xD300 /
W C1 /1 imm8					ror				>>		n		0 0xC1A1 /
W D3 /1											>>'		[*]		2 0xD381 /
C1 /1 imm8										>>>		n		0 0xC121 /
D3 /1											>>>'	[*]		2 0xD300 /
W C1 /7 imm8					sar				>-		n		0 0xC1A7 /
W D3 /7											>-'		[*]		2 0xD387 /
0F 97 /0						seta			?/		[*]		2 0x970F40 /
0F 93 /0						setae			?/=		[*]		2 0x930F40 /
0F 92 /0						setb			?\		[*]		2 0x920F40 /
0F 96 /0						setbe			?\=		[*]		2 0x960F40 /
0F 9F /0						setg			?>		[*]		2 0x9F0F40 /
0F 9D /0						setge			?>=		[*]		2 0x9D0F40 /
0F 9C /0						setl			?<		[*]		2 0x9C0F40 /
0F 9E /0						setle			?<=		[*]		2 0x9E0F40 /
0F 95 /0						setnz			?~		[*]		2 0x950F40 /
0F 94 /0						setz			?=		[*]		2 0x940F40 /
W C1 /4 imm8					shl				<		n		0 0xC1A4 /
W D3 /4											<'		[*]		2 0xD384 /
W C1 /5 imm8					shr				>		n		0 0xC1A5 /
W D3 /5											>'		[*]		2 0xD385 /
W 83 /5 imm8					sub				-		n		0 0x8385 /
W 81 /5 imm32									-		n		0 0x8385 /
W 2B /r											-'		r		1 0x2B80 /
W 85 /r							test			`~		[*]		2 0x85A0 /
W 83 /6 imm8					xor				^		n		0 0x8386 /
W 81 /6 imm32									^		n		0 0x8386 /
W 33 /r											^'		r		1 0x3380 /
33 /r											`^		r		2 0x3320 /

--- AVX --- (default: m-mmmm=00001, W=0, vvvv=1111, L=1, pp=00)
V 58 /r							vaddps
V 5B /r							vcvtdq2ps
V.p10 5B /r						vcvttps2dq
V 5E /r							vdivps
V 5F /r							vmaxps 2
V 5D /r							vminps 2
V 10 /r (ymm, y/m)				vmovups
V 11 /r (y/m, ymm)
V 59 /r							vmulps
V 53 /r							vrcpps 2
V 52 /r							vrsqrtps 2
V 51 /r							vsqrtps 2
V 5C /r							vsubps
V 2E /r							vucomiss 2
V.L 77							vzeroupper 0

--- AVX2 --- (default: m-mmmm=00001, W=0, vvvv=1111, L=1, pp=01)
V.m10 1C /r						vpabsb
V.m10 1D /r						vpabsw
V.m10 1E /r						vpabsd
V FC /r							vpaddb
V FE /r							vpaddd
V FD /r							vpaddw
V DB /r							vpand
V DF /r							vpandn
V.m10 58 /r						vpbroadcastd
V 74 /r							vpcmpeqb
V 75 /r							vpcmpeqw
V 76 /r							vpcmpeqd
V 64 /r							vpcmpgtb
V 65 /r							vpcmpgtw
V 66 /r							vpcmpgtd
V.m11 46 /r imm8				vperm2i128
V.m10 3C /r						vpmaxsb
V.m10 3D /r						vpmaxsd
V EE /r							vpmaxsw
V DE /r							vpmaxub
V.m10 3F /r						vpmaxud
V.m10 3E /r						vpmaxuw
V.m10 38 /r						vpminsb
V.m10 39 /r						vpminsd
V EA /r							vpminsw
V DA /r							vpminub
V.m10 3A /r						vpminuw
V.m10 3B /r						vpminud
V.m10 40 /r						vpmulld
V D5 /r							vpmullw
V D7 /r							vpmovmskb
V EB /r							vpor
V 70 /r imm8					vpshufd
V 72 /6 imm8					vpslld
V 73 /7 imm8					vpslldq
V 71 /6 imm8					vpsllw
V 72 /2 imm8					vpsrld
V 73 /3 imm8					vpsrldq
V 71 /2 imm8					vpsrlw
V F8 /r							vpsubb
V FA /r							vpsubd
V F9 /r							vpsubw
V 68 /r							vpunpckhbw
V 69 /r							vpunpckhwd
V 60 /r							vpunpcklbw
V 61 /r							vpunpcklwd
V EF /r							vpxor