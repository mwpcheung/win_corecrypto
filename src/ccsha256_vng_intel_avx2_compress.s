# 
#  Copyright (c) 2014,2015 Apple Inc. All rights reserved.
#  
#  corecrypto Internal Use License Agreement
#  
#  IMPORTANT:  This Apple corecrypto software is supplied to you by Apple Inc. ("Apple")
#  in consideration of your agreement to the following terms, and your download or use
#  of this Apple software constitutes acceptance of these terms.  If you do not agree
#  with these terms, please do not download or use this Apple software.
#  
#  1.	As used in this Agreement, the term "Apple Software" collectively means and
#  includes all of the Apple corecrypto materials provided by Apple here, including
#  but not limited to the Apple corecrypto software, frameworks, libraries, documentation
#  and other Apple-created materials. In consideration of your agreement to abide by the
#  following terms, conditioned upon your compliance with these terms and subject to
#  these terms, Apple grants you, for a period of ninety (90) days from the date you
#  download the Apple Software, a limited, non-exclusive, non-sublicensable license
#  under Apple’s copyrights in the Apple Software to make a reasonable number of copies
#  of, compile, and run the Apple Software internally within your organization only on
#  devices and computers you own or control, for the sole purpose of verifying the
#  security characteristics and correct functioning of the Apple Software; provided
#  that you must retain this notice and the following text and disclaimers in all
#  copies of the Apple Software that you make. You may not, directly or indirectly,
#  redistribute the Apple Software or any portions thereof. The Apple Software is only
#  licensed and intended for use as expressly stated above and may not be used for other
#  purposes or in other contexts without Apple's prior written permission.  Except as
#  expressly stated in this notice, no other rights or licenses, express or implied, are
#  granted by Apple herein.
#  
#  2.	The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
#  WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES
#  OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
#  THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS,
#  SYSTEMS, OR SERVICES. APPLE DOES NOT WARRANT THAT THE APPLE SOFTWARE WILL MEET YOUR
#  REQUIREMENTS, THAT THE OPERATION OF THE APPLE SOFTWARE WILL BE UNINTERRUPTED OR
#  ERROR-FREE, THAT DEFECTS IN THE APPLE SOFTWARE WILL BE CORRECTED, OR THAT THE APPLE
#  SOFTWARE WILL BE COMPATIBLE WITH FUTURE APPLE PRODUCTS, SOFTWARE OR SERVICES. NO ORAL
#  OR WRITTEN INFORMATION OR ADVICE GIVEN BY APPLE OR AN APPLE AUTHORIZED REPRESENTATIVE
#  WILL CREATE A WARRANTY. 
#  
#  3.	IN NO EVENT SHALL APPLE BE LIABLE FOR ANY DIRECT, SPECIAL, INDIRECT, INCIDENTAL
#  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
#  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING
#  IN ANY WAY OUT OF THE USE, REPRODUCTION, COMPILATION OR OPERATION OF THE APPLE
#  SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING
#  NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
#  POSSIBILITY OF SUCH DAMAGE.
#  
#  4.	This Agreement is effective until terminated. Your rights under this Agreement will
#  terminate automatically without notice from Apple if you fail to comply with any term(s)
#  of this Agreement.  Upon termination, you agree to cease all use of the Apple Software
#  and destroy all copies, full or partial, of the Apple Software. This Agreement will be
#  governed and construed in accordance with the laws of the State of California, without
#  regard to its choice of law rules.
#  
#  You may report security issues about Apple products to product-security@apple.com,
#  as described here:  https://www.apple.com/support/security/.  Non-security bugs and
#  enhancement requests can be made via https://bugreport.apple.com as described
#  here: https://developer.apple.com/bug-reporting/
#  
#  EA1350
#  10/5/15
# 

#ifndef __NO_ASM__

/*
	the order of 2nd and 3rd calling arguments is different from the xnu implementation
 */

#include <corecrypto/cc_config.h>

#if CCSHA2_VNG_INTEL

/*
	This file provides x86_64 hand implementation of the following function

	sha2_void sha256_compile(sha256_ctx ctx[1]);

	which is a C function in CommonCrypto Source/Digest/sha2.c

	The implementation here is modified from another sha256 x86_64 implementation for sha256 in the xnu.
	To modify to fit the new API,
		the old ctx (points to ctx->hashes) shoule be changed to ctx->hashes, 8(ctx).
		the old data (points to ctx->wbuf), should be changed to ctx->wbuf, 40(ctx).

	sha256_compile handles 1 input block (64 bytes) per call.


	The following is comments for the initial xnu-sha256.s.

	void SHA256_Transform(SHA256_ctx *ctx, char *data, unsigned int num_blocks);

	which is a C function in sha2.c (from xnu).

	sha256 algorithm per block description:

		1. W(0:15) = big-endian (per 4 bytes) loading of input data (64 byte)
		2. load 8 digests a-h from ctx->state
		3. for r = 0:15
				T1 = h + Sigma1(e) + Ch(e,f,g) + K[r] + W[r];
				d += T1;
				h = T1 + Sigma0(a) + Maj(a,b,c)
				permute a,b,c,d,e,f,g,h into h,a,b,c,d,e,f,g
		4. for r = 16:63
				W[r] = W[r-16] + sigma1(W[r-2]) + W[r-7] + sigma0(W[r-15]);
				T1 = h + Sigma1(e) + Ch(e,f,g) + K[r] + W[r];
				d += T1;
				h = T1 + Sigma0(a) + Maj(a,b,c)
				permute a,b,c,d,e,f,g,h into h,a,b,c,d,e,f,g

	In the assembly implementation:
		- a circular window of message schedule W(r:r+15) is updated and stored in xmm0-xmm3
		- its corresponding W+K(r:r+15) is updated and stored in a stack space circular buffer
		- the 8 digests (a-h) will be stored in GPR or m32 (all in GPR for x86_64, and some in m32 for i386)

	the implementation per block looks like

	----------------------------------------------------------------------------

	load W(0:15) (big-endian per 4 bytes) into xmm0:xmm3
	pre_calculate and store W+K(0:15) in stack

	load digests a-h from ctx->state;

	for (r=0;r<48;r+=4) {
		digests a-h update and permute round r:r+3
		update W([r:r+3]%16) and WK([r:r+3]%16) for the next 4th iteration
	}

	for (r=48;r<64;r+=4) {
		digests a-h update and permute round r:r+3
	}

	ctx->states += digests a-h;

	----------------------------------------------------------------------------

	our implementation (allows multiple blocks per call) pipelines the loading of W/WK of a future block
	into the last 16 rounds of its previous block:

	----------------------------------------------------------------------------

	load W(0:15) (big-endian per 4 bytes) into xmm0:xmm3
	pre_calculate and store W+K(0:15) in stack

L_loop:

	load digests a-h from ctx->state;

	for (r=0;r<48;r+=4) {
		digests a-h update and permute round r:r+3
		update W([r:r+3]%16) and WK([r:r+3]%16) for the next 4th iteration
	}

	num_block--;
	if (num_block==0)	jmp L_last_block;

	for (r=48;r<64;r+=4) {
		digests a-h update and permute round r:r+3
		load W([r:r+3]%16) (big-endian per 4 bytes) into xmm0:xmm3
		pre_calculate and store W+K([r:r+3]%16) in stack
	}

	ctx->states += digests a-h;

	jmp	L_loop;

L_last_block:

	for (r=48;r<64;r+=4) {
		digests a-h update and permute round r:r+3
	}

	ctx->states += digests a-h;

	------------------------------------------------------------------------

	Apple CoreOS vector & numerics
*/
#if defined __x86_64__


