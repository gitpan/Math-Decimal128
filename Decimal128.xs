
#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include <stdlib.h>

#ifdef OLDPERL
#define SvUOK SvIsUV
#endif

#ifndef Newx
#  define Newx(v,n,t) New(0,v,n,t)
#endif

typedef _Decimal128 D128;

/*******************************
#ifdef __MINGW64__
typedef _Decimal128 D128 __attribute__ ((aligned(8)));
#else
typedef _Decimal128 D128;
#endif
********************************/

D128 add_on[113] = {
      1e0DL, 2e0DL, 4e0DL, 8e0DL, 16e0DL, 32e0DL, 64e0DL, 128e0DL, 256e0DL, 512e0DL, 1024e0DL,
      2048e0DL, 4096e0DL, 8192e0DL, 16384e0DL, 32768e0DL, 65536e0DL, 131072e0DL, 262144e0DL,
      524288e0DL, 1048576e0DL, 2097152e0DL, 4194304e0DL, 8388608e0DL, 16777216e0DL, 33554432e0DL,
      67108864e0DL, 134217728e0DL, 268435456e0DL, 536870912e0DL, 1073741824e0DL, 2147483648e0DL,
      4294967296e0DL, 8589934592e0DL, 17179869184e0DL, 34359738368e0DL, 68719476736e0DL,
      137438953472e0DL, 274877906944e0DL, 549755813888e0DL, 1099511627776e0DL, 2199023255552e0DL,
      4398046511104e0DL, 8796093022208e0DL, 17592186044416e0DL, 35184372088832e0DL,
      70368744177664e0DL, 140737488355328e0DL, 281474976710656e0DL, 562949953421312e0DL,
      1125899906842624e0DL, 2251799813685248e0DL, 4503599627370496e0DL, 9007199254740992e0DL,
      18014398509481984e0DL, 36028797018963968e0DL, 72057594037927936e0DL, 144115188075855872e0DL,
      288230376151711744e0DL, 576460752303423488e0DL, 1152921504606846976e0DL,
      2305843009213693952e0DL, 4611686018427387904e0DL, 9223372036854775808e0DL,
      18446744073709551616e0DL, 36893488147419103232e0DL, 73786976294838206464e0DL,
      147573952589676412928e0DL, 295147905179352825856e0DL, 590295810358705651712e0DL,
      1180591620717411303424e0DL, 2361183241434822606848e0DL, 4722366482869645213696e0DL,
      9444732965739290427392e0DL, 18889465931478580854784e0DL, 37778931862957161709568e0DL,
      75557863725914323419136e0DL, 151115727451828646838272e0DL, 302231454903657293676544e0DL,
      604462909807314587353088e0DL, 1208925819614629174706176e0DL, 2417851639229258349412352e0DL,
      4835703278458516698824704e0DL, 9671406556917033397649408e0DL, 19342813113834066795298816e0DL,
      38685626227668133590597632e0DL, 77371252455336267181195264e0DL,
      154742504910672534362390528e0DL, 309485009821345068724781056e0DL,
      618970019642690137449562112e0DL, 1237940039285380274899124224e0DL,
      2475880078570760549798248448e0DL, 4951760157141521099596496896e0DL,
      9903520314283042199192993792e0DL, 19807040628566084398385987584e0DL,
      39614081257132168796771975168e0DL, 79228162514264337593543950336e0DL,
      158456325028528675187087900672e0DL, 316912650057057350374175801344e0DL,
      633825300114114700748351602688e0DL, 1267650600228229401496703205376e0DL,
      2535301200456458802993406410752e0DL, 5070602400912917605986812821504e0DL,
      10141204801825835211973625643008e0DL, 20282409603651670423947251286016e0DL,
      40564819207303340847894502572032e0DL, 81129638414606681695789005144064e0DL,
      162259276829213363391578010288128e0DL, 324518553658426726783156020576256e0DL,
      649037107316853453566312041152512e0DL, 1298074214633706907132624082305024e0DL,
      2596148429267413814265248164610048e0DL, 5192296858534827628530496329220096e0DL };

int  _is_nan(D128 x) {
     if(x == x) return 0;
     return 1;
}

int  _is_inf(D128 x) {
     if(x != x) return 0; /* NaN  */
     if(x == 0.DL) return 0; /* Zero */
     if(x/x != x/x) {
       if(x < 0.DL) return -1;
       else return 1;
     }
     return 0; /* Finite Real */
}

int  _is_neg_zero(D128 x) {
     char * buffer;

     if(x != 0.DL) return 0;

     Newx(buffer, 2, char);
     sprintf(buffer, "%.0f", (double)x);

     if(strcmp(buffer, "-0")) {
       Safefree(buffer);
       return 0;
     }

     Safefree(buffer);
     return 1;
}

SV *  _is_nan_NV(pTHX_ SV * x) {
      if(SvNV(x) == SvNV(x)) return newSViv(0);
      return newSViv(1);
}

SV *  _is_inf_NV(pTHX_ SV * x) {
      if(SvNV(x) != SvNV(x)) return 0; /* NaN  */
      if(SvNV(x) == 0.0) return newSViv(0); /* Zero */
      if(SvNV(x)/SvNV(x) != SvNV(x)/SvNV(x)) {
        if(SvNV(x) < 0.0) return newSViv(-1);
        else return newSViv(1);
      }
      return newSVnv(0); /* Finite Real */
}

SV *  _is_neg_zero_NV(pTHX_ SV * x) {
      char * buffer;

      if(SvNV(x) != 0.0) return newSViv(0);

      Newx(buffer, 2, char);

      sprintf(buffer, "%.0f", (double)SvNV(x));

      if(strcmp(buffer, "-0")) {
        Safefree(buffer);
        return newSViv(0);
      }

      Safefree(buffer);
      return newSViv(1);
}

