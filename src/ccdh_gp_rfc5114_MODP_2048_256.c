/*
 * Copyright (c) 2011,2015 Apple Inc. All rights reserved.
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


/* Autogenerated file - Use scheme ccdh_gen_gp */
#include <corecrypto/ccdh_priv.h>
#include <corecrypto/ccdh_gp.h>

static const ccdh_gp_decl_static(2048) _ccdh_gp_rfc5114_MODP_2048_256 =
{
    .zp = {
        .n = ccn_nof(2048),
        .options = 0,
        .mod_prime = cczp_mod
    },
    .p = {
        /* prime */
        CCN64_C(db,09,4a,e9,1e,1a,15,97),CCN64_C(69,38,77,fa,d7,ef,09,ca),
        CCN64_C(61,16,d2,27,6e,11,71,5f),CCN64_C(a4,b5,43,30,c1,98,af,12),
        CCN64_C(75,f2,63,75,d7,01,41,03),CCN64_C(c3,a3,96,0a,54,e7,10,c3),
        CCN64_C(de,d4,01,0a,bd,0b,e6,21),CCN64_C(c0,b8,57,f6,89,96,28,56),
        CCN64_C(b3,ca,3f,79,71,50,60,26),CCN64_C(1c,ca,cb,83,e6,b4,86,f6),
        CCN64_C(67,e1,44,e5,14,05,64,25),CCN64_C(f6,a1,67,b5,a4,18,25,d9),
        CCN64_C(3a,d8,34,77,96,52,4d,8e),CCN64_C(f1,3c,6d,9a,51,bf,a4,ab),
        CCN64_C(2d,52,52,67,35,48,8a,0e),CCN64_C(b6,3a,ca,e1,ca,a6,b7,90),
        CCN64_C(4f,db,70,c5,81,b2,3f,76),CCN64_C(bc,39,a0,bf,12,30,7f,5c),
        CCN64_C(b9,41,f5,4e,b1,e5,9b,b8),CCN64_C(6c,5b,fc,11,d4,5f,90,88),
        CCN64_C(22,e0,b1,ef,42,75,bf,7b),CCN64_C(91,f9,e6,72,5b,47,58,c0),
        CCN64_C(5a,8a,9d,30,6b,cf,67,ed),CCN64_C(20,9e,0c,64,97,51,7a,bd),
        CCN64_C(3b,f4,29,6d,83,0e,9a,7c),CCN64_C(16,c3,d9,11,34,09,6f,aa),
        CCN64_C(fa,f7,df,45,61,b2,aa,30),CCN64_C(e0,0d,f8,f1,d6,19,57,d4),
        CCN64_C(5d,2c,ee,d4,43,5e,3b,00),CCN64_C(8c,ee,f6,08,66,0d,d0,f2),
        CCN64_C(ff,bb,d1,9c,65,19,59,99),CCN64_C(87,a8,e6,1d,b4,b6,66,3c)
    },
    .recip = {
        /* recip */
        CCN64_C(dd,ac,dc,00,80,da,59,e0),CCN64_C(e0,6c,ce,57,da,06,ec,4b),
        CCN64_C(69,a7,0c,49,b2,f3,40,09),CCN64_C(73,0a,ff,d5,f2,98,7f,99),
        CCN64_C(50,7e,2a,f0,62,ab,6c,cb),CCN64_C(43,71,13,67,97,c8,e2,d6),
        CCN64_C(54,20,f4,85,35,63,76,31),CCN64_C(8c,05,18,f1,a6,43,81,a2),
        CCN64_C(02,11,46,a7,b3,e5,6a,d6),CCN64_C(db,dc,66,eb,f4,3f,e2,88),
        CCN64_C(ce,40,30,30,0d,fc,e7,1e),CCN64_C(dd,01,8a,90,fd,06,f9,d5),
        CCN64_C(cd,2d,c9,23,7b,0c,13,2a),CCN64_C(40,99,6c,67,f7,cf,f7,df),
        CCN64_C(d0,ee,da,61,33,15,5b,95),CCN64_C(22,05,68,7a,75,49,49,65),
        CCN64_C(89,f5,31,a1,b2,53,cf,0f),CCN64_C(73,b2,ca,bf,85,37,63,8e),
        CCN64_C(f0,02,34,73,42,a4,d5,f8),CCN64_C(ee,1a,08,53,77,75,b9,bf),
        CCN64_C(a6,f9,d0,d1,e4,05,30,4f),CCN64_C(54,35,46,35,5f,c2,89,a4),
        CCN64_C(39,16,c8,c6,30,c2,bb,38),CCN64_C(df,3a,fb,0c,df,ba,ae,f8),
        CCN64_C(f2,af,fd,7b,96,a1,07,5d),CCN64_C(c0,12,c3,63,ec,ad,75,52),
        CCN64_C(f0,9a,3f,14,45,dd,76,31),CCN64_C(4e,e0,54,88,18,12,d3,b2),
        CCN64_C(58,fb,68,25,0d,87,d9,87),CCN64_C(2d,07,32,21,76,68,fd,5a),
        CCN64_C(62,0a,cb,c3,89,24,54,a5),CCN64_C(e3,17,47,11,ce,55,4a,4d),
        CCN8_C(01)
    },
    .g = {
        /* g */
        CCN64_C(66,4b,4c,0f,6c,c4,16,59),CCN64_C(5e,23,27,cf,ef,98,c5,82),
        CCN64_C(d6,47,d1,48,d4,79,54,51),CCN64_C(2f,63,07,84,90,f0,0e,f8),
        CCN64_C(18,4b,52,3d,1d,b2,46,c3),CCN64_C(c7,89,14,28,cd,c6,7e,b6),
        CCN64_C(7f,d0,28,37,0d,f9,2b,52),CCN64_C(b3,35,3b,bb,64,e0,ec,37),
        CCN64_C(ec,d0,6e,15,57,cd,09,15),CCN64_C(b7,d2,bb,d2,df,01,61,99),
        CCN64_C(c8,48,4b,1e,05,25,88,b9),CCN64_C(db,2a,3b,73,13,d3,fe,14),
        CCN64_C(d0,52,b9,85,d1,82,ea,0a),CCN64_C(a4,bd,1b,ff,e8,3b,9c,80),
        CCN64_C(df,c9,67,c1,fb,3f,2e,55),CCN64_C(b5,04,5a,f2,76,71,64,e1),
        CCN64_C(1d,14,34,8f,6f,2f,91,93),CCN64_C(64,e6,79,82,42,8e,bc,83),
        CCN64_C(8a,c3,76,d2,82,d6,ed,38),CCN64_C(77,7d,e6,2a,aa,b8,a8,62),
        CCN64_C(dd,f4,63,e5,e9,ec,14,4b),CCN64_C(01,96,f9,31,c7,7a,57,f2),
        CCN64_C(a5,5a,e3,13,41,00,0a,65),CCN64_C(90,12,28,f8,c2,8c,bb,18),
        CCN64_C(bc,37,73,bf,7e,8c,6f,62),CCN64_C(be,3a,6c,1b,0c,6b,47,b1),
        CCN64_C(ff,4f,ed,4a,ac,0b,b5,55),CCN64_C(10,db,c1,50,77,be,46,3f),
        CCN64_C(07,f4,79,3a,1a,0b,a1,25),CCN64_C(4c,a7,b1,8f,21,ef,20,54),
        CCN64_C(2e,77,50,66,60,ed,bd,48),CCN64_C(3f,b3,2c,9b,73,13,4d,0b)
    },
    .q = {
        /* q */
        CCN64_C(a3,08,b0,fe,64,f5,fb,d3),CCN64_C(99,b1,a4,7d,1e,b3,75,0b),
        CCN64_C(b4,47,99,76,40,12,9d,a2),CCN64_C(8c,f8,36,42,a7,09,a0,97),
        CCN64_C(00,00,00,00,00,00,00,00),CCN64_C(00,00,00,00,00,00,00,00),
        CCN64_C(00,00,00,00,00,00,00,00),CCN64_C(00,00,00,00,00,00,00,00),
        CCN64_C(00,00,00,00,00,00,00,00),CCN64_C(00,00,00,00,00,00,00,00),
        CCN64_C(00,00,00,00,00,00,00,00),CCN64_C(00,00,00,00,00,00,00,00),
        CCN64_C(00,00,00,00,00,00,00,00),CCN64_C(00,00,00,00,00,00,00,00),
        CCN64_C(00,00,00,00,00,00,00,00),CCN64_C(00,00,00,00,00,00,00,00),
        CCN64_C(00,00,00,00,00,00,00,00),CCN64_C(00,00,00,00,00,00,00,00),
        CCN64_C(00,00,00,00,00,00,00,00),CCN64_C(00,00,00,00,00,00,00,00),
        CCN64_C(00,00,00,00,00,00,00,00),CCN64_C(00,00,00,00,00,00,00,00),
        CCN64_C(00,00,00,00,00,00,00,00),CCN64_C(00,00,00,00,00,00,00,00),
        CCN64_C(00,00,00,00,00,00,00,00),CCN64_C(00,00,00,00,00,00,00,00),
        CCN64_C(00,00,00,00,00,00,00,00),CCN64_C(00,00,00,00,00,00,00,00),
        CCN64_C(00,00,00,00,00,00,00,00),CCN64_C(00,00,00,00,00,00,00,00),
        CCN64_C(00,00,00,00,00,00,00,00),CCN8_C(00)
    },
    .l = 0,
};

ccdh_const_gp_t ccdh_gp_rfc5114_MODP_2048_256(void)
{
    return (ccdh_const_gp_t)(cczp_const_t)(const cc_unit *)&_ccdh_gp_rfc5114_MODP_2048_256;
}