/*
	I removed the cpu capabilities check for the CC_KERNEL version of this code
	This code is being used in a KEXT and the ability to load the address of
	__cpu_capabilities@GOTPCREL(%rip) is not available.  The fix for this
	was to add entry points into this routine for the SSE3 and NO_SSE3 
	processing and have a C function in the KEXT to the capability 
	checking.  
	
	The C code is as follows:
	
	void ccsha256_vng_intel_compress(ccdigest_state_t state, unsigned long nblocks, const void *in)
	{
	    // I need to add code here of the ilk
	    if (((cpuid_features() & CPUID_FEATURE_SSE3) != 0))
	    {
	        ccsha256_vng_intel_sse3_compress(state, nblocks, in);
	    }
	    else
	    {
	        ccsha256_vng_intel_nossse3_compress(state, nblocks, in);
	    }    
	}
*/

	// associate variables with registers or memory

	#define	sp			%rsp

	#define	ctx			%rdi
	#define	data        %rdx

	#define	a			%r8d
	#define	b			%r9d
	#define	c			%r10d
	#define	d			%r11d
	#define	e			%r12d
	#define	f			%r13d
	#define	g			%r14d
	#define	h			%r15d

	#define	K			%rbx
	#define stack_size	(16+8+16*8+16+64)	// 8 (align) + xmm0:xmm7 + L_aligned_bswap + WK(0:15)

	#define	L_aligned_bswap	64(sp)		// bswap : big-endian loading of 4-byte words
	#define	xmm_save	80(sp)			// starting address for xmm save/restore
	#define	num_blocks	(16*8+80)(sp)
	#define	_ctx		(8+16*8+80)(sp) 

	// local variables
	#define	s	%eax
	#define	t	%ecx
	#define	u	%ebp
	#define	y0	%eax
	#define	y1	%ecx
	#define	y2	%ebp
	#define	y3	%esi
	#define	T1	%edi

	// a window (16 words) of message scheule
	#define	W0	%xmm0
	#define	W1	%xmm1
	#define	W2	%xmm2
	#define	W3	%xmm3

	// circular buffer for WK[(r:r+15)%16]
	#define WK(x)   (x&15)*4(sp)

// #define Ch(x,y,z)   (((x) & (y)) ^ ((~(x)) & (z)))

	.macro Ch
	mov		$0, t		// x
	mov		$0, s		// x
	not		t			// ~x
	and		$1, s		// x & y
	and		$2, t		// ~x & z
	xor		s, t		// t = ((x) & (y)) ^ ((~(x)) & (z));
	.endm

// #define Maj(x,y,z)  (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))

	.macro	Maj
#if 1		// steve's suggestion
	mov	 	$1,	t // y
	mov		$2,	s // z
	xor		$2,	t // y^z
	and		$1,	s // y&z
	and		$0, 	t // x&(y^z)
	xor		s,	t // Maj(x,y,z)
#else
	mov		$0, t		// x
	mov		$1, s		// y
	and		s, t		// x&y
	and		$2, s		// y&z
	xor		s, t		// (x&y) ^ (y&z)
	mov		$2, s		// z
	and		$0, s		// (x&z)
	xor		s, t		// t = (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
#endif
	.endm

// #define sigma0_256(x)   (S32(7,  (x)) ^ S32(18, (x)) ^ R(3 ,   (x)))

	// performs sigma0_256 on 4 words on an xmm registers
	// use xmm6/xmm7 as intermediate registers
	.macro	sigma0
	movdqa	$0, %xmm6
	movdqa	$0, %xmm7
	psrld	$$3, $0			// SHR3(x)
	psrld	$$7, %xmm6		// part of ROTR7
	pslld	$$14, %xmm7		// part of ROTR18
	pxor	%xmm6, $0
	pxor	%xmm7, $0
	psrld	$$11, %xmm6		// part of ROTR18
	pslld	$$11, %xmm7		// part of ROTR7
	pxor	%xmm6, $0
	pxor	%xmm7, $0
	.endm