D128 _get_inf(int sign) {
     if(sign < 0) return -1.DL/0.DL;
     return 1.DL/0.DL;
}

D128 _get_nan(void) {
     D128 inf = _get_inf(1);
     return inf/inf;
}

SV * _DEC128_MAX(pTHX) {
     D128 * d128;
     SV * obj_ref, * obj;

     Newx(d128, 1, D128);
     if(d128 == NULL) croak("Failed to allocate memory in DEC128_MAX() function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Decimal128");

     *d128 = 9999999999999999999999999999999999e6111DL;


     sv_setiv(obj, INT2PTR(IV,d128));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _DEC128_MIN(pTHX) {
     D128 * d128;
     SV * obj_ref, * obj;

     Newx(d128, 1, D128);
     if(d128 == NULL) croak("Failed to allocate memory in DEC128_MIN() function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Decimal128");

     *d128 = 1e-6176DL;


     sv_setiv(obj, INT2PTR(IV,d128));
     SvREADONLY_on(obj);
     return obj_ref;
}


SV * NaND128(pTHX) {
     D128 * d128;
     SV * obj_ref, * obj;

     Newx(d128, 1, D128);
     if(d128 == NULL) croak("Failed to allocate memory in NaND128(aTHX) function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Decimal128");

     *d128 = _get_nan();

     sv_setiv(obj, INT2PTR(IV,d128));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * InfD128(pTHX_ int sign) {
     D128 * d128;
     SV * obj_ref, * obj;

     Newx(d128, 1, D128);
     if(d128 == NULL) croak("Failed to allocate memory in InfD128(aTHX) function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Decimal128");

     *d128 = _get_inf(sign);

     sv_setiv(obj, INT2PTR(IV,d128));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * ZeroD128(pTHX_ int sign) {
     D128 * d128;
     SV * obj_ref, * obj;

     Newx(d128, 1, D128);
     if(d128 == NULL) croak("Failed to allocate memory in ZeroD128(aTHX) function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Decimal128");

     *d128 = 0.DL;
     if(sign < 0) *d128 *= -1;

     sv_setiv(obj, INT2PTR(IV,d128));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * UnityD128(pTHX_ int sign) {
     D128 * d128;
     SV * obj_ref, * obj;

     Newx(d128, 1, D128);
     if(d128 == NULL) croak("Failed to allocate memory in UnityD128(aTHX) function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Decimal128");

     *d128 = 1.DL;
     /* *d128 = (D128)strtold("1e0", NULL); */
     if(sign < 0) *d128 *= -1;

     sv_setiv(obj, INT2PTR(IV,d128));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Exp10l(pTHX_ int power) {
     D128 * d128;
     SV * obj_ref, * obj;

     /* Remove the following condition, and allow 0/(+-inf to be returned
        when the power goes outside the range.
     if(power < -6176 || power > 6144)
       croak("Argument supplied to Exp10 function (%d) is out of allowable range", power);
     */

     Newx(d128, 1, D128);
     if(d128 == NULL) croak("Failed to allocate memory in Exp10() function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Decimal128");

     *d128 = 1.DL;
     if(power < 0) {
       while(power < -1000) {
         *d128 *= 1e-1000DL;
         power += 1000;
       }
       while(power < -100) {
         *d128 *= 1e-100DL;
         power += 100;
       }
       while(power < -10) {
         *d128 *= 1e-10DL;
         power += 10;
       }
       while(power) {
         *d128 *= 1e-1DL;
         power++;
       }
     }
     else {
       while(power > 1000) {
         *d128 *= 1e1000DL;
         power -= 1000;
       }
       while(power > 100) {
         *d128 *= 1e100DL;
         power -= 100;
       }
       while(power > 10) {
         *d128 *= 1e10DL;
         power -= 10;
       }
       while(power) {
         *d128 *= 1e1DL;
         power--;
       }
     }

     sv_setiv(obj, INT2PTR(IV,d128));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _testvalD128_1(pTHX_ int sign) {
     D128 * d128;
     SV * obj_ref, * obj;

     Newx(d128, 1, D128);
     if(d128 == NULL) croak("Failed to allocate memory in _testvalD128() function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Decimal128");

     *d128 = 93071992547409938307199254740993e0DL;

     if(sign < 0) *d128 *= -1;

     sv_setiv(obj, INT2PTR(IV,d128));
     SvREADONLY_on(obj);
     return obj_ref;
}


SV * _testvalD128_2(pTHX_ int sign) {
     D128 * d128;
     SV * obj_ref, * obj;

     Newx(d128, 1, D128);
     if(d128 == NULL) croak("Failed to allocate memory in _testvalD128() function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Decimal128");

     *d128 = 2547409938307199254740993e0DL;

     if(sign < 0) *d128 *= -1;

     sv_setiv(obj, INT2PTR(IV,d128));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _testvalD128_3(pTHX_ int sign) {
     D128 * d128;
     SV * obj_ref, * obj;

     Newx(d128, 1, D128);
     if(d128 == NULL) croak("Failed to allocate memory in _testvalD128() function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Decimal128");

     *d128 = 9938307199254740993e0DL;

     if(sign < 0) *d128 *= -1;

     sv_setiv(obj, INT2PTR(IV,d128));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _testvalD128_4(pTHX_ int sign) {
     D128 * d128;
     SV * obj_ref, * obj;

     Newx(d128, 1, D128);
     if(d128 == NULL) croak("Failed to allocate memory in _testvalD128() function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Decimal128");

     *d128 = 4740993e0DL;

     if(sign < 0) *d128 *= -1;

     sv_setiv(obj, INT2PTR(IV,d128));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _MEtoD128(pTHX_ char * msd, char * nsd, char * lsd, SV * exponent) {

     D128 * d128;
     SV * obj_ref, * obj;
     int exp = (int)SvIV(exponent), i;
     long double m;

     Newx(d128, 1, D128);
     if(d128 == NULL) croak("Failed to allocate memory in MEtoD128() function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Decimal128");

     m = strtold(msd, NULL);
     *d128 = (D128)m * 1e24DL;

     m = strtold(nsd, NULL);
     *d128 += (D128)m * 1e12DL;

     m = strtold(lsd, NULL);
     *d128 += (D128)m;

     if(exp < 0) {
       for(i = 0; i > exp; --i) *d128 *= 1e-1DL;
     }
     else {
       for(i = 0; i < exp; ++i) *d128 *= 10.DL;
     }

     sv_setiv(obj, INT2PTR(IV,d128));
     SvREADONLY_on(obj);
     return obj_ref;
}

void _assignME(pTHX_ SV * a, char * msd, char * nsd, char * lsd, SV * c) {
     long double man;
     int exp = (int)SvIV(c), i;
     D128 all;

     man = strtold(msd, NULL);
     all = (_Decimal128)man * 1e24DL;

     man = strtold(nsd, NULL);
     all += (D128)man * 1e12DL;

     man = strtold(lsd, NULL);
     all += (D128)man;

     *(INT2PTR(D128 *, SvIV(SvRV(a)))) = all;

     if(exp < 0) {
       for(i = 0; i > exp; --i) *(INT2PTR(D128 *, SvIV(SvRV(a)))) *= 1e-1DL;
     }
     else {
       for(i = 0; i < exp; ++i) *(INT2PTR(D128 *, SvIV(SvRV(a)))) *= 10.DL;
     }
}

SV * NVtoD128(pTHX_ SV * x) {

     D128 * d128;
     SV * obj_ref, * obj;

     Newx(d128, 1, D128);
     if(d128 == NULL) croak("Failed to allocate memory in NVtoD128(aTHX) function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Decimal128");

     *d128 = (D128)SvNV(x);

     sv_setiv(obj, INT2PTR(IV,d128));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * UVtoD128(pTHX_ SV * x) {

     D128 * d128;
     SV * obj_ref, * obj;

     Newx(d128, 1, D128);
     if(d128 == NULL) croak("Failed to allocate memory in UVtoD128(aTHX) function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Decimal128");

     *d128 = (D128)SvUV(x);

     sv_setiv(obj, INT2PTR(IV,d128));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * IVtoD128(pTHX_ SV * x) {

     D128 * d128;
     SV * obj_ref, * obj;

     Newx(d128, 1, D128);
     if(d128 == NULL) croak("Failed to allocate memory in IVtoD128(aTHX) function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Decimal128");

     *d128 = (D128)SvIV(x);

     sv_setiv(obj, INT2PTR(IV,d128));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * STRtoD128(pTHX_ char * x) {
#ifdef STRTOD128_AVAILABLE
     D128 * d128;
     char * ptr;
     SV * obj_ref, * obj;

     Newx(d128, 1, D128);
     if(d128 == NULL) croak("Failed to allocate memory in STRtoD128(aTHX) function");

     *d128 = strtod128(x, &ptr);

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Decimal128");

     sv_setiv(obj, INT2PTR(IV,d128));
     SvREADONLY_on(obj);
     return obj_ref;
#else
     croak("The strtod128() function has not been made available");
#endif
}

int  have_strtod128(void) {
#ifdef STRTOD128_AVAILABLE
     return 1;
#else
     return 0;
#endif
}

SV * D128toNV(pTHX_ SV * d128) {
     return newSVnv((NV)(*(INT2PTR(D128*, SvIV(SvRV(d128))))));
}

void DESTROY(pTHX_ SV *  rop) {
     Safefree(INT2PTR(D128 *, SvIV(SvRV(rop))));
}

void assignNaNl(pTHX_ SV * a) {

     if(sv_isobject(a)) {
       const char * h = HvNAME(SvSTASH(SvRV(a)));
       if(strEQ(h, "Math::Decimal128")) {
          *(INT2PTR(D128 *, SvIV(SvRV(a)))) = _get_nan();
       }
       else croak("Invalid object supplied to Math::Decimal128::assignNaN function");
     }
     else croak("Invalid argument supplied to Math::Decimal128::assignNaN function");
}

void assignInfl(pTHX_ SV * a, int sign) {

     if(sv_isobject(a)) {
       const char * h = HvNAME(SvSTASH(SvRV(a)));
       if(strEQ(h, "Math::Decimal128")) {
          *(INT2PTR(D128 *, SvIV(SvRV(a)))) = _get_inf(sign);
       }
       else croak("Invalid object supplied to Math::Decimal128::assignInf function");
     }
     else croak("Invalid argument supplied to Math::Decimal128::assignInf function");
}

SV * _overload_add(pTHX_ SV * a, SV * b, SV * third) {

     D128 * d128;
     SV * obj_ref, * obj;

     Newx(d128, 1, D128);
     if(d128 == NULL) croak("Failed to allocate memory in _overload_add(aTHX) function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Decimal128");

     sv_setiv(obj, INT2PTR(IV,d128));
     SvREADONLY_on(obj);

    if(SvUOK(b)) {
      *d128 = *(INT2PTR(D128 *, SvIV(SvRV(a)))) + SvUV(b);
      return obj_ref;
    }

    if(SvIOK(b)) {
      *d128 = *(INT2PTR(D128 *, SvIV(SvRV(a)))) + SvIV(b);
      return obj_ref;
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::Decimal128")) {
        *d128 = *(INT2PTR(D128 *, SvIV(SvRV(a)))) + *(INT2PTR(D128 *, SvIV(SvRV(b))));
        return obj_ref;
      }
      croak("Invalid object supplied to Math::Decimal128::_overload_add function");
    }
    croak("Invalid argument supplied to Math::Decimal128::_overload_add function");
}

SV * _overload_mul(pTHX_ SV * a, SV * b, SV * third) {

     D128 * d128;
     SV * obj_ref, * obj;

     Newx(d128, 1, D128);
     if(d128 == NULL) croak("Failed to allocate memory in _overload_mul(aTHX) function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Decimal128");

     sv_setiv(obj, INT2PTR(IV,d128));
     SvREADONLY_on(obj);

    if(SvUOK(b)) {
      *d128 = *(INT2PTR(D128 *, SvIV(SvRV(a)))) * SvUV(b);
      return obj_ref;
    }

    if(SvIOK(b)) {
      *d128 = *(INT2PTR(D128 *, SvIV(SvRV(a)))) * SvIV(b);
      return obj_ref;
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::Decimal128")) {
        *d128 = *(INT2PTR(D128 *, SvIV(SvRV(a)))) * *(INT2PTR(D128 *, SvIV(SvRV(b))));
        return obj_ref;
      }
      croak("Invalid object supplied to Math::Decimal128::_overload_mul function");
    }
    croak("Invalid argument supplied to Math::Decimal128::_overload_mul function");
}

SV * _overload_sub(pTHX_ SV * a, SV * b, SV * third) {

     D128 * d128;
     SV * obj_ref, * obj;

     Newx(d128, 1, D128);
     if(d128 == NULL) croak("Failed to allocate memory in _overload_sub(aTHX) function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Decimal128");

     sv_setiv(obj, INT2PTR(IV,d128));
     SvREADONLY_on(obj);

    if(SvUOK(b)) {
      if(third == &PL_sv_yes) *d128 = SvUV(b) - *(INT2PTR(D128 *, SvIV(SvRV(a))));
      else *d128 = *(INT2PTR(D128 *, SvIV(SvRV(a)))) - SvUV(b);
      return obj_ref;
    }

    if(SvIOK(b)) {
      if(third == &PL_sv_yes) *d128 = SvIV(b) - *(INT2PTR(D128 *, SvIV(SvRV(a))));
      else *d128 = *(INT2PTR(D128 *, SvIV(SvRV(a)))) - SvIV(b);
      return obj_ref;
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::Decimal128")) {
        *d128 = *(INT2PTR(D128 *, SvIV(SvRV(a)))) - *(INT2PTR(D128 *, SvIV(SvRV(b))));
        return obj_ref;
      }
      croak("Invalid object supplied to Math::Decimal128::_overload_sub function");
    }

    if(third == &PL_sv_yes) {
      *d128 = *(INT2PTR(D128 *, SvIV(SvRV(a)))) * -1.DL;
      return obj_ref;
    }

    croak("Invalid argument supplied to Math::Decimal128::_overload_sub function");
}

SV * _overload_div(pTHX_ SV * a, SV * b, SV * third) {

     D128 * d128;
     SV * obj_ref, * obj;

     Newx(d128, 1, D128);
     if(d128 == NULL) croak("Failed to allocate memory in _overload_div(aTHX) function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Decimal128");

     sv_setiv(obj, INT2PTR(IV,d128));
     SvREADONLY_on(obj);

    if(SvUOK(b)) {
      if(third == &PL_sv_yes) *d128 = SvUV(b) / *(INT2PTR(D128 *, SvIV(SvRV(a))));
      else *d128 = *(INT2PTR(D128 *, SvIV(SvRV(a)))) / SvUV(b);
      return obj_ref;
    }

    if(SvIOK(b)) {
      if(third == &PL_sv_yes) *d128 = SvIV(b) / *(INT2PTR(D128 *, SvIV(SvRV(a))));
      else *d128 = *(INT2PTR(D128 *, SvIV(SvRV(a)))) / SvIV(b);
      return obj_ref;
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::Decimal128")) {
        *d128 = *(INT2PTR(D128 *, SvIV(SvRV(a)))) / *(INT2PTR(D128 *, SvIV(SvRV(b))));
        return obj_ref;
      }
      croak("Invalid object supplied to Math::Decimal128::_overload_div function");
    }
    croak("Invalid argument supplied to Math::Decimal128::_overload_div function");
}

SV * _overload_add_eq(pTHX_ SV * a, SV * b, SV * third) {

     SvREFCNT_inc(a);

    if(SvUOK(b)) {
      *(INT2PTR(D128 *, SvIV(SvRV(a)))) += SvUV(b);
      return a;
    }
    if(SvIOK(b)) {
      *(INT2PTR(D128 *, SvIV(SvRV(a)))) += SvIV(b);
      return a;
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::Decimal128")) {
        *(INT2PTR(D128 *, SvIV(SvRV(a)))) += *(INT2PTR(D128 *, SvIV(SvRV(b))));
        return a;
      }
      SvREFCNT_dec(a);
      croak("Invalid object supplied to Math::Decimal128::_overload_add_eq function");
    }
    SvREFCNT_dec(a);
    croak("Invalid argument supplied to Math::Decimal128::_overload_add_eq function");
}

SV * _overload_mul_eq(pTHX_ SV * a, SV * b, SV * third) {

     SvREFCNT_inc(a);

    if(SvUOK(b)) {
      *(INT2PTR(D128 *, SvIV(SvRV(a)))) *= SvUV(b);
      return a;
    }
    if(SvIOK(b)) {
      *(INT2PTR(D128 *, SvIV(SvRV(a)))) *= SvIV(b);
      return a;
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::Decimal128")) {
        *(INT2PTR(D128 *, SvIV(SvRV(a)))) *= *(INT2PTR(D128 *, SvIV(SvRV(b))));
        return a;
      }
      SvREFCNT_dec(a);
      croak("Invalid object supplied to Math::Decimal128::_overload_mul_eq function");
    }
    SvREFCNT_dec(a);
    croak("Invalid argument supplied to Math::Decimal128::_overload_mul_eq function");
}

SV * _overload_sub_eq(pTHX_ SV * a, SV * b, SV * third) {

     SvREFCNT_inc(a);

    if(SvUOK(b)) {
      *(INT2PTR(D128 *, SvIV(SvRV(a)))) -= SvUV(b);
      return a;
    }
    if(SvIOK(b)) {
      *(INT2PTR(D128 *, SvIV(SvRV(a)))) -= SvIV(b);
      return a;
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::Decimal128")) {
        *(INT2PTR(D128 *, SvIV(SvRV(a)))) -= *(INT2PTR(D128 *, SvIV(SvRV(b))));
        return a;
      }
      SvREFCNT_dec(a);
      croak("Invalid object supplied to Math::Decimal128::_overload_sub_eq function");
    }
    SvREFCNT_dec(a);
    croak("Invalid argument supplied to Math::Decimal128::_overload_sub_eq function");
}

SV * _overload_div_eq(pTHX_ SV * a, SV * b, SV * third) {

     SvREFCNT_inc(a);

    if(SvUOK(b)) {
      *(INT2PTR(D128 *, SvIV(SvRV(a)))) /= SvUV(b);
      return a;
    }
    if(SvIOK(b)) {
      *(INT2PTR(D128 *, SvIV(SvRV(a)))) /= SvIV(b);
      return a;
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::Decimal128")) {
        *(INT2PTR(D128 *, SvIV(SvRV(a)))) /= *(INT2PTR(D128 *, SvIV(SvRV(b))));
        return a;
      }
      SvREFCNT_dec(a);
      croak("Invalid object supplied to Math::Decimal128::_overload_div_eq function");
    }
    SvREFCNT_dec(a);
    croak("Invalid argument supplied to Math::Decimal128::_overload_div_eq function");
}

SV * _overload_equiv(pTHX_ SV * a, SV * b, SV * third) {

     if(SvUOK(b)) {
       if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) == SvUV(b)) return newSViv(1);
       return newSViv(0);
     }

     if(SvIOK(b)) {
       if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) == SvIV(b)) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Decimal128")) {
         if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) == *(INT2PTR(D128 *, SvIV(SvRV(b))))) return newSViv(1);
         return newSViv(0);
       }
       croak("Invalid object supplied to Math::Decimal128::_overload_equiv function");
     }
     croak("Invalid argument supplied to Math::Decimal128::_overload_equiv function");
}

