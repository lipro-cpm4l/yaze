#!/usr/bin/env perl

use strict;				# avoid unexpected bugs
use warnings;				# avoid unclean code


#-----------------------------------------------------------------------------
#---------------------  Command Line Options / Parsing  ----------------------

# sudo apt-get install perl-doc
use Getopt::Long qw(GetOptions);	# support options+arguments
use Pod::Usage qw(pod2usage);		# avoid redundant &Usage()

my $opt_all	= 0;	# all instead of documnted instructions only
my $opt_rand	= 0;	# randomises the initial machine states
my $opt_zmac	= 0;	# generate zmac compatible assembler mnemonic
my $opt_msgl	= 30;	# default length of the test case message string
my ($opt_help, $opt_man, $opt_versions);

my @opt_argv	= @ARGV;
GetOptions(
	'all!'		=> \$opt_all,
	'help!'		=> \$opt_help,
	'man!'		=> \$opt_man,
	'msgl=i'	=> \$opt_msgl,
	'rand!'		=> \$opt_rand,
	'versions!'	=> \$opt_versions,
	'zmac!'		=> \$opt_zmac,
) or pod2usage(-output  => \*STDERR, -verbose => 1) && exit;

pod2usage(-verbose => 1) && exit if defined $opt_help;
pod2usage(-verbose => 2) && exit if defined $opt_man;


#-----------------------------------------------------------------------------
#----------------  Z80Exer Package Definitions / INIT / END  -----------------

package Z80Exer;

use vars qw($version $cmdline);
$version	= '0.00.01';
$cmdline	= "$0 @opt_argv";	# save command line for later usage

use vars qw($all $rand $zmac $msgl $vers);	# runtime options
use vars qw($z80exer);				# assembler output

INIT {
	# sudo apt-get install libinline-files-perl
	use Inline::Files;		# support inline template filehandle
	open TMPL or die $!;		# open inline template
}

END {
	print $z80exer unless not defined $z80exer;
	if (defined $vers) {
		print	";\n",
			"; Modules, Perl, OS, Program info:\n",
			";   Getopt::Long    $Getopt::Long::VERSION\n",
			";   Pod::Usage      $Pod::Usage::VERSION\n",
			";   Inline::Files   $Inline::Files::VERSION\n",
			";   Text::Template  $Text::Template::VERSION\n",
			";   strict          $strict::VERSION\n",
			";   Perl            $]\n",
			";   OS              $^O\n",
			";   z80exer.pl      $version\n",
			";   $cmdline\n",
			";\n\n";
	}

	close TMPL or die $!;		# close inline template
}


#-----------------------------------------------------------------------------
#---------------  Z80Exer Package Basic Properties / Methods  ----------------

package Z80Exer;

# generate the full-flag version with all possible Z80 instructions
$all = $opt_all;
sub get_all {
	return $all;
}

# randomises all the initial machine states in each test case
$rand = $opt_rand;
sub get_rand {
	return $rand;
}

# generate for ZMAC Z80 Macro Assembler and MAXAM Assembler
$zmac = $opt_zmac;
sub get_zmac {
	return $zmac;
}

$msgl = $opt_msgl;
sub get_msgl {
	return $msgl;
}

$vers = $opt_versions;
sub get_vers {
	return $vers;
}


#-----------------------------------------------------------------------------
#----------------------  Template Driven Code Section  -----------------------

package Z80Exer;

# sudo apt-get install libtext-template-perl
# http://perl.find-info.ru/perl/025/advperl2-chp-3-sect-2.html
use Text::Template::Preprocess;		# support template driven development

my $z80exer_tmplpp = Text::Template::Preprocess->new(
#	TYPE	=> 'FILE',
#	SOURCE	=> 'z80exer.tmpl',
	TYPE	=> 'FILEHANDLE',
	SOURCE	=> *TMPL,
	PREPEND	=> '# use strict;'
);

$z80exer = $z80exer_tmplpp->fill_in(
	PACKAGE		=> 'Z80Exer',
	PREPROCESSOR	=> \&z80exer_filter,
);

sub z80exer_filter {
	my ( $class, $package, $callas ) = @_;
	my $sub_name = (caller(0))[3];

	die "$sub_name not called as preprocessor"
		unless ($callas eq 'PREPROCESSOR');

	die "$sub_name not called with a package"
		unless ($class eq 'PACKAGE');

	die "$sub_name not called with our package"
		unless ($package eq 'Z80Exer');

	my $all = $package->get_all;
	my $zmac = $package->get_zmac;
	my $msgl = $package->get_msgl;

	chop;
	for (;;) {
		if (/\@c\s(\w+),(\w+)/) {
			# select expected crc
			my $crc = $rand ? 'deadbeaf' : $all ? $2 : $1;
			$crc =~ s/(..)(..)(..)(..)/0$1h,0$2h,0$3h,0$4h/;
			s/\@c(\s)\w+,\w+/db$1${crc}/;
			next;
		}
		if (/\@d<(\w+)>/) {
			# use given 2-byte random value
			my $hex = $rand ? &random_byte.&random_byte :  $1;
			s/\@d<(\w+)>/0${hex}h/;
			next;
		}
		if (/\@d/) {
			# generate a 2-byte random value
			my $hex = &random_byte.&random_byte;
			s/\@d/0${hex}h/;
			next;
		}
		if (/\@f<(\w+)>/) {
			# use given random flag value
			my $hex = $rand ? &random_flag :  $1;
			s/\@f<(\w+)>/0${hex}h/;
			next;
		}
		if (/\@f/) {
			# generate a random flag value
			my $hex = &random_flag;
			s/\@f/0${hex}h/;
			next;
		}
		if (/\@g'(.+)'/) {
			# use given message
			my $msg = $1;
			$msg .= ('.' x ($msgl - length $msg)) unless not $zmac;
			s/\@g'(.+)'/'${msg}'/;
			next;
		}
		if (/\@i/) {
			# generate instruction set description
			my $idsc = $all ? "all" : "documented";
			s/\@i/${idsc}/;
			next;
		}
		if (/\@l/) {
			# supplement message length
			s/\@l/${msgl}/;
			next;
		}
		if (/\@m\s(\w+)/) {
			# generate instruction set flag mask
			my $flm = $all ? "0ffh" : $1;
			s/\@m(\s)\w+/db$1${flm}/;
			next;
		}
		if (/\@s<(\w+)>/) {
			# use given 1-byte random value
			my $hex = $rand ? &random_byte :  $1;
			s/\@s<(\w+)>/0${hex}h/;
			next;
		}
		if (/\@v<(\-*\w+(?:,\s*\-*\w+){0,3})>/) {
			# use given instruction vector
			my $vector = $1;
			$vector =~ s/\s+//g;
			my ($i1, $i2, $i3, $i4) = (split /,/, $vector)[0..3];
			$i1 = 0 unless defined $i1; $i2 = 0 unless defined $i2;
			$i3 = 0 unless defined $i3; $i4 = 0 unless defined $i4;
			no warnings 'syntax';	# disable temporary, caused in hex()
			$i1 = '0' . $i1 .'h' unless (hex($i1) =~ /^[0-9]$/);
			$i2 = '0' . $i2 .'h' unless (hex($i2) =~ /^[0-9]$/);
			$i3 = '0' . $i3 .'h' unless (hex($i3) =~ /^[0-9]$/);
			$i4 = '0' . $i4 .'h' unless (hex($i4) =~ /^[0-9]$/);
			use warnings;		# (re-)enable again
			$vector = $i1;
			$vector = $vector . ',' . $i2 unless not $zmac and not $i2;
			$vector = $vector . ',' . $i3 unless not $zmac and not $i3;
			$vector = $vector . ',' . $i4 unless not $zmac and not $i4;
			$vector = '<' . $vector . '>' unless $zmac or not $i2;
			s/\@v<(\-*\w+(?:,\s*\-*\w+){0,3})>/${vector}/;
			next;
		}
		if (/\@s/) {
			# generate a 1-byte random value
			my $hex = &random_byte;
			s/\@s/0${hex}h/;
			next;
		}
		last;
	}
}

sub random_byte {
	sprintf("%02x", int(rand(256)));
}

sub random_flag {
	my ($self, $param) = @_;
	sprintf("%02x", 0xd7 & int(rand(256)));
}


#-----------------------------------------------------------------------------
#-----------------------  Assembler Template Section  ------------------------

__TMPL__
;
; autogenerated with:
;   {$cmdline}
;

	title	'Z80 @i instruction set exerciser'
{
	# generate comment howto assemble ...
	if ($zmac) {
		# ... with ZMAC and MAXAM
		$OUT .= q{
;
; ZMAC Z80 Macro Assembler	: (TBD)
; MZMAC from the My Z80 Tools	: mzmac -z zexer.azm
;};
	} else {
		# ... with MACRO-80 (default)
		$OUT .= q{
;
; Microsoft MACRO-80 Assembler	: (TBD)
;};
	}
}