// #define sigma1_256(x)   (S32(17, (x)) ^ S32(19, (x)) ^ R(10,   (x)))

	// performs sigma1_256 on 4 words on an xmm registers
	// use xmm6/xmm7 as intermediate registers
	.macro	sigma1
	movdqa	$0, %xmm6
	movdqa	$0, %xmm7
	psrld	$$10, $0		// SHR10(x)
	psrld	$$17, %xmm6		// part of ROTR17
	pxor	%xmm6, $0
	pslld	$$13, %xmm7		// part of ROTR19
	pxor	%xmm7, $0
	psrld	$$2, %xmm6		// part of ROTR19
	pxor	%xmm6, $0
	pslld	$$2, %xmm7		// part of ROTR17
	pxor	%xmm7, $0
	.endm

// #define Sigma0_256(x)   (S32(2,  (x)) ^ S32(13, (x)) ^ S32(22, (x)))

	.macro	Sigma0
	mov		$0, t			// x
	mov		$0, s			// x
	ror		$$2, t			// S32(2,  (x))
	ror		$$13, s			// S32(13,  (x))
	xor		s, t			// S32(2,  (x)) ^ S32(13, (x))
	ror		$$9, s			// S32(22,  (x))
	xor		s, t			// t = (S32(2,  (x)) ^ S32(13, (x)) ^ S32(22, (x)))
	.endm