SV * _overload_not_equiv(pTHX_ SV * a, SV * b, SV * third) {

     if(SvUOK(b)) {
       if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) != SvUV(b)) return newSViv(1);
       return newSViv(0);
     }

     if(SvIOK(b)) {
       if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) != SvIV(b)) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Decimal128")) {
         if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) == *(INT2PTR(D128 *, SvIV(SvRV(b))))) return newSViv(0);
         return newSViv(1);
       }
       croak("Invalid object supplied to Math::Decimal128::_overload_not_equiv function");
     }
     croak("Invalid argument supplied to Math::Decimal128::_overload_not_equiv function");
}

SV * _overload_lt(pTHX_ SV * a, SV * b, SV * third) {

     if(SvUOK(b)) {
       if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) < SvUV(b)) return newSViv(1);
       return newSViv(0);
     }

     if(SvIOK(b)) {
       if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) < SvIV(b)) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Decimal128")) {
         if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) < *(INT2PTR(D128 *, SvIV(SvRV(b))))) return newSViv(1);
         return newSViv(0);
       }
       croak("Invalid object supplied to Math::Decimal128::_overload_lt function");
     }
     croak("Invalid argument supplied to Math::Decimal128::_overload_lt function");
}

SV * _overload_gt(pTHX_ SV * a, SV * b, SV * third) {

    if(SvUOK(b)) {
      if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) > SvUV(b)) return newSViv(1);
      return newSViv(0);
    }

    if(SvIOK(b)) {
      if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) > SvIV(b)) return newSViv(1);
      return newSViv(0);
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::Decimal128")) {
        if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) > *(INT2PTR(D128 *, SvIV(SvRV(b))))) return newSViv(1);
        return newSViv(0);
      }
      croak("Invalid object supplied to Math::Decimal128::_overload_gt function");
    }
    croak("Invalid argument supplied to Math::Decimal128::_overload_gt function");
}

