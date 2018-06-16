/*
 * Copyright (c) 2010,2011,2012,2014,2015 Apple Inc. All rights reserved.
 * 
 * corecrypto Internal Use License Agreement
 * 
 * IMPORTANT:  This Apple corecrypto software is supplied to you by Apple Inc. ("Apple")
 * in consideration of your agreement to the following terms, and your download or use
 * of this Apple software constitutes acceptance of these terms.  If you do not agree
 * with these terms, please do not download or use this Apple software.
 * 
 * 1.	As used in this Agreement, the term "Apple Software" collectively means and
 * includes all of the Apple corecrypto materials provided by Apple here, including
 * but not limited to the Apple corecrypto software, frameworks, libraries, documentation
 * and other Apple-created materials. In consideration of your agreement to abide by the
 * following terms, conditioned upon your compliance with these terms and subject to
 * these terms, Apple grants you, for a period of ninety (90) days from the date you
 * download the Apple Software, a limited, non-exclusive, non-sublicensable license
 * under Apple’s copyrights in the Apple Software to make a reasonable number of copies
 * of, compile, and run the Apple Software internally within your organization only on
 * devices and computers you own or control, for the sole purpose of verifying the
 * security characteristics and correct functioning of the Apple Software; provided
 * that you must retain this notice and the following text and disclaimers in all
 * copies of the Apple Software that you make. You may not, directly or indirectly,
 * redistribute the Apple Software or any portions thereof. The Apple Software is only
 * licensed and intended for use as expressly stated above and may not be used for other
 * purposes or in other contexts without Apple's prior written permission.  Except as
 * expressly stated in this notice, no other rights or licenses, express or implied, are
 * granted by Apple herein.
 * 
 * 2.	The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 * WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES
 * OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
 * THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS,
 * SYSTEMS, OR SERVICES. APPLE DOES NOT WARRANT THAT THE APPLE SOFTWARE WILL MEET YOUR
 * REQUIREMENTS, THAT THE OPERATION OF THE APPLE SOFTWARE WILL BE UNINTERRUPTED OR
 * ERROR-FREE, THAT DEFECTS IN THE APPLE SOFTWARE WILL BE CORRECTED, OR THAT THE APPLE
 * SOFTWARE WILL BE COMPATIBLE WITH FUTURE APPLE PRODUCTS, SOFTWARE OR SERVICES. NO ORAL
 * OR WRITTEN INFORMATION OR ADVICE GIVEN BY APPLE OR AN APPLE AUTHORIZED REPRESENTATIVE
 * WILL CREATE A WARRANTY. 
 * 
 * 3.	IN NO EVENT SHALL APPLE BE LIABLE FOR ANY DIRECT, SPECIAL, INDIRECT, INCIDENTAL
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING
 * IN ANY WAY OUT OF THE USE, REPRODUCTION, COMPILATION OR OPERATION OF THE APPLE
 * SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING
 * NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 * 
 * 4.	This Agreement is effective until terminated. Your rights under this Agreement will
 * terminate automatically without notice from Apple if you fail to comply with any term(s)
 * of this Agreement.  Upon termination, you agree to cease all use of the Apple Software
 * and destroy all copies, full or partial, of the Apple Software. This Agreement will be
 * governed and construed in accordance with the laws of the State of California, without
 * regard to its choice of law rules.
 * 
 * You may report security issues about Apple products to product-security@apple.com,
 * as described here:  https://www.apple.com/support/security/.  Non-security bugs and
 * enhancement requests can be made via https://bugreport.apple.com as described
 * here: https://developer.apple.com/bug-reporting/
 *
 * EA1350 
 * 10/5/15
 */


#include <corecrypto/ccn.h>
#include <corecrypto/cc_debug.h>

#define CC_DEBUG_VSHIFTL (CORECRYPTO_DEBUG && 0)

#if 1

/* Logical shift left, iterates backwards though a ccn so that multi cc_unit
   shifts can be done in place by copying from the less significant units
   towards the start of the ccn to the ones in the back. */
cc_unit ccn_shift_left(cc_size count, cc_unit *r, const cc_unit *s, size_t k)
{
#if CC_DEBUG_VSHIFTL
    cc_printf("raise unless 0x");
    ccn_print(count, s);
#endif
    if (count == 0)
        return 0;
    cc_assert(count > 0);
    cc_assert(k >= 0 && k < CCN_UNIT_BITS);
    cc_size i = count - 1;
    unsigned long m = CCN_UNIT_BITS - k;
    cc_unit sip1 = s[i];
	cc_unit carry = (sip1 >> m);
	while (i) {
        i--;
        cc_unit si = s[i];
		r[i + 1] = (sip1 << k) | (si >> m);
        sip1 = si;
	}
    r[0] = (sip1 << k);
#if CC_DEBUG_VSHIFTL
    cc_printf(" << %lu == 0x%08x", k, carry);
    ccn_lprint(count, "", r);
#endif
	return carry;
}

#else

/* Slightly faster forward logical shift left, incompatible with
   ccn_shift_left_multi in place operations. */
cc_unit ccn_shift_left(cc_size count, cc_unit *r, const cc_unit *s, unsigned long k)
{
#if CC_DEBUG_VSHIFTL
    cc_printf("raise unless 0x");
    ccn_print(count, s);
#endif
    assert(k >= 0 && k <= 32);
	cc_unit carry = 0;
    cc_size m = 32 - k;
	for (cc_size ix = 0; ix < count; ++ix) {
        cc_unit v = s[ix];
		r[ix] = (v << k) | carry;
		carry = (v >> m);
	}
#if CC_DEBUG_VSHIFTL
    cc_printf(" << %lu == 0x%08x", k, carry);
    ccn_lprint(count, "", r);
#endif
	return carry;
}

#endif