// #define Sigma1_256(x)   (S32(6,  (x)) ^ S32(11, (x)) ^ S32(25, (x)))

	.macro	Sigma1
	mov		$0, s			// x
	ror		$$6, s			// S32(6,  (x))
	mov		s, t			// S32(6,  (x))
	ror		$$5, s			// S32(11, (x))
	xor		s, t			// S32(6,  (x)) ^ S32(11, (x))
	ror		$$14, s			// S32(25, (x))
	xor		s, t			// t = (S32(6,  (x)) ^ S32(11, (x)) ^ S32(25, (x)))
	.endm

	// per round digests update
	.macro	round_ref
	Sigma1	$4				// t = T1
	add		t, $7			// use h to store h+Sigma1(e)
	Ch		$4, $5, $6		// t = Ch (e, f, g);
	add		$7, t			// t = h+Sigma1(e)+Ch(e,f,g);
	add		WK($8), t		// h = T1
	add		t, $3			// d += T1;
	mov		t, $7			// h = T1
	Sigma0	$0				// t = Sigma0(a);
	add		t, $7			// h = T1 + Sigma0(a);
	Maj		$0, $1, $2		// t = Maj(a,b,c)
	add		t, $7			// h = T1 + Sigma0(a) + Maj(a,b,c);
	.endm

	/*
		it's possible to use shrd to operate like ror { ror n, eax == shrd n, eax, eax }
		On Westmere/Clarkdale, ror runs significantly better than shrd
		On SNB, shrd is largely improved, and it runs better than ror does
		On IVB, ror is improved, and ror and shrd performs abpout the same
		On hsw, shrd is a bit better than ror

		Therefore, on pre-SNB processors, we should use ror. For SNB and later, we recommend to use shrd for the purpose of ror.

	*/

	// update the message schedule W and W+K (4 rounds) 16 rounds ahead in the future
	.macro	message_schedule
	movdqu	(K), %xmm5
	addq	$$16, K				// K points to next K256 word for next iteration
	movdqa	$1, %xmm4 			// W7:W4
	palignr	$$4, $0, %xmm4		// W4:W1
	movdqa	%xmm4, %xmm6
	movdqa	%xmm4, %xmm7
	psrld	$$3, %xmm4			// SHR3(x)
	psrld	$$7, %xmm6		// part of ROTR7
	pslld	$$14, %xmm7		// part of ROTR18
	pxor	%xmm6, %xmm4
	pxor	%xmm7, %xmm4
	psrld	$$11, %xmm6		// part of ROTR18
	pslld	$$11, %xmm7		// part of ROTR7
	pxor	%xmm6, %xmm4
	pxor	%xmm7, %xmm4
	movdqa	$3, %xmm6 			// W15:W12
	paddd	%xmm4, $0			// $0 = W3:W0 + sigma0(W4:W1)
	palignr	$$4, $2, %xmm6		// W12:W9
	paddd	%xmm6, $0			// $0 = W12:W9 + sigma0(W4:W1) + W3:W0
	movdqa	$3, %xmm4			// W15:W12
	psrldq	$$8, %xmm4			// 0,0,W15,W14
	movdqa	%xmm4, %xmm6
	movdqa	%xmm4, %xmm7
	psrld	$$10, %xmm4		// SHR10(x)
	psrld	$$17, %xmm6		// part of ROTR17
	pxor	%xmm6, %xmm4
	pslld	$$13, %xmm7		// part of ROTR19
	pxor	%xmm7, %xmm4
	psrld	$$2, %xmm6		// part of ROTR19
	pxor	%xmm6, %xmm4
	pslld	$$2, %xmm7		// part of ROTR17
	pxor	%xmm7, %xmm4
	paddd	%xmm4, $0			// sigma1(0,0,W15,W14) + W12:W9 + sigma0(W4:W1) + W3:W0
	movdqa	$0, %xmm4			// W19-sigma1(W17), W18-sigma1(W16), W17, W16
	pslldq	$$8, %xmm4			// W17, W16, 0, 0
	movdqa	%xmm4, %xmm6
	movdqa	%xmm4, %xmm7
	psrld	$$10, %xmm4		// SHR10(x)
	psrld	$$17, %xmm6		// part of ROTR17
	pxor	%xmm6, %xmm4
	pslld	$$13, %xmm7		// part of ROTR19
	pxor	%xmm7, %xmm4
	psrld	$$2, %xmm6		// part of ROTR19
	pxor	%xmm6, %xmm4
	pslld	$$2, %xmm7		// part of ROTR17
	pxor	%xmm7, %xmm4
	paddd	%xmm4, $0			// W19:W16
	paddd	$0, %xmm5			// WK
	movdqa	%xmm5, WK($4)
	.endm

	// this macro is used in the last 16 rounds of a current block
	// it reads the next message (16 4-byte words), load it into 4 words W[r:r+3], computes WK[r:r+3]
	// and save into stack to prepare for next block

	.macro	update_W_WK
	movdqu	$0*16(data), $1		// read 4 4-byte words
	pshufb	L_aligned_bswap, $1	// big-endian of each 4-byte word, W[r:r+3]
	movdqu	$0*16(K), %xmm4		// K[r:r+3]
	paddd	$1, %xmm4			// WK[r:r+3]
	movdqa	%xmm4, WK($0*4)		// save WK[r:r+3] into stack circular buffer
	.endm

	.macro	roundsA_schedule
	// round	a, b, c, d, e, f, g, h, 0+$4
	mov		a, y3
		vpalignr	$$4, $2, $3, %xmm6		// w[r-7]
	rorx	$$25, e, y0
	rorx	$$11, e, y1
		vpalignr	$$4, $0, $1, %xmm4		// w[r-15], to be applied to sigma0 = ror7 ^ ror18 ^ shr3
	add		WK(0+$4), h
	or		c, y3
	mov		f, y2
	rorx	$$13, a, T1
		vpaddd		%xmm6, $0, $0			// $0 = w[r] = w[r-16] +w[r-7]
	xor		y1, y0
	xor		g, y2
		vpslld	$$14, %xmm4, %xmm7		// part of ROTR18
	rorx	$$6, e, y1
	and		e, y2
	xor		y1, y0
		vpsrld	$$7, %xmm4, %xmm6		// part of ROTR7
	rorx	$$22, a, y1
	add		h, d
	and		b, y3
	xor		T1, y1
		vpsrld	$$3, %xmm4, %xmm4			// SHR3(x)
	rorx	$$2, a, T1
	xor		g, y2
	xor		T1, y1
	mov		a, T1
		vpxor	%xmm7, %xmm4, %xmm4
	and		c, T1
	add		y0, y2
	or		T1, y3
	add		y1, h
		vpslld	$$11, %xmm7, %xmm7		// part of ROTR7
	add		y2, d
	add		y2, h
	add		y3, h
		vpxor	%xmm6, %xmm4, %xmm4


	// round	h, a, b, c, d, e, f, g, 1+$4
	mov		h, y3
	rorx	$$25, d, y0
	rorx	$$11, d, y1
		vpsrld	$$11, %xmm6, %xmm6		// part of ROTR18
	add		WK(1+$4), g
	mov		e, y2
	or		b, y3
	rorx	$$13, h, T1
		vpxor	%xmm7, %xmm4, %xmm4
	xor		y1, y0
	xor		f, y2
	rorx	$$6, d, y1
	and		d, y2
	xor		y1, y0
	rorx	$$22, h, y1
		vpxor	%xmm6, %xmm4, %xmm4
	add		g, c
	and		a, y3
	xor		T1, y1
	rorx	$$2, h, T1
		vpaddd	%xmm4, $0, $0			// $0 = W3:W0 + sigma0(W4:W1)
	xor		f, y2
	xor		T1, y1
	mov		h, T1
	add		y0, y2
	and		b, T1
		vunpckhps	$3, $3, %xmm7
	or		T1, y3
	add		y1, g
	add		y2, c
	add		y2, g
	add		y3, g
		vpsrld		$$10, $3, %xmm4		// part of ROTR19



	// round	g, h, a, b, c, d, e, f, 2+$4
	mov		g, y3
		vpsrlq		$$17, %xmm7, %xmm6
	rorx	$$25, c, y0
	rorx	$$11, c, y1
	add		WK(2+$4), f
		vpsrlq		$$19, %xmm7, %xmm7
	or		a, y3
	mov		d, y2
	rorx	$$13, g, T1
	xor		y1, y0
		vpxor		%xmm7, %xmm6, %xmm6
	xor		e, y2
	rorx	$$6, c, y1
	and		c, y2
	xor		y1, y0
	rorx	$$22, g, y1
		vpshufd		$$0x80, %xmm6, %xmm6 
	add		f, b
	and		h, y3
	xor		T1, y1
	rorx	$$2, g, T1
		vpxor		%xmm6, %xmm4, %xmm4
	xor		e, y2
	xor		T1, y1
	mov		g, T1
	and		a, T1
		vpsrldq		$$8, %xmm4, %xmm4			// 0,0,W15,W14
	add		y0, y2
	or		T1, y3
	add		y1, f
		vpaddd	%xmm4, $0, $0			// sigma1(0,0,W15,W14) + W12:W9 + sigma0(W4:W1) + W3:W0
	add		y2, b
	add		y2, f
	add		y3, f



	// round	f, g, h, a, b, c, d, e, 3+$4
		vunpcklps	$0, $0, %xmm7
	mov		f, y3
	rorx	$$25, b, y0
	rorx	$$11, b, y1
		vpsrld		$$10, $0, %xmm4		// part of ROTR19
	add		WK(3+$4), e
	or		h, y3
	mov		c, y2
		vpsrlq		$$17, %xmm7, %xmm6
	rorx	$$13, f, T1
	xor		y1, y0
	xor		d, y2
		vpsrlq		$$19, %xmm7, %xmm7
	rorx	$$6, b, y1
	and		b, y2
	xor		y1, y0
	rorx	$$22, f, y1
		vpxor		%xmm7, %xmm6, %xmm6
	add		e, a
	and		g, y3
	xor		T1, y1
		vpshufd		$$0x08, %xmm6, %xmm6 
	rorx	$$2, f, T1
	xor		d, y2
	xor		T1, y1
	mov		f, T1
		vpxor		%xmm6, %xmm4, %xmm4
	and		h, T1
	add		y0, y2
	or		T1, y3
		vpslldq		$$8, %xmm4, %xmm4
	add		y1, e
	add		y2, a
		vpaddd	%xmm4, $0, $0			// W19:W16
		vpaddd	(K), $0, %xmm4			// WK
	add		y2, e
	add		y3, e

		add		$$16, K
		vmovdqa	%xmm4, WK($4)
	.endm

	.macro	roundsE_schedule
	// round	e, f, g, h, a, b, c, d, 0+$4

	mov		e, y3
		vpalignr	$$4, $2, $3, %xmm6		// W12:W9
	rorx	$$25, a, y0
	rorx	$$11, a, y1
		vpalignr	$$4, $0, $1, %xmm4		// W4:W1
	add		WK(0+$4), d
	or		g, y3
	mov		b, y2
	rorx	$$13, e, T1
		vpslld	$$14, %xmm4, %xmm7		// part of ROTR18
	xor		y1, y0
	xor		c, y2
		vpaddd	%xmm6, $0, $0			// $0 = W12:W9 + sigma0(W4:W1) + W3:W0
	rorx	$$6, a, y1
	and		a, y2
		vpsrld	$$7, %xmm4, %xmm6		// part of ROTR7
	xor		y1, y0
	rorx	$$22, e, y1
		vpsrld	$$3, %xmm4, %xmm4			// SHR3(x)
	add		d, h
	and		f, y3
	xor		T1, y1
	rorx	$$2, e, T1
		vpxor	%xmm6, %xmm4, %xmm4
	xor		c, y2
	xor		T1, y1
		vpsrld	$$11, %xmm6, %xmm6		// part of ROTR18
	mov		e, T1
	and		g, T1
		vpxor	%xmm7, %xmm4, %xmm4
	add		y0, y2
	or		T1, y3
		vpslld	$$11, %xmm7, %xmm7		// part of ROTR7
	add		y1, d
	add		y2, h
	add		y2, d
		vpxor	%xmm6, %xmm4, %xmm4
	add		y3, d


	// round	d, e, f, g, h, a, b, c, 1+$4
	mov		d, y3
	rorx	$$25, h, y0
		vpxor	%xmm7, %xmm4, %xmm4
	rorx	$$11, h, y1
	add		WK(1+$4), c
	or		f, y3
	mov		a, y2
	rorx	$$13, d, T1
		vpaddd	%xmm4, $0, $0			// $0 = W3:W0 + sigma0(W4:W1)
	xor		y1, y0
	xor		b, y2
	rorx	$$6, h, y1
		vunpckhps	$3, $3, %xmm7
	and		h, y2
	xor		y1, y0
	rorx	$$22, d, y1
		vpsrld		$$10, $3, %xmm4		// part of ROTR19
	add		c, g
	and		e, y3
	xor		T1, y1
	rorx	$$2, d, T1
		vpsrlq		$$17, %xmm7, %xmm6
	xor		b, y2
	xor		T1, y1
		vpsrlq		$$19, %xmm7, %xmm7
	mov		d, T1
	and		f, T1
	add		y0, y2
	or		T1, y3
		vpxor		%xmm7, %xmm6, %xmm6
	add		y1, c
	add		y2, g
	add		y2, c
	add		y3, c

		vpshufd		$$0x80, %xmm6, %xmm6 

	//round	c, d, e, f, g, h, a, b, 2+$4
	mov		c, y3
	rorx	$$25, g, y0
	rorx	$$11, g, y1
	add		WK(2+$4), b
		vpxor		%xmm6, %xmm4, %xmm4
	or		e, y3
	mov		h, y2
	rorx	$$13, c, T1
	xor		y1, y0
		vpsrldq		$$8, %xmm4, %xmm4			// 0,0,W15,W14
	xor		a, y2
	rorx	$$6, g, y1
	and		g, y2
	xor		y1, y0
	rorx	$$22, c, y1
		vpaddd	%xmm4, $0, $0			// sigma1(0,0,W15,W14) + W12:W9 + sigma0(W4:W1) + W3:W0
	add		b, f
	and		d, y3
	xor		T1, y1
	rorx	$$2, c, T1
		vunpcklps	$0, $0, %xmm7
	xor		a, y2
	xor		T1, y1
	mov		c, T1
		vpsrld		$$10, $0, %xmm4		// part of ROTR19
	and		e, T1
	add		y0, y2
	or		T1, y3
		vpsrlq		$$17, %xmm7, %xmm6
	add		y1, b
	add		y2, f
	add		y2, b
	add		y3, b
		vpsrlq		$$19, %xmm7, %xmm7

	// round	b, c, d, e, f, g, h, a, 3+$4
	mov		b, y3
	rorx	$$25, f, y0
	rorx	$$11, f, y1
	add		WK(3+$4), a
	or		d, y3
		vpxor		%xmm7, %xmm6, %xmm6
	mov		g, y2
	rorx	$$13, b, T1
	xor		y1, y0
	xor		h, y2
	rorx	$$6, f, y1
		vpshufd		$$0x08, %xmm6, %xmm6 
	and		f, y2
	xor		y1, y0
	rorx	$$22, b, y1
	add		a, e
		vpxor		%xmm6, %xmm4, %xmm4
	and		c, y3
	xor		T1, y1
	rorx	$$2, b, T1
	xor		h, y2
		vpslldq		$$8, %xmm4, %xmm4
	xor		T1, y1
	mov		b, T1
	and		d, T1
	add		y0, y2
	or		T1, y3
		vpaddd	%xmm4, $0, $0			// W19:W16
	add		y1, a
	add		y2, e
	add		y2, a
		vpaddd	(K), $0, %xmm4			// WK
	add		y3, a
		add		$$16, K
		vmovdqa	%xmm4, WK($4)

	.endm

	.macro	roundsA_update
	// round	a, b, c, d, e, f, g, h, 0+$0
		vmovdqu	(($0&12)*4)(data), $1		// read 4 4-byte words
	mov		a, y3
	rorx	$$25, e, y0
	rorx	$$11, e, y1
	add		WK(0+$0), h
	or		c, y3
	mov		f, y2
	rorx	$$13, a, T1
	xor		y1, y0
	xor		g, y2
	rorx	$$6, e, y1
	and		e, y2
	xor		y1, y0
	rorx	$$22, a, y1
	add		h, d
	and		b, y3
	xor		T1, y1
	rorx	$$2, a, T1
	xor		g, y2
	xor		T1, y1
	mov		a, T1
	and		c, T1
	add		y0, y2
	or		T1, y3
	add		y1, h
	add		y2, d
	add		y2, h
	add		y3, h

	// round	h, a, b, c, d, e, f, g, 1+$0
		vpshufb	L_aligned_bswap, $1, $1	// big-endian of each 4-byte word, W[r:r+3]
	mov		h, y3
	rorx	$$25, d, y0
	rorx	$$11, d, y1
	add		WK(1+$0), g
	or		b, y3
	mov		e, y2
	rorx	$$13, h, T1
	xor		y1, y0
	xor		f, y2
	rorx	$$6, d, y1
	and		d, y2
	xor		y1, y0
	rorx	$$22, h, y1
	add		g, c
	and		a, y3
	xor		T1, y1
	rorx	$$2, h, T1
	xor		f, y2
	xor		T1, y1
	mov		h, T1
	and		b, T1
	add		y0, y2
	or		T1, y3
	add		y1, g
	add		y2, c
	add		y2, g
	add		y3, g

	// round	g, h, a, b, c, d, e, f, 2+$0
	mov		g, y3
	rorx	$$25, c, y0
	rorx	$$11, c, y1
	add		WK(2+$0), f
	or		a, y3
	mov		d, y2
	rorx	$$13, g, T1
	xor		y1, y0
	xor		e, y2
	rorx	$$6, c, y1
	and		c, y2
	xor		y1, y0
	rorx	$$22, g, y1
	add		f, b
	and		h, y3
	xor		T1, y1
	rorx	$$2, g, T1
	xor		e, y2
	xor		T1, y1
	mov		g, T1
	and		a, T1
	add		y0, y2
	or		T1, y3
	add		y1, f
	add		y2, b
	add		y2, f
	add		y3, f

	// round	f, g, h, a, b, c, d, e, 3+$0
		vpaddd	(($0&12)*4)(K), $1, %xmm4			// WK[r:r+3]

	mov		f, y3
	rorx	$$25, b, y0
	rorx	$$11, b, y1
	add		WK(3+$0), e
	or		h, y3
	mov		c, y2
	rorx	$$13, f, T1
	xor		y1, y0
	xor		d, y2
	rorx	$$6, b, y1
	and		b, y2
	xor		y1, y0
	rorx	$$22, f, y1
	add		e, a
	and		g, y3
	xor		T1, y1
	rorx	$$2, f, T1
	xor		d, y2
	xor		T1, y1
	mov		f, T1
	and		h, T1
	add		y0, y2
	or		T1, y3
	add		y1, e
	add		y2, a
	add		y2, e
	add		y3, e

		vmovdqa	%xmm4, WK($0&12)		// save WK[r:r+3] into stack circular buffer

	.endm

	.macro	roundsE_update
	// round	e, f, g, h, a, b, c, d, 0+$0
		vmovdqu	(($0&12)*4)(data), $1		// read 4 4-byte words
	mov		e, y3
	rorx	$$25, a, y0
	rorx	$$11, a, y1
	add		WK(0+$0), d
	or		g, y3
	mov		b, y2
	rorx	$$13, e, T1
	xor		y1, y0
	xor		c, y2
	rorx	$$6, a, y1
	and		a, y2
	xor		y1, y0
	rorx	$$22, e, y1
	add		d, h
	and		f, y3
	xor		T1, y1
	rorx	$$2, e, T1
	xor		c, y2
	xor		T1, y1
	mov		e, T1
	and		g, T1
	add		y0, y2
	or		T1, y3
	add		y1, d
	add		y2, h
	add		y2, d
	add		y3, d

	// round	d, e, f, g, h, a, b, c, 1+$0
		vpshufb	L_aligned_bswap, $1, $1	// big-endian of each 4-byte word, W[r:r+3]
	mov		d, y3
	rorx	$$25, h, y0
	rorx	$$11, h, y1
	add		WK(1+$0), c
	or		f, y3
	mov		a, y2
	rorx	$$13, d, T1
	xor		y1, y0
	xor		b, y2
	rorx	$$6, h, y1
	and		h, y2
	xor		y1, y0
	rorx	$$22, d, y1
	add		c, g
	and		e, y3
	xor		T1, y1
	rorx	$$2, d, T1
	xor		b, y2
	xor		T1, y1
	mov		d, T1
	and		f, T1
	add		y0, y2
	or		T1, y3
	add		y1, c
	add		y2, g
	add		y2, c
	add		y3, c

	//round	c, d, e, f, g, h, a, b, 2+$0
	mov		c, y3
	rorx	$$25, g, y0
	rorx	$$11, g, y1
	add		WK(2+$0), b
	or		e, y3
	mov		h, y2
	rorx	$$13, c, T1
	xor		y1, y0
	xor		a, y2
	rorx	$$6, g, y1
	and		g, y2
	xor		y1, y0
	rorx	$$22, c, y1
	add		b, f
	and		d, y3
	xor		T1, y1
	rorx	$$2, c, T1
	xor		a, y2
	xor		T1, y1
	mov		c, T1
	and		e, T1
	add		y0, y2
	or		T1, y3
	add		y1, b
	add		y2, f
	add		y2, b
	add		y3, b

	// round	b, c, d, e, f, g, h, a, 3+$0
		vpaddd	(($0&12)*4)(K), $1, %xmm4			// WK[r:r+3]

	mov		b, y3
	rorx	$$25, f, y0
	rorx	$$11, f, y1
	add		WK(3+$0), a
	or		d, y3
	mov		g, y2
	rorx	$$13, b, T1
	xor		y1, y0
	xor		h, y2
	rorx	$$6, f, y1
	and		f, y2
	xor		y1, y0
	rorx	$$22, b, y1
	add		a, e
	and		c, y3
	xor		T1, y1
	rorx	$$2, b, T1
	xor		h, y2
	xor		T1, y1
	mov		b, T1
	and		d, T1
	add		y0, y2
	or		T1, y3
	add		y1, a
	add		y2, e
	add		y2, a
	add		y3, a

	// update_W_WK	(($0/4)&3), $1
		vmovdqa	%xmm4, WK($0&12)		// save WK[r:r+3] into stack circular buffer
	.endm

	.macro	roundsA
	// round	a, b, c, d, e, f, g, h, 0+$0
	mov		a, y3
	rorx	$$25, e, y0
	rorx	$$11, e, y1
	add		WK(0+$0), h
	or		c, y3
	mov		f, y2
	rorx	$$13, a, T1
	xor		y1, y0
	xor		g, y2
	rorx	$$6, e, y1
	and		e, y2
	xor		y1, y0
	rorx	$$22, a, y1
	add		h, d
	and		b, y3
	xor		T1, y1
	rorx	$$2, a, T1
	xor		g, y2
	xor		T1, y1
	mov		a, T1
	and		c, T1
	add		y0, y2
	or		T1, y3
	add		y1, h
	add		y2, d
	add		y2, h
	add		y3, h

	// round	h, a, b, c, d, e, f, g, 1+$0
	mov		h, y3
	rorx	$$25, d, y0
	rorx	$$11, d, y1
	add		WK(1+$0), g
	or		b, y3
	mov		e, y2
	rorx	$$13, h, T1
	xor		y1, y0
	xor		f, y2
	rorx	$$6, d, y1
	and		d, y2
	xor		y1, y0
	rorx	$$22, h, y1
	add		g, c
	and		a, y3
	xor		T1, y1
	rorx	$$2, h, T1
	xor		f, y2
	xor		T1, y1
	mov		h, T1
	and		b, T1
	add		y0, y2
	or		T1, y3
	add		y1, g
	add		y2, c
	add		y2, g
	add		y3, g

	// round	g, h, a, b, c, d, e, f, 2+$0
	mov		g, y3
	rorx	$$25, c, y0
	rorx	$$11, c, y1
	add		WK(2+$0), f
	or		a, y3
	mov		d, y2
	rorx	$$13, g, T1
	xor		y1, y0
	xor		e, y2
	rorx	$$6, c, y1
	and		c, y2
	xor		y1, y0
	rorx	$$22, g, y1
	add		f, b
	and		h, y3
	xor		T1, y1
	rorx	$$2, g, T1
	xor		e, y2
	xor		T1, y1
	mov		g, T1
	and		a, T1
	add		y0, y2
	or		T1, y3
	add		y1, f
	add		y2, b
	add		y2, f
	add		y3, f

	// round	f, g, h, a, b, c, d, e, 3+$0
	mov		f, y3
	rorx	$$25, b, y0
	rorx	$$11, b, y1
	add		WK(3+$0), e
	or		h, y3
	mov		c, y2
	rorx	$$13, f, T1
	xor		y1, y0
	xor		d, y2
	rorx	$$6, b, y1
	and		b, y2
	xor		y1, y0
	rorx	$$22, f, y1
	add		e, a
	and		g, y3
	xor		T1, y1
	rorx	$$2, f, T1
	xor		d, y2
	xor		T1, y1
	mov		f, T1
	and		h, T1
	add		y0, y2
	or		T1, y3
	add		y1, e
	add		y2, a
	add		y2, e
	add		y3, e

	.endm

	.macro	roundsE
	// round	e, f, g, h, a, b, c, d, 0+$0
	mov		e, y3
	rorx	$$25, a, y0
	rorx	$$11, a, y1
	add		WK(0+$0), d
	or		g, y3
	mov		b, y2
	rorx	$$13, e, T1
	xor		y1, y0
	xor		c, y2
	rorx	$$6, a, y1
	and		a, y2
	xor		y1, y0
	rorx	$$22, e, y1
	add		d, h
	and		f, y3
	xor		T1, y1
	rorx	$$2, e, T1
	xor		c, y2
	xor		T1, y1
	mov		e, T1
	and		g, T1
	add		y0, y2
	or		T1, y3
	add		y1, d
	add		y2, h
	add		y2, d
	add		y3, d

	// round	d, e, f, g, h, a, b, c, 1+$0
	mov		d, y3
	rorx	$$25, h, y0
	rorx	$$11, h, y1
	add		WK(1+$0), c
	or		f, y3
	mov		a, y2
	rorx	$$13, d, T1
	xor		y1, y0
	xor		b, y2
	rorx	$$6, h, y1
	and		h, y2
	xor		y1, y0
	rorx	$$22, d, y1
	add		c, g
	and		e, y3
	xor		T1, y1
	rorx	$$2, d, T1
	xor		b, y2
	xor		T1, y1
	mov		d, T1
	and		f, T1
	add		y0, y2
	or		T1, y3
	add		y1, c
	add		y2, g
	add		y2, c
	add		y3, c

	//round	c, d, e, f, g, h, a, b, 2+$0
	mov		c, y3
	rorx	$$25, g, y0
	rorx	$$11, g, y1
	add		WK(2+$0), b
	or		e, y3
	mov		h, y2
	rorx	$$13, c, T1
	xor		y1, y0
	xor		a, y2
	rorx	$$6, g, y1
	and		g, y2
	xor		y1, y0
	rorx	$$22, c, y1
	add		b, f
	and		d, y3
	xor		T1, y1
	rorx	$$2, c, T1
	xor		a, y2
	xor		T1, y1
	mov		c, T1
	and		e, T1
	add		y0, y2
	or		T1, y3
	add		y1, b
	add		y2, f
	add		y2, b
	add		y3, b

	// round	b, c, d, e, f, g, h, a, 3+$0
	mov		b, y3
	rorx	$$25, f, y0
	rorx	$$11, f, y1
	add		WK(3+$0), a
	or		d, y3
	mov		g, y2
	rorx	$$13, b, T1
	xor		y1, y0
	xor		h, y2
	rorx	$$6, f, y1
	and		f, y2
	xor		y1, y0
	rorx	$$22, b, y1
	add		a, e
	and		c, y3
	xor		T1, y1
	rorx	$$2, b, T1
	xor		h, y2
	xor		T1, y1
	mov		b, T1
	and		d, T1
	add		y0, y2
	or		T1, y3
	add		y1, a
	add		y2, e
	add		y2, a
	add		y3, a

	.endm

	.text
    .globl	_ccsha256_vng_intel_avx2_compress