SV * _overload_lte(pTHX_ SV * a, SV * b, SV * third) {

     if(SvUOK(b)) {
       if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) <= SvUV(b)) return newSViv(1);
       return newSViv(0);
     }

     if(SvIOK(b)) {
       if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) <= SvIV(b)) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Decimal128")) {
         if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) <= *(INT2PTR(D128 *, SvIV(SvRV(b))))) return newSViv(1);
         return newSViv(0);
       }
       croak("Invalid object supplied to Math::Decimal128::_overload_lte function");
     }
     croak("Invalid argument supplied to Math::Decimal128::_overload_lte function");
}

SV * _overload_gte(pTHX_ SV * a, SV * b, SV * third) {

     if(SvUOK(b)) {
       if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) >= SvUV(b)) return newSViv(1);
       return newSViv(0);
     }

     if(SvIOK(b)) {
       if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) >= SvIV(b)) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Decimal128")) {
         if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) >= *(INT2PTR(D128 *, SvIV(SvRV(b))))) return newSViv(1);
         return newSViv(0);
       }
       croak("Invalid object supplied to Math::Decimal128::_overload_gte function");
     }
     croak("Invalid argument supplied to Math::Decimal128::_overload_gte function");
}

SV * _overload_spaceship(pTHX_ SV * a, SV * b, SV * third) {

    if(SvUOK(b)) {
      if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) > SvUV(b)) return newSViv(1);
      if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) < SvUV(b)) return newSViv(-1);
      if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) == SvUV(b)) return newSViv(0);
      return &PL_sv_undef; /* Math::Decimal128 object (1st arg) is a nan */
    }

    if(SvIOK(b)) {
      if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) > SvIV(b)) return newSViv(1);
      if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) < SvIV(b)) return newSViv(-1);
      if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) == SvIV(b)) return newSViv(0);
      return &PL_sv_undef; /* Math::Decimal128 object (1st arg) is a nan */
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::Decimal128")) {
        if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) < *(INT2PTR(D128 *, SvIV(SvRV(b))))) return newSViv(-1);
        if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) > *(INT2PTR(D128 *, SvIV(SvRV(b))))) return newSViv(1);
        if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) == *(INT2PTR(D128 *, SvIV(SvRV(b))))) return newSViv(0);
        return &PL_sv_undef; /* it's a nan */
      }
      croak("Invalid object supplied to Math::Decimal128::_overload_spaceship function");
    }
    croak("Invalid argument supplied to Math::Decimal128::_overload_spaceship function");
}

