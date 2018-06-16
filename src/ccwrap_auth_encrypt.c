/*
 * Copyright (c) 2012,2014,2015 Apple Inc. All rights reserved.
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


#include <corecrypto/ccwrap.h>
#include <corecrypto/cc_priv.h>
#include <corecrypto/cc_macros.h>
#include <corecrypto/cc_debug.h>

/*

 1) Initialize variables.

 Set A = IV, an initial value (see 2.2.3)
 For i = 1 to n R[i] = P[i]

 2) Calculate intermediate values.

 For j = 0 to 5
 For i=1 to n
 B = AES(K, A | R[i])
 A = MSB(64, B) ^ t where t = (n x j)+i
 R[i] = LSB(64, B)

 3) Output the results.

 Set C[0] = A
 For i = 1 to n
 C[i] = R[i]

 */

int ccwrap_auth_encrypt(const struct ccmode_ecb *ecb_mode, ccecb_ctx *ecb_key,
                        size_t nbytes, const void *in,
                        size_t *obytes, void *out)
{
    unsigned long n = nbytes / CCWRAP_SEMIBLOCK; /* size in 64 bit blocks */
    unsigned long i, j;
    int ret = -1;

    uint64_t R[2];

    // keywrap only implemented for 128 bit blocks
    cc_require(ecb_mode->block_size == CCWRAP_SEMIBLOCK * 2, out);

    // minimal two semiblocks
    cc_require(n >= 2, out);

    // NIST 800-38F
#if 0
    if (nbytes % CCWRAP_SEMIBLOCK != 0) {
        cc_require(n <= (1<<29), out); // KWP
        CC_MEMCPY(&R[0], &partial_iv, sizeof(R[0]));
    } else
#endif
    {
#ifdef LP64
#if LP64
        cc_require(n <= (1<<54), out); // KW
#endif
#endif
        R[0] = 0xA6A6A6A6A6A6A6A6;
    }

    for (j = 0; j < 6; j++)
    {
        for (i = 0; i < n; i++)
        {
            CC_MEMCPY(&R[1],
                /* read from in the first time, intermediate results in out */
                ((j==0) ? (const uint8_t*)in : (uint8_t*)out) + CCWRAP_SEMIBLOCK * i, CCWRAP_SEMIBLOCK);
            ecb_mode->ecb(ecb_key, 1, R, R);
            CC_MEMCPY((uint8_t*)out + CCWRAP_SEMIBLOCK * i, &R[1], CCWRAP_SEMIBLOCK);
            R[0] ^= CC_BSWAP64((n*j)+i+1);
            //printf("A: %016llx ", CC_BSWAP64(R[0]));
        }
    }
    //printf("\n");
    CC_MEMMOVE(out + CCWRAP_SEMIBLOCK, out, nbytes);
    CC_MEMCPY(out, R, CCWRAP_SEMIBLOCK);

    unsigned long osize = nbytes + CCWRAP_SEMIBLOCK;
    if (nbytes % CCWRAP_SEMIBLOCK != 0)
        osize += 0; // add padding
    *obytes = osize;
    ret = 0;
out:
    cc_clear(sizeof(R),R);
    return ret;
}