_ccsha256_vng_intel_avx2_compress:

	// push callee-saved registers
	push	%rbp
	push	%rbx
	push	%r12
	push	%r13
	push	%r14
	push	%r15

	// allocate stack space
	sub		$stack_size, sp

	mov		%rsi, num_blocks
	mov		%rdi, _ctx

	// if kernel code, save used xmm registers
#if CC_KERNEL
	vmovdqa	%xmm0, 0*16+xmm_save
	vmovdqa	%xmm1, 1*16+xmm_save
	vmovdqa	%xmm2, 2*16+xmm_save
	vmovdqa	%xmm3, 3*16+xmm_save
	vmovdqa	%xmm4, 4*16+xmm_save
	vmovdqa	%xmm5, 5*16+xmm_save
	vmovdqa	%xmm6, 6*16+xmm_save
	vmovdqa	%xmm7, 7*16+xmm_save
#endif

	// set up bswap parameters in the aligned stack space and pointer to table K256[]
	lea		L_bswap(%rip), %rax
	lea		_ccsha256_K(%rip), K
	vmovdqa	(%rax), %xmm0
	vmovdqa	%xmm0, L_aligned_bswap

	// load W[0:15] into xmm0-xmm3
	vmovdqu	0*16(data), W0
	vmovdqu	1*16(data), W1
	vmovdqu	2*16(data), W2
	vmovdqu	3*16(data), W3
	addq	$64, data

	vpshufb	L_aligned_bswap, W0, W0
	vpshufb	L_aligned_bswap, W1, W1
	vpshufb	L_aligned_bswap, W2, W2
	vpshufb	L_aligned_bswap, W3, W3

	// compute WK[0:15] and save in stack
	vpaddd	0*16(K), %xmm0, %xmm4
	vpaddd	1*16(K), %xmm1, %xmm5
	vpaddd	2*16(K), %xmm2, %xmm6
	vpaddd	3*16(K), %xmm3, %xmm7
    addq	$64, K
	vmovdqa	%xmm4, WK(0)
	vmovdqa	%xmm5, WK(4)
	vmovdqa	%xmm6, WK(8)
	vmovdqa	%xmm7, WK(12)