SV * _overload_copy(pTHX_ SV * a, SV * b, SV * third) {

     D128 * d128;
     SV * obj_ref, * obj;

     Newx(d128, 1, D128);
     if(d128 == NULL) croak("Failed to allocate memory in _overload_copy(aTHX) function");

     *d128 = *(INT2PTR(D128 *, SvIV(SvRV(a))));

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Decimal128");
     sv_setiv(obj, INT2PTR(IV,d128));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * D128toD128(pTHX_ SV * a) {
     D128 * d128;
     SV * obj_ref, * obj;

     if(sv_isobject(a)) {
       const char *h = HvNAME(SvSTASH(SvRV(a)));
       if(strEQ(h, "Math::Decimal128")) {

         Newx(d128, 1, D128);
         if(d128 == NULL) croak("Failed to allocate memory in D128toD128(aTHX) function");

         *d128 = *(INT2PTR(D128 *, SvIV(SvRV(a))));

         obj_ref = newSV(0);
         obj = newSVrv(obj_ref, "Math::Decimal128");
         sv_setiv(obj, INT2PTR(IV,d128));
         SvREADONLY_on(obj);
         return obj_ref;
       }
       croak("Invalid object supplied to Math::Decimal128::D128toD128 function");
     }
     croak("Invalid argument supplied to Math::Decimal128::D128toD128 function");
}

SV * _overload_true(pTHX_ SV * a, SV * b, SV * third) {

     if(_is_nan(*(INT2PTR(D128 *, SvIV(SvRV(a)))))) return newSViv(0);
     if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) != 0.DL) return newSViv(1);
     return newSViv(0);
}