; zexdoc.azm - Z80 @i instruction set exerciser
; Original Copyright (C) 1994  Frank D. Cringle
;{
	$OUT .= q{
; Changes at 31-Oct-2017 Copyright (C) 2017 Stephan Linz
; + use EQU to enable or disable (default) the three different verbosity
;   output sections -- only for debugging purposes
;};
	if ($zmac) {
		$OUT .= q{
; Changes at 31-Oct-2017 Copyright (C) 2017 Stephan Linz
; + Source syntax tweeked to assemble with MZMAC from the My Z80 Tools,
;   that is based on the ZMAC Z80 Macro Assembler, marked in the source
;   with 'sli:'
;
; Changes at 03-Nov-2002 Copyright (C) 2002 J.G.Harston
; + Source syntax tweeked to assemble with ZMAC Z80 Macro Assembler
;   and MAXAM Assembler, marked in the source with 'jgh:'
; + ds n,c not supported, so strings are set to full explicity length
; + labels on equates mustn't have trailing colon
; + macros don't understand <...> sequence, so parameters are passed
;   explicitly
;};
	}
}
; This program is free software; you can redistribute it and/or
; modify it under the terms of the GNU General Public License
; as published by the Free Software Foundation; either version 2
; of the License, or (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

; sli: enable corresponding verbosity output when set from 0 to 1
; dbg_test - test harness
; dbg_tcrc - crc test inside the test harness
; dbg_crclp - 32-bit crc routine

dbg_test	equ	0
dbg_tcrc	equ	0
dbg_crclp	equ	0

	aseg
	org	100h

	jp	start

; machine state before test (needs to be at predictably constant address)
msbt:	ds	14
spbt:	ds	2

msbthi	equ	msbt / 0100h	; jgh: replace MACRO-80 syntax 'high msbt'
msbtlo	equ	msbt & 0ffh	; jgh: replace MACRO-80 syntax 'low msbt'

; For the purposes of this test program, the machine state consists of:
;	a 2 byte memory operand, followed by
;	the registers iy,ix,hl,de,bc,af,sp
; for a total of 16 bytes.

; The program tests instructions (or groups of similar instructions)
; by cycling through a sequence of machine states, executing the test
; instruction for each one and running a 32-bit crc over the resulting
; machine states.  At the end of the sequence the crc is compared to
; an expected value that was found empirically on a real Z80.

; A test case is defined by a descriptor which consists of:
;	a flag mask byte,
;	the base case,
;	the increment vector,
;	the shift vector,
;	the expected crc,
;	a short descriptive message.
;
; The flag mask byte is used to prevent undefined flag bits from
; influencing the results.  Documented flags are as per Mostek Z80
; Technical Manual.
;
; The next three parts of the descriptor are 20 byte vectors
; corresponding to a 4 byte instruction and a 16 byte machine state.
; The first part is the base case, which is the first test case of
; the sequence.  This base is then modified according to the next 2
; vectors.  Each 1 bit in the increment vector specifies a bit to be
; cycled in the form of a binary counter.  For instance, if the byte
; corresponding to the accumulator is set to 0ffh in the increment
; vector, the test will be repeated for all 256 values of the
; accumulator.  Note that 1 bits don't have to be contiguous.  The
; number of test cases 'caused' by the increment vector is equal to
; 2^(number of 1 bits).  The shift vector is similar, but specifies a
; set of bits in the test case that are to be successively inverted.
; Thus the shift vector 'causes' a number of test cases equal to the
; number of 1 bits in it.

; The total number of test cases is the product of those caused by the
; counter and shift vectors and can easily become unweildy.  Each
; individual test case can take a few milliseconds to execute, due to
; the overhead of test setup and crc calculation, so test design is a
; compromise between coverage and execution time.

; This program is designed to detect differences between
; implementations and is not ideal for diagnosing the causes of any
; discrepancies.  However, provided a reference implementation (or
; real system) is available, a failing test case can be isolated by
; hand using a binary search of the test space.


start:	ld	hl,(6)
	ld	sp,hl
	ld	de,msg1
	ld	c,9
	call	bdos

	ld	hl,tests	; first test case
loop:	ld	a,(hl)		; end of list ?
	inc	hl
	or	(hl)
	jp	z,done
	dec	hl
	call	stt
	jp	loop

done:	ld	de,msg2
	ld	c,9
	call	bdos
	jp	0		; warm boot

tests:
	dw	adc16
	dw	add16
	dw	add16x
	dw	add16y
	dw	alu8i
	dw	alu8r
	dw	alu8rx
	dw	alu8x
	dw	bitx
	dw	bitz80
	dw	cpd1
	dw	cpi1
	dw	daaop		; jgh: can't use opcode as label
	dw	inca
	dw	incb
	dw	incbc
	dw	incc
	dw	incd
	dw	incde
	dw	ince
	dw	inch
	dw	inchl
	dw	incix
	dw	inciy
	dw	incl
	dw	incm
	dw	incsp
	dw	incx
	dw	incxh
	dw	incxl
	dw	incyh
	dw	incyl
	dw	ld161
	dw	ld162
	dw	ld163
	dw	ld164
	dw	ld165
	dw	ld166
	dw	ld167
	dw	ld168
	dw	ld16im
	dw	ld16ix
	dw	ld8bd
	dw	ld8im
	dw	ld8imx
	dw	ld8ix1
	dw	ld8ix2
	dw	ld8ix3
	dw	ld8ixy
	dw	ld8rr
	dw	ld8rrx
	dw	ldaop		; sli: can't use opcode as label
	dw	ldd1
	dw	ldd2
	dw	ldi1
	dw	ldi2
	dw	negop		; jgh: can't use opcode as label
	dw	rldop		; jgh: can't use opcode as label
	dw	rot8080
	dw	rotxy
	dw	rotz80
	dw	srz80
	dw	srzx
	dw	st8ix1
	dw	st8ix2
	dw	st8ix3
	dw	stabd
	dw	0
{
	# generate test string macro 'tstr' ...
	if ($zmac) {
		# ... for ZMAC and MAXAM
		$OUT .= q{
; jgh:	macro syntax changed for ZMAC and MAXAM
;	- can't use opcodes as labels
;	- ZMAC allows &nn as hex, so & removed from local labels
;
tstr	macro	insn1,insn2,insn3,insn4,memop,riy,rix,rhl,rde,rbc,flags,acc,rsp,?lab
?lab:	db	insn1,insn2,insn3,insn4
	dw	memop,riy,rix,rhl,rde,rbc
	db	flags
	db	acc
	dw	rsp
	if	$-?lab ne 20
	error	'missing parameter'
	endif
	endm};
	} else {
		# ... for MACRO-80 (default)
		$OUT .= q{
tstr:	macro	insn,memop,iy,ix,hl,de,bc,flags,acc,sp
	local	lab
&lab:	db	insn
	ds	&lab+4-$,0
	dw	&memop,&iy,&ix,&hl,&de,&bc
	db	&flags
	db	&acc
	dw	&sp
	if	$-&lab ne 20
	error	'missing parameter'
	endif
	endm};
	}
}
{
	# generate test message macro 'tmsg' ...
	if ($zmac) {
		# ... for ZMAC and MAXAM
		$OUT .= q{
; jgh:	macro syntax changed for ZMAC and MAXAM
;	- ZMAC allows &nn as hex, so & removed from local labels
;
tmsg	macro	msg,?lab
?lab:	db	msg
	if	$ ge ?lab+@l+1
	error	'message too long'
	else
;	ds	?lab+@l-$,'.'	; jgh: ZMAC/MAXAM don't have char parameter
	endif
	db	'$'
	endm};
	} else {
		# ... for MACRO-80 (default)
		$OUT .= q{
tmsg:	macro	m
	local	lab
&lab:	db	m
	if	$ ge &lab+@l
	error	'message too long'
	else
	ds	&lab+@l-$,'.'
	endif
	db	'$'
	endm};
	}
}
{
	if ($zmac) {
		$OUT .= q{
;
; jgh:	macro syntax changed for ZMAC and MAXAM
;	- don't recognise <n,m> syntax for macros, so full parameters given
;	- don't have ds n,c pseudo-op, so each tmsg has full string
;
};
	}; ''
}
; <adc,sbc> hl,<bc,de,hl,sp> (38,912 cycles)
adc16:	@m	0c7h					; flag mask
	tstr	@v<ed,42>,@d<832c>,@d<4f88>,@d<f22b>,@d<b339>,@d<7e1f>,@d<1563>,@f<d3>,@s<89>,@d<465e>
	tstr	@v<0,38>,0,0,0,0f821h,0,0,0,0,0		; (1024 cycles)
	tstr	@v<0>,0,0,0,-1,-1,-1,0d7h,0,-1		; (38 cycles)
	@c	f8b4eaa9,d48ad519			; expected crc
	tmsg	@g'<adc,sbc> hl,<bc,de,hl,sp>'

; add hl,<bc,de,hl,sp> (19,456 cycles)
add16:	@m	0c7h					; flag mask
	tstr	@v<9>,@d<c4a5>,@d<c4c7>,@d<d226>,@d<a050>,@d<58ea>,@d<8566>,@f<c6>,@s<de>,@d<9bc9>
	tstr	@v<30>,0,0,0,0f821h,0,0,0,0,0		; (512 cycles)
	tstr	@v<0>,0,0,0,-1,-1,-1,0d7h,0,-1		; (38 cycles)
	@c	89fdb635,d9a4ca05			; expected crc
	tmsg	@g'add hl,<bc,de,hl,sp>'

; add ix,<bc,de,ix,sp> (19,456 cycles)
add16x:	@m	0c7h					; flag mask
	tstr	@v<dd,9>,@d<ddac>,@d<c294>,@d<635b>,@d<33d3>,@d<6a76>,@d<fa20>,@f<94>,@s<68>,@d<36f5>
	tstr	@v<0,30>,0,0,0f821h,0,0,0,0,0,0		; (512 cycles)
	tstr	@v<0>,0,0,-1,0,-1,-1,0d7h,0,-1		; (38 cycles)
	@c	c133790b,b1df8ec0			; expected crc
	tmsg	@g'add ix,<bc,de,ix,sp>'

; add iy,<bc,de,iy,sp> (19,456 cycles)
add16y:	@m	0c7h					; flag mask
	tstr	@v<fd,9>,@d<c7c2>,@d<f407>,@d<51c1>,@d<3e96>,@d<0bf4>,@d<510f>,@f<92>,@s<1e>,@d<71ea>
	tstr	@v<0,30>,0,0f821h,0,0,0,0,0,0,0		; (512 cycles)
	tstr	@v<0>,0,-1,0,0,-1,-1,0d7h,0,-1		; (38 cycles)
	@c	e8817b9e,39c8589b			; expected crc
	tmsg	@g'add iy,<bc,de,iy,sp>'

; aluop a,nn (28,672 cycles)
alu8i:	@m	0d7h					; flag mask
	tstr	@v<c6>,@d<9140>,@d<7e3c>,@d<7a67>,@d<df6d>,@d<5b61>,@d<0b29>,@f<10>,@s<66>,@d<85b2>
	tstr	@v<38>,0,0,0,0,0,0,0,-1,0		; (2048 cycles)
	tstr	@v<0,-1>,0,0,0,0,0,0,0d7h,0,0		; (14 cycles)
	@c	48799360,51c19c2e			; expected crc
	tmsg	@g'aluop a,nn'

; aluop a,<b,c,d,e,h,l,(hl),a> (753,664 cycles)
alu8r:	@m	0d7h					; flag mask
	tstr	@v<80>,@d<c53e>,@d<573a>,@d<4c4d>,msbt,@d<e309>,@d<a666>,@f<d0>,@s<3b>,@d<adbb>
	tstr	@v<3f>,0,0,0,0,0,0,0,-1,0		; (16,384 cycles)
	tstr	@v<0>,0ffh,0,0,0,-1,-1,0d7h,0,0		; (46 cycles)
	@c	fe43b016,06c7aa8e			; expected crc
	tmsg	@g'aluop a,<b,c,d,e,h,l,(hl),a>'

; aluop a,<ixh,ixl,iyh,iyl> (376,832 cycles)
alu8rx:	@m	0d7h					; flag mask
	tstr	@v<dd,84>,@d<d6f7>,@d<c76e>,@d<accf>,@d<2847>,@d<22dd>,@d<c035>,@f<c5>,@s<38>,@d<234b>
	tstr	@v<20,39>,0,0,0,0,0,0,0,-1,0		; (8,192 cycles)
	tstr	@v<0>,0ffh,0,0,0,-1,-1,0d7h,0,0		; (46 cycles)
	@c	a4026d5a,a886cc44			; expected crc
	tmsg	@g'aluop a,<ixh,ixl,iyh,iyl>'

; aluop a,(<ix,iy>+1) (229,376 cycles)
alu8x:	@m	0d7h					; flag mask
	tstr	@v<dd,86,1>,@d<90b7>,msbt-1,msbt-1,@d<32fd>,@d<406e>,@d<c1dc>,@f<45>,@s<6e>,@d<e5fa>
	tstr	@v<20,38>,0,1,1,0,0,0,0,-1,0		; (16,384 cycles)
	tstr	@v<0>,0ffh,0,0,0,0,0,0d7h,0,0		; (14 cycles)
	@c	e849676e,d3f2d74a			; expected crc
	tmsg	@g'aluop a,(<ix,iy>+1)'

; bit n,(<ix,iy>+1) (2048 cycles)
bitx:	@m	053h					; flag mask
	tstr	@v<dd,cb,1,46>,@d<2075>,msbt-1,msbt-1,@d<3cfc>,@d<a79a>,@d<3d74>,@f<51>,@s<27>,@d<ca14>
	tstr	@v<20,0,0,38>,0,0,0,0,0,0,053h,0,0	; (256 cycles)
	tstr	@v<0>,0ffh,0,0,0,0,0,0,0,0		; (8 cycles)
	@c	a8ee0867,83534ee1			; expected crc
	tmsg	@g'bit n,(<ix,iy>+1)'

; bit n,<b,c,d,e,h,l,(hl),a> (49,152 cycles)
bitz80:	@m	053h					; flag mask
	tstr	@v<cb,40>,@d<3ef1>,@d<9dfc>,@d<7acc>,msbt,@d<be61>,@d<7a86>,@f<50>,@s<24>,@d<1998>
	tstr	@v<0,3f>,0,0,0,0,0,0,053h,0,0		; (1024 cycles)
	tstr	@v<0>,0ffh,0,0,0,-1,-1,0,-1,0		; (48 cycles)
	@c	7b55e6c8,5e020e98			; expected crc
	tmsg	@g'bit n,<b,c,d,e,h,l,(hl),a>'

; cpd<r> (1) (6144 cycles)
cpd1:	@m	0d7h					; flag mask
	tstr	@v<ed,a9>,@d<c7b6>,@d<72b4>,@d<18f6>,msbt+17,@d<8dbd>,1,@f<c0>,@s<30>,@d<94a3>
	tstr	@v<0,10>,0,0,0,0,0,010,0,-1,0		; (1024 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,0,0		; (6 cycles)
	@c	a87e6cfa,134b622d			; expected crc
	tmsg	@g'cpd<r>'

; cpi<r> (1) (6144 cycles)
cpi1:	@m	0d7h					; flag mask
	tstr	@v<ed,a1>,@d<4d48>,@d<af4a>,@d<906b>,msbt,@d<4e71>,1,@f<93>,@s<6a>,@d<907c>
	tstr	@v<0,10>,0,0,0,0,0,010,0,-1,0		; (1024 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,0,0		; (6 cycles)
	@c	06deb356,2da42d19			; expected crc
	tmsg	@g'cpi<r>'

; <daa,cpl,scf,ccf>
daaop:	@m	0d7h					; flag mask
	tstr	@v<27>,@d<2141>,@d<09fa>,@d<1d60>,@d<a559>,@d<8d5b>,@d<9079>,@f<04>,@s<8e>,@d<299d>
	tstr	@v<18>,0,0,0,0,0,0,0d7h,-1,0		; (65,536 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0,0,0			; (1 cycle)
	@c	9b4ba675,6d2dd213			; expected crc
	tmsg	@g'<daa,cpl,scf,ccf>'

; <inc,dec> a (3072 cycles)
inca:	@m	0d7h					; flag mask
	tstr	@v<3c>,@d<4adf>,@d<d5d8>,@d<e598>,@d<8a2b>,@d<a7b0>,@d<431b>,@f<44>,@s<5a>,@d<d030>
	tstr	@v<1>,0,0,0,0,0,0,0,-1,0		; (512 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,0,0		; (6 cycles)
	@c	d18815a4,81fa8100			; expected crc
	tmsg	@g'<inc,dec> a'

; <inc,dec> b (3072 cycles)
incb:	@m	0d7h					; flag mask
	tstr	@v<4>,@d<d623>,@d<432d>,@d<7a61>,@d<8180>,@d<5a86>,@d<1e85>,@f<86>,@s<58>,@d<9bbb>
	tstr	@v<1>,0,0,0,0,0,0ff00h,0,0,0		; (512 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,0,0		; (6 cycles)
	@c	5f682264,77f35a73			; expected crc
	tmsg	@g'<inc,dec> b'

; <inc,dec> bc (1536 cycles)
incbc:	@m	0d7h					; flag mask
	tstr	@v<3>,@d<cd97>,@d<44ab>,@d<8dc9>,@d<e3e3>,@d<11cc>,@d<e8a4>,@f<02>,@s<49>,@d<2a4d>
	tstr	@v<8>,0,0,0,0,0,0f821h,0,0,0		; (256 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,0,0		; (6 cycles)
	@c	d2ae3bec,d2ae3bec			; expected crc
	tmsg	@g'<inc,dec> bc'

; <inc,dec> c (3072 cycles)
incc:	@m	0d7h					; flag mask
	tstr	@v<0c>,@d<d789>,@d<0935>,@d<055b>,@d<9f85>,@d<8b27>,@d<d208>,@f<95>,@s<05>,@d<0660>
	tstr	@v<1>,0,0,0,0,0,0ffh,0,0,0		; (512 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,0,0		; (6 cycles)
	@c	c284554c,1af612a7			; expected crc
	tmsg	@g'<inc,dec> c'

; <inc,dec> d (3072 cycles)
incd:	@m	0d7h					; flag mask
	tstr	@v<14>,@d<a0ea>,@d<5fba>,@d<65fb>,@d<981c>,@d<38cc>,@d<debc>,@f<43>,@s<5c>,@d<03bd>
	tstr	@v<1>,0,0,0,0,0ff00h,0,0,0,0		; (512 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,0,0		; (6 cycles)
	@c	4523de10,d146bf51			; expected crc
	tmsg	@g'<inc,dec> d'

; <inc,dec> de (1536 cycles)
incde:	@m	0d7h					; flag mask
	tstr	@v<13>,@d<342e>,@d<131d>,@d<28c9>,@d<0aca>,@d<9967>,@d<3a2e>,@f<92>,@s<f6>,@d<9d54>
	tstr	@v<8>,0,0,0,0,0f821h,0,0,0,0		; (256 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,0,0		; (6 cycles)
	@c	aec6d42c,aec6d42c			; expected crc
	tmsg	@g'<inc,dec> de'

; <inc,dec> e (3072 cycles)
ince:	@m	0d7h					; flag mask
	tstr	@v<1c>,@d<602f>,@d<4c0d>,@d<2402>,@d<e2f5>,@d<a0f4>,@d<a10a>,@f<13>,@s<32>,@d<5925>
	tstr	@v<1>,0,0,0,0,0ffh,0,0,0,0		; (512 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,0,0		; (6 cycles)
	@c	e175afcc,ca8c6ac2			; expected crc
	tmsg	@g'<inc,dec> e'

; <inc,dec> h (3072 cycles)
inch:	@m	0d7h					; flag mask
	tstr	@v<24>,@d<1506>,@d<f2eb>,@d<e8dd>,@d<262b>,@d<11a6>,@d<bc1a>,@f<17>,@s<06>,@d<2818>
	tstr	@v<1>,0,0,0,0ff00h,0,0,0,0,0		; (512 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,0,0		; (6 cycles)
	@c	1ced847d,560f955e			; expected crc
	tmsg	@g'<inc,dec> h'

; <inc,dec> hl (1536 cycles)
inchl:	@m	0d7h					; flag mask
	tstr	@v<23>,@d<c3f4>,@d<07a5>,@d<1b6d>,@d<4f04>,@d<e2c2>,@d<822a>,@f<57>,@s<e0>,@d<c3e1>
	tstr	@v<8>,0,0,0,0f821h,0,0,0,0,0		; (256 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,0,0		; (6 cycles)
	@c	fc0d6d4a,fc0d6d4a			; expected crc
	tmsg	@g'<inc,dec> hl'

; <inc,dec> ix (1536 cycles)
incix:	@m	0d7h					; flag mask
	tstr	@v<dd,23>,@d<bc3c>,@d<0d9b>,@d<e081>,@d<adfd>,@d<9a7f>,@d<96e5>,@f<13>,@s<85>,@d<0be2>
	tstr	@v<0,8>,0,0,0f821h,0,0,0,0,0,0		; (256 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,0,0		; (6 cycles)
	@c	a54dbe31,a54dbe31			; expected crc
	tmsg	@g'<inc,dec> ix'

; <inc,dec> iy (1536 cycles)
inciy:	@m	0d7h					; flag mask
	tstr	@v<fd,23>,@d<9402>,@d<637a>,@d<3182>,@d<c65a>,@d<b2e9>,@d<abb4>,@f<16>,@s<f2>,@d<6d05>
	tstr	@v<0,8>,0,0f821h,0,0,0,0,0,0,0		; (256 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,0,0		; (6 cycles)
	@c	505d51a3,505d51a3			; expected crc
	tmsg	@g'<inc,dec> iy'

; <inc,dec> l (3072 cycles)
incl:	@m	0d7h					; flag mask
	tstr	@v<2c>,@d<8031>,@d<a520>,@d<4356>,@d<b409>,@d<f4c1>,@d<dfa2>,@f<d1>,@s<3c>,@d<3ea2>
	tstr	@v<1>,0,0,0,0ffh,0,0,0,0,0		; (512 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,0,0		; (6 cycles)
	@c	56cd06f3,a0a1b49f			; expected crc
	tmsg	@g'<inc,dec> l'

; <inc,dec> (hl) (3072 cycles)
incm:	@m	0d7h					; flag mask
	tstr	@v<34>,@d<b856>,@d<0c7c>,@d<e53e>,msbt,@d<877e>,@d<da58>,@f<15>,@s<5c>,@d<1f37>
	tstr	@v<1>,0ffh,0,0,0,0,0,0,0,0		; (512 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,0,0		; (6 cycles)
	@c	b83adcef,28295ece			; expected crc
	tmsg	@g'<inc,dec> (hl)'

; <inc,dec> sp (1536 cycles)
incsp:	@m	0d7h					; flag mask
	tstr	@v<33>,@d<346f>,@d<d482>,@d<d169>,@d<deb6>,@d<a494>,@d<f476>,@f<53>,@s<02>,@d<855b>
	tstr	@v<8>,0,0,0,0,0,0,0,0,0f821h		; (256 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,0,0		; (6 cycles)
	@c	5dacd527,5dacd527			; expected crc
	tmsg	@g'<inc,dec> sp'

; <inc,dec> (<ix,iy>+1) (6144 cycles)
incx:	@m	0d7h					; flag mask
	tstr	@v<dd,34,1>,@d<fa6e>,msbt-1,msbt-1,@d<2c28>,@d<8894>,@d<5057>,@f<16>,@s<33>,@d<286f>
	tstr	@v<20,1>,0ffh,0,0,0,0,0,0,0,0		; (1024 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,0,0		; (6 cycles)
	@c	20581470,0b95a8ea			; expected crc
	tmsg	@g'<inc,dec> (<ix,iy>+1)'

; <inc,dec> ixh (3072 cycles)
incxh:	@m	0d7h					; flag mask
	tstr	@v<dd,24>,@d<b838>,@d<316c>,@d<c6d4>,@d<3e01>,@d<8358>,@d<15b4>,@f<81>,@s<de>,@d<4259>
	tstr	@v<0,1>,0,0ff00h,0,0,0,0,0,0,0		; (512 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,0,0		; (6 cycles)
	@c	6f463662,6f463662			; expected crc
	tmsg	@g'<inc,dec> ixh'

; <inc,dec> ixl (3072 cycles)
incxl:	@m	0d7h					; flag mask
	tstr	@v<dd,2c>,@d<4d14>,@d<7460>,@d<76d4>,@d<06e7>,@d<32a2>,@d<213c>,@f<d6>,@s<d7>,@d<99a5>
	tstr	@v<0,1>,0,0ffh,0,0,0,0,0,0,0		; (512 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,0,0		; (6 cycles)
	@c	027bef2c,027bef2c			; expected crc
	tmsg	@g'<inc,dec> ixl'

; <inc,dec> iyh (3072 cycles)
incyh:	@m	0d7h					; flag mask
	tstr	@v<dd,24>,@d<2836>,@d<9f6f>,@d<9116>,@d<61b9>,@d<82cb>,@d<e219>,@f<92>,@s<73>,@d<a98c>
	tstr	@v<0,1>,0ff00h,0,0,0,0,0,0,0,0		; (512 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,0,0		; (6 cycles)
	@c	2d966cf3,2d966cf3			; expected crc
	tmsg	@g'<inc,dec> iyh'

; <inc,dec> iyl (3072 cycles)
incyl:	@m	0d7h					; flag mask
	tstr	@v<dd,2c>,@d<d7c6>,@d<62d5>,@d<a09e>,@d<7039>,@d<3e7e>,@d<9f12>,@f<90>,@s<d9>,@d<220f>
	tstr	@v<0,1>,0ffh,0,0,0,0,0,0,0,0		; (512 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,0,0		; (6 cycles)
	@c	fbcbba95,36c11e75			; expected crc
	tmsg	@g'<inc,dec> iyl'

; ld <bc,de>,(nnnn) (32 cycles)
ld161:	@m	0d7h					; flag mask
	tstr	@v<ed,4b,msbtlo,msbthi>,@d<f9a8>,@d<f559>,@d<93a4>,@d<f5ed>,@d<6f96>,@d<d968>,@f<86>,@s<e6>,@d<4bd8>
	tstr	@v<0,10>,0,0,0,0,0,0,0,0,0		; (2 cycles)
	tstr	@v<0>,-1,0,0,0,0,0,0,0,0		; (16 cycles)
	@c	4d45a9ac,4d45a9ac			; expected crc
	tmsg	@g'ld <bc,de>,(nnnn)'

; ld hl,(nnnn) (16 cycles)
ld162:	@m	0d7h					; flag mask
	tstr	@v<2a,msbtlo,msbthi>,@d<9863>,@d<7830>,@d<2077>,@d<b1fe>,@d<b9fa>,@d<abb8>,@f<04>,@s<06>,@d<6015>
	tstr	@v<0>,0,0,0,0,0,0,0,0,0			; (1 cycle)
	tstr	@v<0>,-1,0,0,0,0,0,0,0,0		; (16 cycles)
	@c	5f972487,5f972487			; expected crc
	tmsg	@g'ld hl,(nnnn)'

; ld sp,(nnnn) (16 cycles)
ld163:	@m	0d7h					; flag mask
	tstr	@v<ed,7b,msbtlo,msbthi>,@d<8dfc>,@d<57d7>,@d<2161>,@d<ca18>,@d<c185>,@d<27da>,@f<83>,@s<1e>,@d<f460>
	tstr	@v<0>,0,0,0,0,0,0,0,0,0			; (1 cycles)
	tstr	@v<0>,-1,0,0,0,0,0,0,0,0		; (16 cycles)
	@c	7acea11b,7acea11b			; expected crc
	tmsg	@g'ld sp,(nnnn)'

; ld <ix,iy>,(nnnn) (32 cycles)
ld164:	@m	0d7h					; flag mask
	tstr	@v<dd,2a,msbtlo,msbthi>,@d<ded7>,@d<a6fa>,@d<f780>,@d<244c>,@d<87de>,@d<bcc2>,@f<16>,@s<63>,@d<4c96>
	tstr	@v<20>,0,0,0,0,0,0,0,0,0		; (2 cycles)
	tstr	@v<0>,-1,0,0,0,0,0,0,0,0		; (16 cycles)
	@c	858bf16d,858bf16d			; expected crc
	tmsg	@g'ld <ix,iy>,(nnnn)'

; ld (nnnn),<bc,de> (64 cycles)
ld165:	@m	0d7h					; flag mask
	tstr	@v<ed,43,msbtlo,msbthi>,@d<1f98>,@d<844d>,@d<e8ac>,@d<c9ed>,@d<c95d>,@d<8f61>,@f<80>,@s<3f>,@d<c7bf>
	tstr	@v<0,10>,0,0,0,0,0,0,0,0,0		; (2 cycles)
	tstr	@v<0>,0,0,0,0,-1,-1,0,0,0		; (32 cycles)
	@c	641e8715,641e8715			; expected crc
	tmsg	@g'ld (nnnn),<bc,de>'

; ld (nnnn),hl (16 cycles)
ld166:	@m	0d7h					; flag mask
	tstr	@v<22,msbtlo,msbthi>,@d<d003>,@d<7772>,@d<7f53>,@d<3f72>,@d<64ea>,@d<e180>,@f<10>,@s<2d>,@d<35e9>
	tstr	@v<0>,0,0,0,0,0,0,0,0,0			; (1 cycle)
	tstr	@v<0>,0,0,0,-1,0,0,0,0,0		; (16 cycles)
	@c	a3608b47,a3608b47			; expected crc
	tmsg	@g'ld (nnnn),hl'

; ld (nnnn),sp (16 cycles)
ld167:	@m	0d7h					; flag mask
	tstr	@v<ed,73,msbtlo,msbthi>,@d<c0dc>,@d<d1d6>,@d<ed5a>,@d<f356>,@d<afda>,@d<6ca7>,@f<44>,@s<9f>,@d<3f0a>
	tstr	@v<0>,0,0,0,0,0,0,0,0,0			; (1 cycle)
	tstr	@v<0>,0,0,0,0,0,0,0,0,-1		; (16 cycles)
	@c	16585fd7,16585fd7			; expected crc
	tmsg	@g'ld (nnnn),sp'

; ld (nnnn),<ix,iy> (64 cycles)
ld168:	@m	0d7h					; flag mask
	tstr	@v<dd,22,msbtlo,msbthi>,@d<6cc3>,@d<0d91>,@d<6900>,@d<8ef8>,@d<e3d6>,@d<c3f7>,@f<c6>,@s<d9>,@d<c2df>
	tstr	@v<20>,0,0,0,0,0,0,0,0,0		; (2 cycles)
	tstr	@v<0>,0,-1,-1,0,0,0,0,0,0		; (32 cycles)
	@c	ba102a6b,ba102a6b			; expected crc
	tmsg	@g'ld (nnnn),<ix,iy>'

; ld <bc,de,hl,sp>,nnnn (64 cycles)
ld16im:	@m	0d7h					; flag mask
	tstr	@v<1>,@d<5c1c>,@d<2d46>,@d<8eb9>,@d<6078>,@d<74b1>,@d<b30e>,@d<46>,@d<d1>,@d<30cc>
	tstr	@v<30>,0,0,0,0,0,0,0,0,0		; (4 cycles)
	tstr	@v<0,ff,ff>,0,0,0,0,0,0,0,0,0		; (16 cycles)
	@c	de391969,de391969			; expected crc
	tmsg	@g'ld <bc,de,hl,sp>,nnnn'

; ld <ix,iy>,nnnn (32 cycles)
ld16ix:	@m	0d7h					; flag mask
	tstr	@v<dd,21>,@d<87e8>,@d<2006>,@d<bd12>,@d<b69b>,@d<7253>,@d<a1e5>,@d<51>,@d<13>,@d<f1bd>
	tstr	@v<20>,0,0,0,0,0,0,0,0,0		; (2 cycles)
	tstr	@v<0,0,ff,ff>,0,0,0,0,0,0,0,0,0		; (16 cycles)
	@c	227dd525,227dd525			; expected crc
	tmsg	@g'ld <ix,iy>,nnnn'

; ld a,<(bc),(de)> (44 cycles)
ld8bd:	@m	0d7h					; flag mask
	tstr	@v<0a>,@d<b3a8>,@d<1d2a>,@d<7f8e>,@d<42ac>,msbt,msbt,@f<c6>,@s<b1>,@d<ef8e>
	tstr	@v<10>,0,0,0,0,0,0,0,0,0		; (2 cycles)
	tstr	@v<0>,0ffh,0,0,0,0,0,0d7h,-1,0		; (22 cycles)
	@c	b0818935,b0818935			; expected crc
	tmsg	@g'ld a,<(bc),(de)>'

; ld <b,c,d,e,h,l,(hl),a>,nn (64 cycles)
ld8im:	@m	0d7h					; flag mask
	tstr	@v<6>,@d<c407>,@d<f49d>,@d<d13d>,@d<0339>,@d<de89>,@d<7455>,@f<53>,@s<c0>,@d<5509>
	tstr	@v<38>,0,0,0,0,0,0,0,0,0		; (8 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0,-1,0		; (8 cycles)
	@c	f1dab556,f1dab556			; expected crc
	tmsg	@g'ld <b,c,d,e,h,l,(hl),a>,nn'

; ld (<ix,iy>+1),nn (32 cycles)
ld8imx:	@m	0d7h					; flag mask
	tstr	@v<dd,36,1>,@d<1b45>,msbt-1,msbt-1,@d<d5c1>,@d<61c7>,@d<bdc4>,@f<c0>,@s<85>,@d<cd16>
	tstr	@v<20>,0,0,0,0,0,0,0,0,0		; (2 cycles)
	tstr	@v<0,0,0,-1>,0,0,0,0,0,0,0,-1,0		; (16 cycles)
	@c	26db477e,26db477e			; expected crc
	tmsg	@g'ld (<ix,iy>+1),nn'

; ld <b,c,d,e>,(<ix,iy>+1) (512 cycles)
ld8ix1:	@m	0d7h					; flag mask
	tstr	@v<dd,46,1>,@d<d016>,msbt-1,msbt-1,@d<4260>,@d<7f39>,@d<0404>,@f<97>,@s<4a>,@d<d085>
	tstr	@v<20,18>,0,1,1,0,0,0,0,0,0		; (32 cycles)
	tstr	@v<0>,-1,0,0,0,0,0,0,0,0		; (16 cycles)
	@c	cc1106a8,cc1106a8			; expected crc
	tmsg	@g'ld <b,c,d,e>,(<ix,iy>+1)'

; ld <h,l>,(<ix,iy>+1) (256 cycles)
ld8ix2:	@m	0d7h					; flag mask
	tstr	@v<dd,66,1>,@d<84e0>,msbt-1,msbt-1,@d<9c52>,@d<a799>,@d<49b6>,@f<93>,@s<00>,@d<eead>
	tstr	@v<20,8>,0,1,1,0,0,0,0,0,0		; (16 cycles)
	tstr	@v<0>,-1,0,0,0,0,0,0,0,0		; (16 cycles)
	@c	fa2a4d03,fa2a4d03			; expected crc
	tmsg	@g'ld <h,l>,(<ix,iy>+1)'

; ld a,(<ix,iy>+1) (128 cycles)
ld8ix3:	@m	0d7h					; flag mask
	tstr	@v<dd,7e,1>,@d<d8b6>,msbt-1,msbt-1,@d<c612>,@d<df07>,@d<9cd0>,@f<43>,@s<a6>,@d<a0e5>
	tstr	@v<20>,0,1,1,0,0,0,0,0,0		; (8 cycles)
	tstr	@v<0>,-1,0,0,0,0,0,0,0,0		; (16 cycles)
	@c	a5e9ac64,a5e9ac64			; expected crc
	tmsg	@g'ld a,(<ix,iy>+1)'

; ld <ixh,ixl,iyh,iyl>,nn (32 cycles)
ld8ixy:	@m	0d7h					; flag mask
	tstr	@v<dd,26>,@d<3c53>,@d<4640>,@d<e179>,@d<7711>,@d<c107>,@d<1afa>,@f<81>,@s<ad>,@d<5d9b>
	tstr	@v<20,8>,0,0,0,0,0,0,0,0,0		; (4 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0,-1,0		; (8 cycles)
	@c	24e8828b,24e8828b			; expected crc
	tmsg	@g'ld <ixh,ixl,iyh,iyl>,nn'

; ld <b,c,d,e,h,l,a>,<b,c,d,e,h,l,a> (3456 cycles)
ld8rr:	@m	0d7h					; flag mask
	tstr	@v<40>,@d<72a4>,@d<a024>,@d<61ac>,msbt,@d<82c7>,@d<718f>,@f<97>,@s<8f>,@d<ef8e>
	tstr	@v<3f>,0,0,0,0,0,0,0,0,0		; (64 cycles)
	tstr	@v<0>,0ffh,0,0,0,-1,-1,0d7h,-1,0	; (54 cycles)
	@c	744b0118,744b0118			; expected crc
	tmsg	@g'ld <bcdehla>,<bcdehla>'

; ld <b,c,d,e,ixy,a>,<b,c,d,e,ixy,a> (6912 cycles)
ld8rrx:	@m	0d7h					; flag mask
	tstr	@v<dd,40>,@d<bcc5>,msbt,msbt,msbt,@d<2fc2>,@d<98c0>,@f<83>,@s<1f>,@d<3bcd>
	tstr	@v<20,3f>,0,0,0,0,0,0,0,0,0		; (128 cycles)
	tstr	@v<0>,0ffh,0,0,0,-1,-1,0d7h,-1,0	; (54 cycles)
	@c	478ba36b,478ba36b			; expected crc
	tmsg	@g'ld <bcdexya>,<bcdexya>'

; ld a,(nnnn) / ld (nnnn),a (44 cycles)
ldaop:	@m	0d7h					; flag mask
	tstr	@v<32,msbtlo,msbthi>,@d<fd68>,@d<f4ec>,@d<44a0>,@d<b543>,@d<0653>,@d<cdba>,@f<d2>,@s<4f>,@d<1fd8>
	tstr	@v<8>,0,0,0,0,0,0,0,0,0			; (2 cycle)
	tstr	@v<0>,0ffh,0,0,0,0,0,0d7h,-1,0		; (22 cycles)
	@c	c9262de5,c9262de5			; expected crc
	tmsg	@g'ld a,(nnnn) / ld (nnnn),a'

; ldd<r> (1) (44 cycles)
ldd1:	@m	0d7h					; flag mask
	tstr	@v<ed,a8>,@d<9852>,@d<68fa>,@d<66a1>,msbt+3,msbt+1,1,@f<c1>,@s<68>,@d<20b7>
	tstr	@v<0,10>,0,0,0,0,0,0,0,0,0		; (2 cycles)
	tstr	@v<0>,-1,0,0,0,0,0,0d7h,0,0		; (22 cycles)
	@c	94f42769,94f42769			; expected crc
	tmsg	@g'ldd<r> (1)'

; ldd<r> (2) (44 cycles)
ldd2:	@m	0d7h					; flag mask
	tstr	@v<ed,a8>,@d<f12e>,@d<eb2a>,@d<d5ba>,msbt+3,msbt+1,2,@f<47>,@s<ff>,@d<fbe4>
	tstr	@v<0,10>,0,0,0,0,0,0,0,0,0		; (2 cycles)
	tstr	@v<0>,-1,0,0,0,0,0,0d7h,0,0		; (22 cycles)
	@c	5a907ed4,39dd3de1			; expected crc
	tmsg	@g'ldd<r> (2)'

; ldi<r> (1) (44 cycles)
ldi1:	@m	0d7h					; flag mask
	tstr	@v<ed,a0>,@d<fe30>,@d<03cd>,@d<6058>,msbt+2,msbt,1,@f<04>,@s<60>,@d<2688>
	tstr	@v<0,10>,0,0,0,0,0,0,0,0,0		; (2 cycles)
	tstr	@v<0>,-1,0,0,0,0,0,0d7h,0,0		; (22 cycles)
	@c	9abdf6b5,f782b0d1			; expected crc
	tmsg	@g'ldi<r> (1)'

; ldi<r> (2) (44 cycles)
ldi2:	@m	0d7h					; flag mask
	tstr	@v<ed,a0>,@d<4ace>,@d<c26e>,@d<b188>,msbt+2,msbt,2,@f<14>,@s<2d>,@d<a39f>
	tstr	@v<0,10>,0,0,0,0,0,0,0,0,0		; (2 cycles)
	tstr	@v<0>,-1,0,0,0,0,0,0d7h,0,0		; (22 cycles)
	@c	eb59891b,e9ead0ae			; expected crc
	tmsg	@g'ldi<r> (2)'

; neg (16,384 cycles)
negop:	@m	0d7h					; flag mask
	tstr	@v<ed,44>,@d<38a2>,@d<5f6b>,@d<d934>,@d<57e4>,@d<d2d6>,@d<4642>,@f<43>,@s<5a>,@d<09cc>
	tstr	@v<0>,0,0,0,0,0,0,0d7h,-1,0		; (16,384 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0,0,0			; (1 cycle)
	@c	6a3c3bbd,d638dd6a			; expected crc
	tmsg	@g'neg'

; <rld,rrd> (7168 cycles)
rldop:	@m	0d7h					; flag mask
	tstr	@v<ed,67>,@d<91cb>,@d<c48b>,@d<fa62>,msbt,@d<e720>,@d<b479>,@f<40>,@s<06>,@d<8ae2>
	tstr	@v<0,8>,0ffh,0,0,0,0,0,0,0,0		; (512 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,-1,0		; (14 cycles)
	@c	955ba326,ff823e77			; expected crc
	tmsg	@g'<rrd,rld>'

; <rlca,rrca,rla,rra> (6144 cycles)
rot8080: @m	0d7h					; flag mask
	tstr	@v<7>,@d<cb92>,@d<6d43>,@d<0a90>,@d<c284>,@d<0c53>,@d<f50e>,@f<91>,@s<eb>,@d<40fc>
	tstr	@v<18>,0,0,0,0,0,0,0,-1,0		; (1024 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0d7h,0,0		; (6 cycles)
	@c	251330ae,9ba3807c			; expected crc
	tmsg	@g'<rlca,rrca,rla,rra>'

; shift/rotate (<ix,iy>+1) (416 cycles)
rotxy:	@m	0d7h					; flag mask
	tstr	@v<dd,cb,1,6>,@d<ddaf>,msbt-1,msbt-1,@d<ff3c>,@d<dbf6>,@d<94f4>,@f<82>,@s<80>,@d<61d9>
	tstr	@v<20,0,0,38>,0,0,0,0,0,0,080h,0,0	; (32 cycles)
	tstr	@v<0>,0ffh,0,0,0,0,0,057h,0,0		; (13 cycles)
	@c	713acd81,710034cb			; expected crc
	tmsg	@g'shf/rot (<ix,iy>+1)'

; shift/rotate <b,c,d,e,h,l,(hl),a> (6784 cycles)
rotz80:	@m	0d7h					; flag mask
	tstr	@v<cb>,@d<cceb>,@d<5d4a>,@d<e007>,msbt,@d<1395>,@d<30ee>,@f<43>,@s<78>,@d<3dad>
	tstr	@v<0,3f>,0,0,0,0,0,0,080h,0,0		; (128 cycles)
	tstr	@v<0>,0ffh,0,0,0,-1,-1,057h,-1,0	; (53 cycles)
	@c	eb604d58,a4255833			; expected crc
	tmsg	@g'shf/rot <b,c,d,e,h,l,(hl),a>'

; <set,res> n,<b,c,d,e,h,l,(hl),a> (7936 cycles)
srz80:	@m	0d7h					; flag mask
	tstr	@v<cb,80>,@d<2cd5>,@d<97ab>,@d<39ff>,msbt,@d<d14b>,@d<6ab2>,@f<53>,@s<27>,@d<b538>
	tstr	@v<0,7f>,0,0,0,0,0,0,0,0,0		; (128 cycles)
	tstr	@v<0>,0ffh,0,0,0,-1,-1,0d7h,-1,0	; (62 cycles)
	@c	8b57f008,8b57f008			; expected crc
	tmsg	@g'<set,res> n,<bcdehl(hl)a>'

; <set,res> n,(<ix,iy>+1) (1792 cycles)
srzx:	@m	0d7h					; flag mask
	tstr	@v<dd,cb,1,86>,@d<fb44>,msbt-1,msbt-1,@d<ba09>,@d<68be>,@d<32d8>,@f<10>,@s<5e>,@d<a867>
	tstr	@v<20,0,0,78>,0,0,0,0,0,0,0,0,0		; (128 cycles)
	tstr	@v<0>,0ffh,0,0,0,0,0,0d7h,0,0		;(14 cycles)
	@c	cc63f98a,cc63f98a			; expected crc
	tmsg	@g'<set,res> n,(<ix,iy>+1)'

; ld (<ix,iy>+1),<b,c,d,e> (1024 cycles)
st8ix1:	@m	0d7h					; flag mask
	tstr	@v<dd,70,1>,@d<270d>,msbt-1,msbt-1,@d<b73a>,@d<887b>,@d<99ee>,@f<86>,@s<70>,@d<ca07>
	tstr	@v<20,3>,0,1,1,0,0,0,0,0,0		; (32 cycles)
	tstr	@v<0>,0,0,0,0,-1,-1,0,0,0		; (32 cycles)
	@c	04626abf,04626abf			; expected crc
	tmsg	@g'ld (<ix,iy>+1),<b,c,d,e>'

; ld (<ix,iy>+1),<h,l> (256 cycles)
st8ix2:	@m	0d7h					; flag mask
	tstr	@v<dd,74,1>,@d<b664>,msbt-1,msbt-1,@d<e8ac>,@d<b5f5>,@d<aafe>,@f<12>,@s<10>,@d<9566>
	tstr	@v<20,1>,0,1,1,0,0,0,0,0,0		; (16 cycles)
	tstr	@v<0>,0,0,0,-1,0,0,0,0,0		; (32 cycles)
	@c	6a1a8831,6a1a8831			; expected crc
	tmsg	@g'ld (<ix,iy>+1),<h,l>'

; ld (<ix,iy>+1),a (64 cycles)
st8ix3:	@m	0d7h					; flag mask
	tstr	@v<dd,77,1>,@d<67af>,msbt-1,msbt-1,@d<4f13>,@d<0644>,@d<bcd7>,@f<50>,@s<ac>,@d<5faf>
	tstr	@v<20>,0,1,1,0,0,0,0,0,0		; (8 cycles)
	tstr	@v<0>,0,0,0,0,0,0,0,-1,0		; (8 cycles)
	@c	ccbe5a96,ccbe5a96			; expected crc
	tmsg	@g'ld (<ix,iy>+1),a'

; ld (<bc,de>),a (96 cycles)
stabd:	@m	0d7h					; flag mask
	tstr	@v<2>,@d<0c3b>,@d<b592>,@d<6cff>,@d<959e>,msbt,msbt+1,@f<c1>,@s<21>,@d<bde7>
	tstr	@v<18>,0,0,0,0,0,0,0,0,0		; (4 cycles)
	tstr	@v<0>,-1,0,0,0,0,0,0,-1,0		; (24 cycles)
	@c	7a4c114f,7a4c114f			; expected crc
	tmsg	@g'ld (<bc,de>),a'

; start test pointed to by (hl)
stt:	push	hl
	ld	a,(hl)		; get pointer to test
	inc	hl
	ld	h,(hl)
	ld	l,a
	ld	a,(hl)		; flag mask
	ld	(flgmsk+1),a
	inc	hl
	push	hl
	ld	de,20
	add	hl,de		; point to incmask
	ld	de,counter
	call	initmask
	pop	hl
	push	hl
	ld	de,20+20
	add	hl,de		; point to scanmask
	ld	de,shifter
	call	initmask
	ld	hl,shifter
	ld	(hl),1		; first bit
	pop	hl
	push	hl
	ld	de,iut		; copy initial instruction under test
	ld	bc,4
	ldir
	ld	de,msbt		; copy initial machine state
	ld	bc,16
	ldir
	ld	de,20+20+4	; skip incmask, scanmask and expcrc
	add	hl,de
	ex	de,hl
	ld	c,9
	call	bdos		; show test name
	call	initcrc		; initialise crc
; test loop
tlp:	ld	a,(iut)
	cp	076h		; pragmatically avoid halt intructions
	jp	z,tlp2
	and	a,0dfh
	cp	0ddh
	jp	nz,tlp1
	ld	a,(iut+1)
	cp	076h
tlp1:	call	nz,test		; execute the test instruction
tlp2:	call	count		; increment the counter
	call	nz,shift	; shift the scan bit
	pop	hl		; pointer to test case
	jp	z,tlp3		; done if shift returned NZ
	ld	de,20+20+20
	add	hl,de		; point to expected crc
	call	cmpcrc
	ld	de,okmsg
	jp	z,tlpok
	ld	de,ermsg1
	ld	c,9
	call	bdos
	call	phex8
	ld	de,ermsg2
	ld	c,9
	call	bdos
	ld	hl,crcval
	call	phex8
	ld	de,crlf
tlpok:	ld	c,9
	call	bdos
	pop	hl
	inc	hl
	inc	hl
	ret

tlp3:	push	hl
	ld	a,1		; initialise count and shift scanners
	ld	(cntbit),a
	ld	(shfbit),a
	ld	hl,counter
	ld	(cntbyt),hl
	ld	hl,shifter
	ld	(shfbyt),hl

	ld	b,4		; bytes in iut field
	pop	hl		; pointer to test case
	push	hl
	ld	de,iut
	call	setup		; setup iut
	ld	b,16		; bytes in machine state
	ld	de,msbt
	call	setup		; setup machine state
	jp	tlp

; setup a field of the test case
; b  = number of bytes
; hl = pointer to base case
; de = destination
setup:	call	subyte
	inc	hl
	dec	b
	jp	nz,setup
	ret

subyte:	push	bc
	push	de
	push	hl
	ld	c,(hl)		; get base byte
	ld	de,20
	add	hl,de		; point to incmask
	ld	a,(hl)
	cp	0
	jp	z,subshf
	ld	b,8		; 8 bits
subclp:	rrca
	push	af
	ld	a,0
	call	c,nxtcbit	; get next counter bit if mask bit was set
	xor	c		; flip bit if counter bit was set
	rrca
	ld	c,a
	pop	af
	dec	b
	jp	nz,subclp
	ld	b,8
subshf:	ld	de,20
	add	hl,de		; point to shift mask
	ld	a,(hl)
	cp	0
	jp	z,substr
	ld	b,8		; 8 bits
sbshf1:	rrca
	push	af
	ld	a,0
	call	c,nxtsbit	; get next shifter bit if mask bit was set
	xor	c		; flip bit if shifter bit was set
	rrca
	ld	c,a
	pop	af
	dec	b
	jp	nz,sbshf1
substr:	pop	hl
	pop	de
	ld	a,c
	ld	(de),a		; mangled byte to destination
	inc	de
	pop	bc
	ret

; get next counter bit in low bit of a
cntbit:	ds	1
cntbyt:	ds	2

nxtcbit: push	bc
	push	hl
	ld	hl,(cntbyt)
	ld	b,(hl)
	ld	hl,cntbit
	ld	a,(hl)
	ld	c,a
	rlca
	ld	(hl),a
	cp	a,1
	jp	nz,ncb1
	ld	hl,(cntbyt)
	inc	hl
	ld	(cntbyt),hl
ncb1:	ld	a,b
	and	c
	pop	hl
	pop	bc
	ret	z
	ld	a,1
	ret

; get next shifter bit in low bit of a
shfbit:	ds	1
shfbyt:	ds	2

nxtsbit: push	bc
	push	hl
	ld	hl,(shfbyt)
	ld	b,(hl)
	ld	hl,shfbit
	ld	a,(hl)
	ld	c,a
	rlca
	ld	(hl),a
	cp	a,1
	jp	nz,nsb1
	ld	hl,(shfbyt)
	inc	hl
	ld	(shfbyt),hl
nsb1:	ld	a,b
	and	c
	pop	hl
	pop	bc
	ret	z
	ld	a,1
	ret

; clear memory at hl, bc bytes
clrmem:	push	af
	push	bc
	push	de
	push	hl
	ld	(hl),0
	ld	d,h
	ld	e,l
	inc	de
	dec	bc
	ldir
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret

; initialise counter or shifter
; de = pointer to work area for counter or shifter
; hl = pointer to mask
initmask:
	push	de
	ex	de,hl
	ld	bc,20+20
	call	clrmem		; clear work area
	ex	de,hl
	ld	b,20		; byte counter
	ld	c,1		; first bit
	ld	d,0		; bit counter
imlp:	ld	e,(hl)
imlp1:	ld	a,e
	and	a,c
	jp	z,imlp2
	inc	d
imlp2:	ld	a,c
	rlca
	ld	c,a
	cp	a,1
	jp	nz,imlp1
	inc	hl
	dec	b
	jp	nz,imlp
; got number of 1-bits in mask in reg d
	ld	a,d
	and	0f8h
	rrca
	rrca
	rrca			; divide by 8 (get byte offset)
	ld	l,a
	ld	h,0
	ld	a,d
	and	a,7		; bit offset
	inc	a
	ld	b,a
	ld	a,080h
imlp3:	rlca
	dec	b
	jp	nz,imlp3
	pop	de
	add	hl,de
	ld	de,20
	add	hl,de
	ld	(hl),a
	ret

; multi-byte counter
count:	push	bc
	push	de
	push	hl
	ld	hl,counter	; 20 byte counter starts here
	ld	de,20		; somewhere in here is the stop bit
	ex	de,hl
	add	hl,de
	ex	de,hl
cntlp:	inc	(hl)
	ld	a,(hl)
	cp	0
	jp	z,cntlp1	; overflow to next byte
	ld	b,a
	ld	a,(de)
	and	a,b		; test for terminal value
	jp	z,cntend
	ld	(hl),0		; reset to zero
cntend:	pop	bc
	pop	de
	pop	hl
	ret

cntlp1:	inc	hl
	inc	de
	jp	cntlp

; multi-byte shifter
shift:	push	bc
	push	de
	push	hl
	ld	hl,shifter	; 20 byte shift register starts here
	ld	de,20		; somewhere in here is the stop bit
	ex	de,hl
	add	hl,de
	ex	de,hl
shflp:	ld	a,(hl)
	or	a
	jp	z,shflp1
	ld	b,a
	ld	a,(de)
	and	b
	jp	nz,shlpe
	ld	a,b
	rlca
	cp	a,1
	jp	nz,shflp2
	ld	(hl),0
	inc	hl
	inc	de
shflp2:	ld	(hl),a
	xor	a		; set Z
shlpe:	pop	hl
	pop	de
	pop	bc
	ret
shflp1:	inc	hl
	inc	de
	jp	shflp

counter: ds	2*20
shifter: ds	2*20

; test harness
test:	push	af
	push	bc
	push	de
	push	hl
	if	dbg_test
	ld	de,crlf
	ld	c,9
	call	bdos
	ld	hl,iut
	ld	b,4
	call	hexstr
	ld	e,' '
	ld	c,2
	call	bdos
	ld	b,16
	ld	hl,msbt
	call	hexstr
	endif
	di			; disable interrupts
	ld	(spsav),sp	; save stack pointer
	ld	sp,msbt+2	; point to test-case machine state
	pop	iy		; and load all regs
	pop	ix
	pop	hl
	pop	de
	pop	bc
	pop	af
	ld	sp,(spbt)
iut:	ds	4		; max 4 byte instruction under test
	ld	(spat),sp	; save stack pointer
	ld	sp,spat
	push	af		; save other registers
	push	bc
	push	de
	push	hl
	push	ix
	push	iy
	ld	sp,(spsav)	; restore stack pointer
	ei			; enable interrupts
	ld	hl,(msbt)	; copy memory operand
	ld	(msat),hl
	ld	hl,flgsat	; flags after test
	ld	a,(hl)
flgmsk:	and	a,0d7h		; mask-out irrelevant bits (self-modified code!)
	ld	(hl),a
	ld	b,16		; total of 16 bytes of state
	ld	de,msat
	ld	hl,crcval
tcrc:	ld	a,(de)
	inc	de
	call	updcrc		; accumulate crc of this test case
	dec	b
	jp	nz,tcrc
	if	dbg_tcrc
	ld	e,' '
	ld	c,2
	call	bdos
	ld	hl,crcval
	call	phex8
	ld	de,crlf
	ld	c,9
	call	bdos
	ld	hl,msat
	ld	b,16
	call	hexstr
	ld	de,crlf
	ld	c,9
	call	bdos
	endif
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret

; machine state after test
msat:	ds	14	; memop,iy,ix,hl,de,bc,af
spat:	ds	2	; stack pointer after test
; jgh: ZMAC/MAXAM doesn't like ':' after label with EQUs
flgsat	equ	spat-2	; flags

spsav:	ds	2	; saved stack pointer

; display hex string (pointer in hl, byte count in b)
hexstr:	ld	a,(hl)
	call	phex2
	inc	hl
	dec	b
	jp	nz,hexstr
	ret

; display hex
; display the big-endian 32-bit value pointed to by hl
phex8:	push	af
	push	bc
	push	hl
	ld	b,4
ph8lp:	ld	a,(hl)
	call	phex2
	inc	hl
	dec	b
	jp	nz,ph8lp
	pop	hl
	pop	bc
	pop	af
	ret

; display byte in a
phex2:	push	af
	rrca
	rrca
	rrca
	rrca
	call	phex1
	pop	af
; fall through

; display low nibble in a
phex1:	push	af
	push	bc
	push	de
	push	hl
	and	a,0fh
	cp	a,10
	jp	c,ph11
	add	a,'a'-'9'-1
ph11:	add	a,'0'
	ld	e,a
	ld	c,2
	call	bdos
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret

bdos	push	af
	push	bc
	push	de
	push	hl
	call	5
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret

msg1:	db	'Z80 @i instruction exerciser',10,13,'$'
msg2:	db	'Tests complete$'
okmsg:	db	'  OK',10,13,'$'
ermsg1:	db	'  ERROR **** crc expected:$'
ermsg2:	db	' found:$'
crlf:	db	10,13,'$'

; compare crc
; hl points to value to compare to crcval
cmpcrc:	push	bc
	push	de
	push	hl
	ld	de,crcval
	ld	b,4
cclp:	ld	a,(de)
	cp	a,(hl)
	jp	nz,cce
	inc	hl
	inc	de
	dec	b
	jp	nz,cclp
cce:	pop	hl
	pop	de
	pop	bc
	ret

; 32-bit crc routine
; entry: a contains next byte, hl points to crc
; exit:  crc updated
updcrc:	push	af
	push	bc
	push	de
	push	hl
	push	hl
	ld	de,3
	add	hl,de	; point to low byte of old crc
	xor	a,(hl)	; xor with new byte
	ld	l,a
	ld	h,0
	add	hl,hl	; use result as index into table of 4 byte entries
	add	hl,hl
	ex	de,hl
	ld	hl,crctab
	add	hl,de	; point to selected entry in crctab
	ex	de,hl
	pop	hl
	ld	bc,4	; c = byte count, b = accumulator
crclp:	ld	a,(de)
	xor	a,b
	ld	b,(hl)
	ld	(hl),a
	inc	de
	inc	hl
	dec	c
	jp	nz,crclp
	if	dbg_crclp
	ld	hl,crcval
	call	phex8
	ld	de,crlf
	ld	c,9
	call	bdos
	endif
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret

initcrc:push	af
	push	bc
	push	hl
	ld	hl,crcval
	ld	a,0ffh
	ld	b,4
icrclp:	ld	(hl),a
	inc	hl
	dec	b
	jp	nz,icrclp
	pop	hl
	pop	bc
	pop	af
	ret

crcval	ds	4

crctab:	db	000h,000h,000h,000h
	db	077h,007h,030h,096h
	db	0eeh,00eh,061h,02ch
	db	099h,009h,051h,0bah
	db	007h,06dh,0c4h,019h
	db	070h,06ah,0f4h,08fh
	db	0e9h,063h,0a5h,035h
	db	09eh,064h,095h,0a3h
	db	00eh,0dbh,088h,032h
	db	079h,0dch,0b8h,0a4h
	db	0e0h,0d5h,0e9h,01eh
	db	097h,0d2h,0d9h,088h
	db	009h,0b6h,04ch,02bh
	db	07eh,0b1h,07ch,0bdh
	db	0e7h,0b8h,02dh,007h
	db	090h,0bfh,01dh,091h
	db	01dh,0b7h,010h,064h
	db	06ah,0b0h,020h,0f2h
	db	0f3h,0b9h,071h,048h
	db	084h,0beh,041h,0deh
	db	01ah,0dah,0d4h,07dh
	db	06dh,0ddh,0e4h,0ebh
	db	0f4h,0d4h,0b5h,051h
	db	083h,0d3h,085h,0c7h
	db	013h,06ch,098h,056h
	db	064h,06bh,0a8h,0c0h
	db	0fdh,062h,0f9h,07ah
	db	08ah,065h,0c9h,0ech
	db	014h,001h,05ch,04fh
	db	063h,006h,06ch,0d9h
	db	0fah,00fh,03dh,063h
	db	08dh,008h,00dh,0f5h
	db	03bh,06eh,020h,0c8h
	db	04ch,069h,010h,05eh
	db	0d5h,060h,041h,0e4h
	db	0a2h,067h,071h,072h
	db	03ch,003h,0e4h,0d1h
	db	04bh,004h,0d4h,047h
	db	0d2h,00dh,085h,0fdh
	db	0a5h,00ah,0b5h,06bh
	db	035h,0b5h,0a8h,0fah
	db	042h,0b2h,098h,06ch
	db	0dbh,0bbh,0c9h,0d6h
	db	0ach,0bch,0f9h,040h
	db	032h,0d8h,06ch,0e3h
	db	045h,0dfh,05ch,075h
	db	0dch,0d6h,00dh,0cfh
	db	0abh,0d1h,03dh,059h
	db	026h,0d9h,030h,0ach
	db	051h,0deh,000h,03ah
	db	0c8h,0d7h,051h,080h
	db	0bfh,0d0h,061h,016h
	db	021h,0b4h,0f4h,0b5h
	db	056h,0b3h,0c4h,023h
	db	0cfh,0bah,095h,099h
	db	0b8h,0bdh,0a5h,00fh
	db	028h,002h,0b8h,09eh
	db	05fh,005h,088h,008h
	db	0c6h,00ch,0d9h,0b2h
	db	0b1h,00bh,0e9h,024h
	db	02fh,06fh,07ch,087h
	db	058h,068h,04ch,011h
	db	0c1h,061h,01dh,0abh
	db	0b6h,066h,02dh,03dh
	db	076h,0dch,041h,090h
	db	001h,0dbh,071h,006h
	db	098h,0d2h,020h,0bch
	db	0efh,0d5h,010h,02ah
	db	071h,0b1h,085h,089h
	db	006h,0b6h,0b5h,01fh
	db	09fh,0bfh,0e4h,0a5h
	db	0e8h,0b8h,0d4h,033h
	db	078h,007h,0c9h,0a2h
	db	00fh,000h,0f9h,034h
	db	096h,009h,0a8h,08eh
	db	0e1h,00eh,098h,018h
	db	07fh,06ah,00dh,0bbh
	db	008h,06dh,03dh,02dh
	db	091h,064h,06ch,097h
	db	0e6h,063h,05ch,001h
	db	06bh,06bh,051h,0f4h
	db	01ch,06ch,061h,062h
	db	085h,065h,030h,0d8h
	db	0f2h,062h,000h,04eh
	db	06ch,006h,095h,0edh
	db	01bh,001h,0a5h,07bh
	db	082h,008h,0f4h,0c1h
	db	0f5h,00fh,0c4h,057h
	db	065h,0b0h,0d9h,0c6h
	db	012h,0b7h,0e9h,050h
	db	08bh,0beh,0b8h,0eah
	db	0fch,0b9h,088h,07ch
	db	062h,0ddh,01dh,0dfh
	db	015h,0dah,02dh,049h
	db	08ch,0d3h,07ch,0f3h
	db	0fbh,0d4h,04ch,065h
	db	04dh,0b2h,061h,058h
	db	03ah,0b5h,051h,0ceh
	db	0a3h,0bch,000h,074h
	db	0d4h,0bbh,030h,0e2h
	db	04ah,0dfh,0a5h,041h
	db	03dh,0d8h,095h,0d7h
	db	0a4h,0d1h,0c4h,06dh
	db	0d3h,0d6h,0f4h,0fbh
	db	043h,069h,0e9h,06ah
	db	034h,06eh,0d9h,0fch
	db	0adh,067h,088h,046h
	db	0dah,060h,0b8h,0d0h
	db	044h,004h,02dh,073h
	db	033h,003h,01dh,0e5h
	db	0aah,00ah,04ch,05fh
	db	0ddh,00dh,07ch,0c9h
	db	050h,005h,071h,03ch
	db	027h,002h,041h,0aah
	db	0beh,00bh,010h,010h
	db	0c9h,00ch,020h,086h
	db	057h,068h,0b5h,025h
	db	020h,06fh,085h,0b3h
	db	0b9h,066h,0d4h,009h
	db	0ceh,061h,0e4h,09fh
	db	05eh,0deh,0f9h,00eh
	db	029h,0d9h,0c9h,098h
	db	0b0h,0d0h,098h,022h
	db	0c7h,0d7h,0a8h,0b4h
	db	059h,0b3h,03dh,017h
	db	02eh,0b4h,00dh,081h
	db	0b7h,0bdh,05ch,03bh
	db	0c0h,0bah,06ch,0adh
	db	0edh,0b8h,083h,020h
	db	09ah,0bfh,0b3h,0b6h
	db	003h,0b6h,0e2h,00ch
	db	074h,0b1h,0d2h,09ah
	db	0eah,0d5h,047h,039h
	db	09dh,0d2h,077h,0afh
	db	004h,0dbh,026h,015h
	db	073h,0dch,016h,083h
	db	0e3h,063h,00bh,012h
	db	094h,064h,03bh,084h
	db	00dh,06dh,06ah,03eh
	db	07ah,06ah,05ah,0a8h
	db	0e4h,00eh,0cfh,00bh
	db	093h,009h,0ffh,09dh
	db	00ah,000h,0aeh,027h
	db	07dh,007h,09eh,0b1h
	db	0f0h,00fh,093h,044h
	db	087h,008h,0a3h,0d2h
	db	01eh,001h,0f2h,068h
	db	069h,006h,0c2h,0feh
	db	0f7h,062h,057h,05dh
	db	080h,065h,067h,0cbh
	db	019h,06ch,036h,071h
	db	06eh,06bh,006h,0e7h
	db	0feh,0d4h,01bh,076h
	db	089h,0d3h,02bh,0e0h
	db	010h,0dah,07ah,05ah
	db	067h,0ddh,04ah,0cch
	db	0f9h,0b9h,0dfh,06fh
	db	08eh,0beh,0efh,0f9h
	db	017h,0b7h,0beh,043h
	db	060h,0b0h,08eh,0d5h
	db	0d6h,0d6h,0a3h,0e8h
	db	0a1h,0d1h,093h,07eh
	db	038h,0d8h,0c2h,0c4h
	db	04fh,0dfh,0f2h,052h
	db	0d1h,0bbh,067h,0f1h
	db	0a6h,0bch,057h,067h
	db	03fh,0b5h,006h,0ddh
	db	048h,0b2h,036h,04bh
	db	0d8h,00dh,02bh,0dah
	db	0afh,00ah,01bh,04ch
	db	036h,003h,04ah,0f6h
	db	041h,004h,07ah,060h
	db	0dfh,060h,0efh,0c3h
	db	0a8h,067h,0dfh,055h
	db	031h,06eh,08eh,0efh
	db	046h,069h,0beh,079h
	db	0cbh,061h,0b3h,08ch
	db	0bch,066h,083h,01ah
	db	025h,06fh,0d2h,0a0h
	db	052h,068h,0e2h,036h
	db	0cch,00ch,077h,095h
	db	0bbh,00bh,047h,003h
	db	022h,002h,016h,0b9h
	db	055h,005h,026h,02fh
	db	0c5h,0bah,03bh,0beh
	db	0b2h,0bdh,00bh,028h
	db	02bh,0b4h,05ah,092h
	db	05ch,0b3h,06ah,004h
	db	0c2h,0d7h,0ffh,0a7h
	db	0b5h,0d0h,0cfh,031h
	db	02ch,0d9h,09eh,08bh
	db	05bh,0deh,0aeh,01dh
	db	09bh,064h,0c2h,0b0h
	db	0ech,063h,0f2h,026h
	db	075h,06ah,0a3h,09ch
	db	002h,06dh,093h,00ah
	db	09ch,009h,006h,0a9h
	db	0ebh,00eh,036h,03fh
	db	072h,007h,067h,085h
	db	005h,000h,057h,013h
	db	095h,0bfh,04ah,082h
	db	0e2h,0b8h,07ah,014h
	db	07bh,0b1h,02bh,0aeh
	db	00ch,0b6h,01bh,038h
	db	092h,0d2h,08eh,09bh
	db	0e5h,0d5h,0beh,00dh
	db	07ch,0dch,0efh,0b7h
	db	00bh,0dbh,0dfh,021h
	db	086h,0d3h,0d2h,0d4h
	db	0f1h,0d4h,0e2h,042h
	db	068h,0ddh,0b3h,0f8h
	db	01fh,0dah,083h,06eh
	db	081h,0beh,016h,0cdh
	db	0f6h,0b9h,026h,05bh
	db	06fh,0b0h,077h,0e1h
	db	018h,0b7h,047h,077h
	db	088h,008h,05ah,0e6h
	db	0ffh,00fh,06ah,070h
	db	066h,006h,03bh,0cah
	db	011h,001h,00bh,05ch
	db	08fh,065h,09eh,0ffh
	db	0f8h,062h,0aeh,069h
	db	061h,06bh,0ffh,0d3h
	db	016h,06ch,0cfh,045h
	db	0a0h,00ah,0e2h,078h
	db	0d7h,00dh,0d2h,0eeh
	db	04eh,004h,083h,054h
	db	039h,003h,0b3h,0c2h
	db	0a7h,067h,026h,061h
	db	0d0h,060h,016h,0f7h
	db	049h,069h,047h,04dh
	db	03eh,06eh,077h,0dbh
	db	0aeh,0d1h,06ah,04ah
	db	0d9h,0d6h,05ah,0dch
	db	040h,0dfh,00bh,066h
	db	037h,0d8h,03bh,0f0h
	db	0a9h,0bch,0aeh,053h
	db	0deh,0bbh,09eh,0c5h
	db	047h,0b2h,0cfh,07fh
	db	030h,0b5h,0ffh,0e9h
	db	0bdh,0bdh,0f2h,01ch
	db	0cah,0bah,0c2h,08ah
	db	053h,0b3h,093h,030h
	db	024h,0b4h,0a3h,0a6h
	db	0bah,0d0h,036h,005h
	db	0cdh,0d7h,006h,093h
	db	054h,0deh,057h,029h
	db	023h,0d9h,067h,0bfh
	db	0b3h,066h,07ah,02eh
	db	0c4h,061h,04ah,0b8h
	db	05dh,068h,01bh,002h
	db	02ah,06fh,02bh,094h
	db	0b4h,00bh,0beh,037h
	db	0c3h,00ch,08eh,0a1h
	db	05ah,005h,0dfh,01bh
	db	02dh,002h,0efh,08dh

	end


__END__


#-----------------------------------------------------------------------------
#----------------------  Documentation / Usage / Help  -----------------------

=head1 NAME

 z80exer.pl - Generate Z80 instruction set exerciser

=head1 SYNOPSIS

z80exer.pl [options]

=head1 OPTIONS

=over 8

=item B<--help>

Print options and arguments instead of generate code and exits.

=item B<--man>

Prints complete man page instead of generate code and exits.

=item B<--versions>

Add a version overview at the end of the generated assembler code.

=item B<--all>

Generate the full-flag version with all possible Z80 instructions,
inclusive the undocumented.

Default is the documented-flag version when this option is not set.

=item B<--msgl=length>

Set the length of each test case message. Default is 30 characters.

=item B<--rand>

Randomises all the initial machine states in each test case.

Default is to use all the predefined machine states when this option
is not set.

=item B<--zmac>

Generate syntax for ZMAC Z80 Macro Assembler and MAXAM Assembler.

Default is to generate syntax for the Microsoft MACRO-80 Assembler
when this option is not set.

=back

=head1 DESCRIPTION

B<This program> generates either the full-flag or documented-flag
version of the Z80 instruction exerciser, and also randomises the
initial machine states in each test case.

Switches that don't define a value can be done in long or short form.
eg:

    z80exer.pl --man
    z80exer.pl -m

=cut