L_loop:

	// digests a-h = ctx->states;
	mov		_ctx, ctx
	mov		0*4(ctx), a
	mov		1*4(ctx), b
	mov		2*4(ctx), c
	mov		3*4(ctx), d
	mov		4*4(ctx), e
	mov		5*4(ctx), f
	mov		6*4(ctx), g
	mov		7*4(ctx), h

	// rounds 0:47 interleaved with W/WK update for rounds 16:63
	roundsA_schedule W0,W1,W2,W3,16
	roundsE_schedule W1,W2,W3,W0,20
	roundsA_schedule W2,W3,W0,W1,24
	roundsE_schedule W3,W0,W1,W2,28
	roundsA_schedule W0,W1,W2,W3,32
	roundsE_schedule W1,W2,W3,W0,36
	roundsA_schedule W2,W3,W0,W1,40
	roundsE_schedule W3,W0,W1,W2,44
	roundsA_schedule W0,W1,W2,W3,48
	roundsE_schedule W1,W2,W3,W0,52
	roundsA_schedule W2,W3,W0,W1,56
	roundsE_schedule W3,W0,W1,W2,60

	// revert K to the beginning of K256[]
	subq		$256, K
	subq		$1, num_blocks				// num_blocks--

	je		L_final_block				// if final block, wrap up final rounds

	// rounds 48:63 interleaved with W/WK initialization for next block rounds 0:15
	roundsA_update	48, W0
	roundsE_update	52, W1
	roundsA_update	56, W2
	roundsE_update	60, W3

	addq	$64, K
	addq	$64, data

	// ctx->states += digests a-h
	mov		_ctx, ctx
	add		a, 0*4(ctx)
	add		b, 1*4(ctx)
	add		c, 2*4(ctx)
	add		d, 3*4(ctx)
	add		e, 4*4(ctx)
	add		f, 5*4(ctx)
	add		g, 6*4(ctx)
	add		h, 7*4(ctx)

	jmp		L_loop				// branch for next block

	// wrap up digest update round 48:63 for final block