SV * _overload_not(pTHX_ SV * a, SV * b, SV * third) {
     if(_is_nan(*(INT2PTR(D128 *, SvIV(SvRV(a)))))) return newSViv(1);
     if(*(INT2PTR(D128 *, SvIV(SvRV(a)))) != 0.DL) return newSViv(0);
     return newSViv(1);
}

SV * _overload_abs(pTHX_ SV * a, SV * b, SV * third) {

     D128 * d128;
     SV * obj_ref, * obj;

     Newx(d128, 1, D128);
     if(d128 == NULL) croak("Failed to allocate memory in _overload_abs(aTHX) function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Decimal128");

     sv_setiv(obj, INT2PTR(IV,d128));
     SvREADONLY_on(obj);

     *d128 = *(INT2PTR(D128 *, SvIV(SvRV(a))));
     if(_is_neg_zero(*d128) || *d128 < 0 ) *d128 *= -1.DL;
     return obj_ref;
}

SV * _overload_inc(pTHX_ SV * p, SV * second, SV * third) {
     SvREFCNT_inc(p);
     *(INT2PTR(D128 *, SvIV(SvRV(p)))) += 1.DL;
     return p;
}

SV * _overload_dec(pTHX_ SV * p, SV * second, SV * third) {
     SvREFCNT_inc(p);
     *(INT2PTR(D128 *, SvIV(SvRV(p)))) -= 1.DL;
     return p;
}

SV * _itsa(pTHX_ SV * a) {
     if(SvUOK(a)) return newSVuv(1);
     if(SvIOK(a)) return newSVuv(2);
     if(SvNOK(a)) return newSVuv(3);
     if(SvPOK(a)) return newSVuv(4);
     if(sv_isobject(a)) {
       const char *h = HvNAME(SvSTASH(SvRV(a)));
       if(strEQ(h, "Math::Decimal128")) return newSVuv(34);
     }
     return newSVuv(0);
}

SV * is_NaND128(pTHX_ SV * b) {
     if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::Decimal128"))
         return newSViv(_is_nan(*(INT2PTR(D128 *, SvIV(SvRV(b))))));
     }
     croak("Invalid argument supplied to Math::Decimal128::is_NaND128 function");
}

SV * is_InfD128(pTHX_ SV * b) {
     if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::Decimal128"))
         return newSViv(_is_inf(*(INT2PTR(D128 *, SvIV(SvRV(b))))));
     }
     croak("Invalid argument supplied to Math::Decimal128::is_InfD128 function");
}

SV * is_ZeroD128(pTHX_ SV * b) {
     if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::Decimal128"))
         if (_is_neg_zero(*(INT2PTR(D128 *, SvIV(SvRV(b)))))) return newSViv(-1);
         if (*(INT2PTR(D128 *, SvIV(SvRV(b)))) == 0.DL) return newSViv(1);
         return newSViv(0);
     }
     croak("Invalid argument supplied to Math::Decimal128::is_ZeroD128 function");
}

SV * _wrap_count(pTHX) {
     return newSVuv(PL_sv_count);
}

SV * _get_xs_version(pTHX) {
     return newSVpv(XS_VERSION, 0);
}

void _d128_bytes(pTHX_ SV * sv) {
  dXSARGS;
  _Decimal128 d128 = *(INT2PTR(_Decimal128 *, SvIV(SvRV(sv))));
  int i, n = sizeof(_Decimal128);
  char * buff;
  void * p = &d128;

  Newx(buff, 4, char);
  if(buff == NULL) croak("Failed to allocate memory in _d128_bytes function");

  sp = mark;

#ifdef WE_HAVE_BENDIAN
  for (i = 0; i < n; i++) {
#else
  for (i = n - 1; i >= 0; i--) {
#endif

    sprintf(buff, "%02X", ((unsigned char*)p)[i]);
    XPUSHs(sv_2mortal(newSVpv(buff, 0)));
  }
  PUTBACK;
  Safefree(buff);
  XSRETURN(n);
}

SV * _bid_mant(pTHX_ SV * bin) {

  D128 * d128;
  SV * obj_ref, * obj;
  int i, imax = av_len((AV*)SvRV(bin));
  char * buf;
  D128 val = 0.DL;
  extern D128 add_on[];

  Newx(d128, 1, D128);
  if(d128 == NULL) croak("Failed to allocate memory in _bid_mant function");

  for(i = 0; i <= imax; i++)
    if(SvIV(*(av_fetch((AV*)SvRV(bin), i, 0)))) val += add_on[i];

  /* If val is inf or nan this function would not have been called.
     Therefore, if val > DEC128_MAX it must be one of those illegal
     values that should be set to zero */

  if(val > 9999999999999999999999999999999999e0DL) val = 0.DL;

  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::Decimal128");

  *d128 = val;
  sv_setiv(obj, INT2PTR(IV,d128));
  SvREADONLY_on(obj);
  return obj_ref;

}

SV * _endianness(pTHX) {
#if defined(WE_HAVE_BENDIAN)
  return newSVpv("Big Endian", 0);
#elif defined(WE_HAVE_LENDIAN)
  return newSVpv("Little Endian", 0);
#else
  return &PL_sv_undef;
#endif
}

SV * _DPDtoD128(pTHX_ char * in) {
  D128 * d128;
  SV * obj_ref, * obj;
  int i, n = sizeof(D128);
  D128 out = 0.;
  void *p = &out;

  Newx(d128, 1, D128);
  if(d128 == NULL) croak("Failed to allocate memory in DPDtoD128 function");

  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::Decimal128");

  for (i = n - 1; i >= 0; i--)
#ifdef WE_HAVE_BENDIAN
    ((unsigned char*)p)[i] = in[i];
#else
    ((unsigned char*)p)[i] = in[n - 1 - i];
#endif

  *d128 = out;

  sv_setiv(obj, INT2PTR(IV,d128));
  SvREADONLY_on(obj);
  return obj_ref;
}

/*
   _assignDPD takes 2 args: a Math::DEcimal128 object, and a
   string that encodes the value to be assigned to that object
*/
void _assignDPD(pTHX_ SV * a, char * in) {
  int i, n = sizeof(D128);
  D128 out = 0.;
  void *p = &out;

  for (i = n - 1; i >= 0; i--)
#ifdef WE_HAVE_BENDIAN
    ((unsigned char*)p)[i] = in[i];
#else
    ((unsigned char*)p)[i] = in[n - 1 - i];
#endif

  *(INT2PTR(D128 *, SvIV(SvRV(a)))) = out;
}



MODULE = Math::Decimal128  PACKAGE = Math::Decimal128

PROTOTYPES: DISABLE


SV *
_is_nan_NV (x)
	SV *	x
CODE:
  RETVAL = _is_nan_NV (aTHX_ x);
OUTPUT:  RETVAL

SV *
_is_inf_NV (x)
	SV *	x
CODE:
  RETVAL = _is_inf_NV (aTHX_ x);
OUTPUT:  RETVAL

SV *
_is_neg_zero_NV (x)
	SV *	x
CODE:
  RETVAL = _is_neg_zero_NV (aTHX_ x);
OUTPUT:  RETVAL

SV *
_DEC128_MAX ()
CODE:
  RETVAL = _DEC128_MAX (aTHX);
OUTPUT:  RETVAL


SV *
_DEC128_MIN ()
CODE:
  RETVAL = _DEC128_MIN (aTHX);
OUTPUT:  RETVAL


SV *
NaND128 ()
CODE:
  RETVAL = NaND128 (aTHX);
OUTPUT:  RETVAL


SV *
InfD128 (sign)
	int	sign
CODE:
  RETVAL = InfD128 (aTHX_ sign);
OUTPUT:  RETVAL

SV *
ZeroD128 (sign)
	int	sign
CODE:
  RETVAL = ZeroD128 (aTHX_ sign);
OUTPUT:  RETVAL

SV *
UnityD128 (sign)
	int	sign
CODE:
  RETVAL = UnityD128 (aTHX_ sign);
OUTPUT:  RETVAL

SV *
Exp10l (power)
	int	power
CODE:
  RETVAL = Exp10l (aTHX_ power);
OUTPUT:  RETVAL

SV *
_testvalD128_1 (sign)
	int	sign
CODE:
  RETVAL = _testvalD128_1 (aTHX_ sign);
OUTPUT:  RETVAL

SV *
_testvalD128_2 (sign)
	int	sign
CODE:
  RETVAL = _testvalD128_2 (aTHX_ sign);
OUTPUT:  RETVAL

SV *
_testvalD128_3 (sign)
	int	sign
CODE:
  RETVAL = _testvalD128_3 (aTHX_ sign);
OUTPUT:  RETVAL

SV *
_testvalD128_4 (sign)
	int	sign
CODE:
  RETVAL = _testvalD128_4 (aTHX_ sign);
OUTPUT:  RETVAL

SV *
_MEtoD128 (msd, nsd, lsd, exponent)
	char *	msd
	char *	nsd
	char *	lsd
	SV *	exponent
CODE:
  RETVAL = _MEtoD128 (aTHX_ msd, nsd, lsd, exponent);
OUTPUT:  RETVAL

void
_assignME (a, msd, nsd, lsd, c)
	SV *	a
	char *	msd
	char *	nsd
	char *	lsd
	SV *	c
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _assignME(aTHX_ a, msd, nsd, lsd, c);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
NVtoD128 (x)
	SV *	x
CODE:
  RETVAL = NVtoD128 (aTHX_ x);
OUTPUT:  RETVAL

SV *
UVtoD128 (x)
	SV *	x
CODE:
  RETVAL = UVtoD128 (aTHX_ x);
OUTPUT:  RETVAL

SV *
IVtoD128 (x)
	SV *	x
CODE:
  RETVAL = IVtoD128 (aTHX_ x);
OUTPUT:  RETVAL

SV *
STRtoD128 (x)
	char *	x
CODE:
  RETVAL = STRtoD128 (aTHX_ x);
OUTPUT:  RETVAL

int
have_strtod128 ()


SV *
D128toNV (d128)
	SV *	d128
CODE:
  RETVAL = D128toNV (aTHX_ d128);
OUTPUT:  RETVAL

void
DESTROY (rop)
	SV *	rop
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        DESTROY(aTHX_ rop);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
assignNaNl (a)
	SV *	a
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        assignNaNl(aTHX_ a);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
assignInfl (a, sign)
	SV *	a
	int	sign
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        assignInfl(aTHX_ a, sign);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
_overload_add (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_add (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_mul (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_mul (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_sub (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_sub (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_div (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_div (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_add_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_add_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_mul_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_mul_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_sub_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_sub_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_div_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_div_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_equiv (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_equiv (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_not_equiv (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_not_equiv (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_lt (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_lt (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_gt (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_gt (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_lte (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_lte (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_gte (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_gte (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_spaceship (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_spaceship (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_copy (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_copy (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
D128toD128 (a)
	SV *	a
CODE:
  RETVAL = D128toD128 (aTHX_ a);
OUTPUT:  RETVAL

SV *
_overload_true (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_true (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_not (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_not (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_abs (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_abs (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_inc (p, second, third)
	SV *	p
	SV *	second
	SV *	third
CODE:
  RETVAL = _overload_inc (aTHX_ p, second, third);
OUTPUT:  RETVAL

SV *
_overload_dec (p, second, third)
	SV *	p
	SV *	second
	SV *	third
CODE:
  RETVAL = _overload_dec (aTHX_ p, second, third);
OUTPUT:  RETVAL

SV *
_itsa (a)
	SV *	a
CODE:
  RETVAL = _itsa (aTHX_ a);
OUTPUT:  RETVAL

SV *
is_NaND128 (b)
	SV *	b
CODE:
  RETVAL = is_NaND128 (aTHX_ b);
OUTPUT:  RETVAL

SV *
is_InfD128 (b)
	SV *	b
CODE:
  RETVAL = is_InfD128 (aTHX_ b);
OUTPUT:  RETVAL

SV *
is_ZeroD128 (b)
	SV *	b
CODE:
  RETVAL = is_ZeroD128 (aTHX_ b);
OUTPUT:  RETVAL

SV *
_wrap_count ()
CODE:
  RETVAL = _wrap_count (aTHX);
OUTPUT:  RETVAL


SV *
_get_xs_version ()
CODE:
  RETVAL = _get_xs_version (aTHX);
OUTPUT:  RETVAL


void
_d128_bytes (sv)
	SV *	sv
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _d128_bytes(aTHX_ sv);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
_bid_mant (bin)
	SV *	bin
CODE:
  RETVAL = _bid_mant (aTHX_ bin);
OUTPUT:  RETVAL

SV *
_endianness ()
CODE:
  RETVAL = _endianness (aTHX);
OUTPUT:  RETVAL


SV *
_DPDtoD128 (in)
	char *	in
CODE:
  RETVAL = _DPDtoD128 (aTHX_ in);
OUTPUT:  RETVAL

void
_assignDPD (a, in)
	SV *	a
	char *	in
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _assignDPD(aTHX_ a, in);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