L_final_block:
	roundsA	48
	roundsE	52
	roundsA	56
	roundsE	60

	// ctx->states += digests a-h
	mov		_ctx, ctx
	add		a, 0*4(ctx)
	add		b, 1*4(ctx)
	add		c, 2*4(ctx)
	add		d, 3*4(ctx)
	add		e, 4*4(ctx)
	add		f, 5*4(ctx)
	add		g, 6*4(ctx)
	add		h, 7*4(ctx)

	// if kernel, restore xmm0-xmm7
#if CC_KERNEL
	vmovdqa	0*16+xmm_save, %xmm0
	vmovdqa	1*16+xmm_save, %xmm1
	vmovdqa	2*16+xmm_save, %xmm2
	vmovdqa	3*16+xmm_save, %xmm3
	vmovdqa	4*16+xmm_save, %xmm4
	vmovdqa	5*16+xmm_save, %xmm5
	vmovdqa	6*16+xmm_save, %xmm6
	vmovdqa	7*16+xmm_save, %xmm7
#endif

	// free allocated stack memory
	add		$stack_size, sp

	// restore callee-saved registers
	pop		%r15
	pop		%r14
	pop		%r13
	pop		%r12
	pop		%rbx
	pop		%rbp

	// return
	ret

	// data for using ssse3 pshufb instruction (big-endian loading of data)
    .const
    .align  4, 0x90

L_bswap:
    .long   0x00010203
    .long   0x04050607
    .long   0x08090a0b
    .long   0x0c0d0e0f


#endif      // x86_64

#endif /* CCSHA2_VNG_INTEL */
#endif /* __NO_ASM__ */
