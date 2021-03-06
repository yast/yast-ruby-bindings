#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#ifndef _OW_SOURCE
#define _OW_SOURCE
#endif

#include "config.h"

#include <string>
#include <sstream>
#include <stdexcept>
#include <iconv.h>
#include <errno.h>
extern "C" {
  #ifdef HAVE_XCRYPT_H
    #include <xcrypt.h>
  #else
    #include <crypt.h>
  #endif
}
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <regex.h>

#include "ycp/y2log.h"
#include "ycp/ExecutionEnvironment.h"

#include "scr/SCR.h"
#include "scr/ScriptingAgent.h"
#include "wfm/WFM.h"

#include "ruby.h"

#include "Y2YCPTypeConv.h"
#include "Y2RubyTypeConv.h"
#include "RubyLogger.h"
#include "Y2RubyUtils.h"

static VALUE rb_mSCR;
static VALUE rb_mWFM;
static VALUE rb_mYast;
static VALUE rb_mBuiltins;
static VALUE rb_mFloat;


static SCR scr;
static WFM wfm;
static ScriptingAgent sa;

extern "C" {

  static VALUE call_builtin(const string &qualified_name, int argc, VALUE *argv)
  {
    extern StaticDeclaration static_declarations;
    YaST::ee.setFilename(RSTRING_PTR(argv[0]));
    YaST::ee.setLinenumber(FIX2INT(argv[1]));

    declaration_t *bi_dt = static_declarations.findDeclaration(qualified_name.c_str());
    if (bi_dt==NULL)
      rb_raise(rb_eNameError, "No such builtin '%s'", qualified_name.c_str());

    YEBuiltin bi_call(bi_dt);
    for (int i = 3; i<argc; ++i)
    {
      YCPValue param_v = rbvalue_2_ycpvalue(argv[i]);
      YConstPtr param_c = new YConst(YCode::ycConstant, param_v);
      constTypePtr err_tp = bi_call.attachParameter ( param_c, Type::vt2type(param_v->valuetype()));

      if (err_tp != NULL)
      {
        if (err_tp->isError())
          rb_raise(rb_eArgError,"Too much parameters passed");
        else
          rb_raise(rb_eRuntimeError,"attachParameter failed: %s",err_tp->toString().c_str());
      }
    }

    constTypePtr err_tp = bi_call.finalize(RubyLogger::instance());
    if (err_tp != NULL)
      rb_raise(rb_eRuntimeError,"Error when finalizing builtin call: %s",err_tp->toString().c_str());

    VALUE result = ycpvalue_2_rbvalue(bi_call.evaluate(false));
    return result;
  }

  static VALUE
  scr_call_builtin( int argc, VALUE *argv, VALUE self )
  {
    if (argc<3)
      rb_raise(rb_eArgError, "At least one argument must be passed");
    std::string qualified_name = std::string("SCR::") + RSTRING_PTR(argv[2]);
    return call_builtin(qualified_name,argc,argv);
  }

  static VALUE
  wfm_call_builtin( int argc, VALUE *argv, VALUE self )
  {
    if (argc<3)
      rb_raise(rb_eArgError, "At least one argument must be passed");
    std::string qualified_name = std::string("WFM::") + RSTRING_PTR(argv[2]);
    return call_builtin(qualified_name,argc,argv);
  }

  static bool recode(std::wstring &in, std::string &out)
  {
    iconv_t cd = iconv_open ("UTF-8", "WCHAR_T");

          if (cd == (iconv_t)(-1))
    {
      y2error ("iconv_open: %m");
            return false;
    }

    char* in_ptr = (char*)(in.data ());
    size_t in_len = in.length () * sizeof (wchar_t);

    const size_t buffer_size = 1024;
    char buffer[buffer_size];

    out.clear ();

    bool errors = false;

    while (in_len != (size_t)(0))
    {
      char *tmp_ptr = buffer;
      size_t tmp_size = buffer_size;
            size_t r = iconv (cd, &in_ptr, &in_len, &tmp_ptr, &tmp_size);
            size_t n = tmp_ptr - buffer;

      out.append (buffer, n);

      if (r == (size_t)(-1))
      {
        if (errno == EINVAL || errno == EILSEQ)
        {
          // more or less harmless
          out.append (1, '?');
          in_ptr += sizeof (wchar_t);
          in_len -= sizeof (wchar_t);
          errors = true;
        }
        else if (errno == E2BIG && n == 0)
        {
          // fatal: the buffer is too small to hold a
          // single multi-byte sequence
          iconv_close(cd);
          return false;
        } 
      }
    }

    if (errors)
      y2warning("recode errors");

    iconv_close(cd);

    return true;
  }

  static VALUE
  float_to_lstring(VALUE self, VALUE rfloat, VALUE rprecision)
  {
    if (NIL_P(rfloat) || NIL_P(rprecision))
      return Qnil;

    std::wostringstream ss; // bnc#683881#c12: need wide chars

    try
    {
      ss.imbue (std::locale (""));
    }
    catch (const std::runtime_error &error)
    {
      y2warning("Cannot set locale (missing glibc-locale package?): %s", error.what());
    }

    ss.precision (NUM2LONG(rprecision));
    ss << fixed<< NUM2DBL(rfloat);
    std::wstring res = ss.str();
    std::string utf_res;
    if (!recode(res,utf_res))
      return Qnil;
    return yrb_utf8_str_new(utf_res);
  }

  // TODO move to own module, it is stupid to have it as builtin
  enum crypt_ybuiltin_t { CRYPT, MD5, BLOWFISH, SHA256, SHA512 };

  static int
  read_loop (int fd, char* buffer, int count)
  {
    int offset, block;

    offset = 0;
    while (count > 0)
    {
      block = read (fd, &buffer[offset], count);

      if (block < 0)
      {
        if (errno == EINTR)
          continue;
        return block;
      }

      if (!block)
        return offset;

      offset += block;
      count -= block;
    }

    return offset;
  }


  static char*
  make_crypt_salt (const char* crypt_prefix, int crypt_rounds)
  {
    // use gensalt own auto entropy
    char* retval = crypt_gensalt_ra (crypt_prefix, crypt_rounds, NULL, 0);

    // auto entropy might not be supported in some older systems (15.2 and older),
    // if we get the EINVAL "Invalid argument" error then read some entropy from
    // /dev/urandom and try again
    if (!retval && errno == EINVAL)
    {
      const char* device = "/dev/urandom";

      int fd = open (device, O_RDONLY);
      if (fd < 0)
      {
        y2error ("Can't open %s for reading: %s\n", device, strerror (errno));
        return 0;
      }

      char entropy[16];
      const size_t entropy_len = sizeof(entropy);
      int read_size = read_loop (fd, entropy, entropy_len);
      close (fd);

      if (read_size != entropy_len)
      {
        y2error ("Unable to obtain entropy from %s\n", device);
        return 0;
      }

      retval = crypt_gensalt_ra (crypt_prefix, crypt_rounds, entropy, entropy_len);
    }

    if (!retval)
      y2error ("Unable to generate a salt, check your crypt settings: %s.\n", strerror(errno));

    return retval;
  }


  // the return value should be free'd
  char *
  crypt_pass (const char* unencrypted, crypt_ybuiltin_t use_crypt)
  {
    char* salt;

    switch (use_crypt)
    {
      case CRYPT:
        salt = make_crypt_salt ("", 0);
        break;

      case MD5:
        salt = make_crypt_salt ("$1$", 0);
        break;

      case BLOWFISH:
        salt = make_crypt_salt ("$2y$", 0);
        break;

      case SHA256:
        salt = make_crypt_salt ("$5$", 0);
        break;

      case SHA512:
        salt = make_crypt_salt ("$6$", 0);
        break;

      default:
        y2error ("Don't know crypt type %d", use_crypt);
        return 0;
    }
    if (!salt)
    {
      y2error ("Cannot create salt for crypt type %d", use_crypt);
      return 0;
    }

    struct crypt_data output;
    memset (&output, 0, sizeof (output));

    char *newencrypted = crypt_r (unencrypted, salt, &output);
    free (salt);

    if (!newencrypted
    /* catch retval magic by ow-crypt/libxcrypt */
    || !strcmp(newencrypted, "*0") || !strcmp(newencrypted, "*1"))
    {
        y2error ("crypt_r () returns 0 pointer");
        return 0;
    }
    y2debug ("encrypted %s", newencrypted);

    //data lives on stack so dup it
    return strdup(newencrypted);
  }

  VALUE crypt_internal(crypt_ybuiltin_t type, VALUE unencrypted)
  {
    const char* source = StringValuePtr(unencrypted);
    char * res = crypt_pass(source, type);
    if (!res)
      return Qnil;
    VALUE ret = yrb_utf8_str_new(res);
    free(res);
    return ret;
  }

  VALUE crypt_crypt(VALUE mod, VALUE input)
  {
    return crypt_internal(CRYPT, input);
  }

  VALUE crypt_md5(VALUE mod, VALUE input)
  {
    return crypt_internal(MD5, input);
  }

  VALUE crypt_blowfish(VALUE mod, VALUE input)
  {
    return crypt_internal(BLOWFISH, input);
  }

  VALUE crypt_sha256(VALUE mod, VALUE input)
  {
    return crypt_internal(SHA256, input);
  }

  VALUE crypt_sha512(VALUE mod, VALUE input)
  {
    return crypt_internal(SHA512, input);
  }

#define ERR_MAX 80		// for regexp
#define SUB_MAX 10		// for regexp
  //regexp builtins as ycp and ruby regexps are slightly different
  /// (regexp builtins)
  typedef struct REG_RET
  {
      string result_str;		// for regexpsub
      string match_str[SUB_MAX];	// index 0 not used!!
      int match_nb;		// 0 - 9
      string error_str;		// from regerror
      bool error;
      bool solved;
  } Reg_Ret;


  /*
   * Universal regular expression solver.
   * It is used by all regexp* ycp builtins.
   * Replacement is done if result is not ""
   */
  Reg_Ret solve_regular_expression (const char *input, const char *pattern,
            const char *result)
  {
      int status;
      char error[ERR_MAX + 1];

      regex_t compiled;
      regmatch_t matchptr[SUB_MAX + 1];

      Reg_Ret reg_ret;
      reg_ret.match_nb = 0;
      reg_ret.error = true;
      reg_ret.error_str = "";

      status = regcomp (&compiled, pattern, REG_EXTENDED);
      if (status)
      {
    regerror (status, &compiled, error, ERR_MAX);
    reg_ret.error_str = string (error);
    return reg_ret;
      }

      if (compiled.re_nsub > SUB_MAX)
      {
    snprintf (error, ERR_MAX, "too many subexpresions: %zu", compiled.re_nsub);
    reg_ret.error_str = string (error);
    regfree (&compiled);
    return reg_ret;
      }

      status = regexec (&compiled, input, compiled.re_nsub + 1, matchptr, 0);
      reg_ret.solved = !status;
      reg_ret.error = false;

      if (status)
      {
    regfree (&compiled);
    return reg_ret;
      }

      string input_str (input);

      for (unsigned int i=0; (i <= compiled.re_nsub) && (i <= SUB_MAX); i++) {
          reg_ret.match_str[i] = matchptr[i].rm_so >= 0 ? input_str.substr(matchptr[i].rm_so, matchptr[i].rm_eo - matchptr[i].rm_so) : "";
          reg_ret.match_nb = i;
      }


      string result_str;
      const char * done = result;	// text before 'done' has been dealt with
      const char * bspos = result;


      while (1) {
        bspos = strchr (bspos, '\\');
        if (bspos == NULL) // not found
    break;

        // STATE: \ seen
        ++bspos;

        if (*bspos >= '1' && *bspos <= '9') {
    // copy non-backslash text
    result_str.append (done, bspos - 1 - done);
    // copy replacement string
    result_str += reg_ret.match_str[*bspos - '0'];
    done = bspos = bspos + 1;
        }
      }
      // copy the rest
      result_str += done;
        
      reg_ret.result_str = result_str;
      regfree (&compiled);
      return reg_ret;
  }

  // documented in builtins.rb
  static VALUE regexpmatch(VALUE o, VALUE i, VALUE p)
  {
    if (NIL_P(i) || NIL_P(p))
      return Qnil;

    const char *input = StringValuePtr(i);
    const char *pattern = StringValuePtr(p);

    Reg_Ret result = solve_regular_expression (input, pattern, "");
    if (result.error)
    {
      ycp2error ("Error in regexpmatch %s %s: %s", input, pattern, result.error_str.c_str ());
      return Qnil;
    }

    return result.solved ? Qtrue : Qfalse;
  }

  static VALUE
  regexppos(VALUE o, VALUE i, VALUE p)
  {
      /**
       * @builtin regexppos 
       * @short  Returns a pair with position and length of the first match.
       * @param string INPUT
       * @param string PATTERN
       * @return list
       *
       * @description
       * If no match is found it returns an empty list.
       *
       * @see  regex(7).
       *
       * @usage regexppos ("abcd012efgh345", "[0-9]+") -> [4, 3]
       * @usage ("aaabbb", "[0-9]+") -> []
       */
    if (NIL_P(i) || NIL_P(p))
      return Qnil;

    const char *input = StringValuePtr(i);
    const char *pattern = StringValuePtr(p);


    Reg_Ret result = solve_regular_expression (input, pattern, "");

    if (result.error)
    {
      ycp2error ("Error in regexpmatch %s %s: %s", input, pattern, result.error_str.c_str ());
      return Qnil;
    }

    VALUE list = rb_ary_new2(2);
    if (result.solved) {
        std::string i(input);
        rb_ary_push (list, INT2NUM(i.find (result.match_str[0])));
        rb_ary_push (list, INT2NUM(result.match_str[0].length ()));
    }

    return list;
  }

  // documented in builtins.rb
  static VALUE
  regexpsub (VALUE o, VALUE i, VALUE p, VALUE m)
  {
    if (NIL_P(i) || NIL_P(p))
      return Qnil;

    const char *input = StringValuePtr(i);
    const char *pattern = StringValuePtr(p);
    const char *match = StringValuePtr(m);

    Reg_Ret result = solve_regular_expression (input, pattern, match);

    if (result.error)
    {
      ycp2error ("Error in regexpmatch %s %s: %s", input, pattern, result.error_str.c_str ());
      return Qnil;
    }

    if (result.solved)
      return yrb_utf8_str_new(result.result_str);

    return Qnil;
  }


  static VALUE
  regexptokenize (VALUE o, VALUE i, VALUE p)
  {
      /**
       * @builtin regexptokenize
       * @short Regex tokenize
       * @param string INPUT
       * @param string PATTERN
       * @return list
       *
       * @see regex(7).
       * @description
       * Searches a string for a POSIX Extended Regular Expression match
       * and returns a list of the matched subexpressions
       *
       * If the pattern does not match, the list is empty.
       * Otherwise the list contains then matchted subexpressions for each pair
       * of parenthesize in pattern.
       *
       * If the pattern is invalid, 'nil' is returned.
       *
       * @usage
       * Examples: 
       * // e ==  [ "aaabbB" ]
       * list e = regexptokenize ("aaabbBb", "(.*[A-Z]).*");
       *
       * // h == [ "aaab", "bb" ]
       * list h = regexptokenize ("aaabbb", "(.*ab)(.*)");
       *
       * // h == []
       * list h = regexptokenize ("aaabbb", "(.*ba).*");
       *
       * // h == nil
       * list h = regexptokenize ("aaabbb", "(.*ba).*(");
       */
      // ")
    if (NIL_P(i) || NIL_P(p))
      return Qnil;

    const char *input = StringValuePtr(i);
    const char *pattern = StringValuePtr(p);


    Reg_Ret result = solve_regular_expression (input, pattern, "");

    if (result.error)
    {
      ycp2error ("Error in regexpmatch %s %s: %s", input, pattern, result.error_str.c_str ());
      return Qnil;
    }

    VALUE list = rb_ary_new();
    if (result.solved) {
      for (int i = 1; i <= result.match_nb; i++)
      {
          rb_ary_push(list, yrb_utf8_str_new(result.match_str[i]));
      }
    }

    return list;
  }

  // a wrapper around glibc strcoll() function,
  // needed for sorting using the current locale
  static VALUE
  strcoll_wrapper(VALUE self, VALUE str1, VALUE str2)
  {
    Check_Type(str1, T_STRING);
    Check_Type(str2, T_STRING);

    return INT2FIX(strcoll(RSTRING_PTR(str1), RSTRING_PTR(str2)));
  }

  // reads the value of a hash key
  // used internally by stftime_wrapper
  static int
  tm_hash_value(VALUE hash, const char *key)
  {
    return NUM2INT(rb_hash_aref(hash, ID2SYM(rb_intern(key))));
  }
  
  // converts a hash to a tm structure
  // used internally by stftime_wrapper
  void
  hash_to_tm(VALUE hash, struct tm *res)
  {
    res->tm_sec   = tm_hash_value(hash, "tm_sec");
    res->tm_min   = tm_hash_value(hash, "tm_min");
    res->tm_hour  = tm_hash_value(hash, "tm_hour");
    res->tm_mday  = tm_hash_value(hash, "tm_mday");
    res->tm_mon   = tm_hash_value(hash, "tm_mon");
    res->tm_year  = tm_hash_value(hash, "tm_year");
    res->tm_wday  = tm_hash_value(hash, "tm_wday");
    res->tm_yday  = tm_hash_value(hash, "tm_yday");
    res->tm_isdst = tm_hash_value(hash, "tm_isdst");
  }

#define STRFTIME_MAX_LENGTH 256
  // a wrapper around strftime() function,
  // needed for formatting using the current locale
  static VALUE
  strftime_wrapper(VALUE self, VALUE time, VALUE format)
  {
    char res[STRFTIME_MAX_LENGTH];
    struct tm timeinfo;

    Check_Type(format, T_STRING);
    memset(&timeinfo, 0, sizeof timeinfo);
    hash_to_tm(time, &timeinfo);

    // Since std::put_time is not implemented in GCC4.9, we'll use
    // setlocale and strftime instead of facets
    setlocale(LC_TIME,""); // Needed to allow locale change at runtime
    if (strftime(res, sizeof(res), RSTRING_PTR(format), &timeinfo)) {
      return yrb_utf8_str_new(string(res));
    } else {
      rb_raise(rb_eRuntimeError, "The result of strftime would be longer than %d characters", STRFTIME_MAX_LENGTH);
      return Qnil;
    }
  }
}

extern "C"
{
  /*
   * Ruby module initializer
   *
   * "require 'ycpx'" will call Init_ycpx()
   */

  void
  Init_builtinx()
  {
    /*
     * module YCP
     */
    rb_mYast = rb_define_module("Yast");
    rb_define_singleton_method( rb_mYast, "strcoll", RUBY_METHOD_FUNC(strcoll_wrapper), 2);
    rb_mSCR = rb_define_module_under(rb_mYast, "SCR");
    rb_define_singleton_method( rb_mSCR, "call_builtin", RUBY_METHOD_FUNC(scr_call_builtin), -1);
    rb_mWFM = rb_define_module_under(rb_mYast, "WFM");
    rb_define_singleton_method( rb_mWFM, "call_builtin", RUBY_METHOD_FUNC(wfm_call_builtin), -1);
    rb_mBuiltins = rb_define_module_under(rb_mYast, "Builtins");
    rb_mFloat = rb_define_module_under(rb_mBuiltins, "Float");
    rb_define_singleton_method( rb_mFloat, "tolstring", RUBY_METHOD_FUNC(float_to_lstring), 2);
    rb_define_singleton_method( rb_mBuiltins, "crypt", RUBY_METHOD_FUNC(crypt_crypt), 1);
    rb_define_singleton_method( rb_mBuiltins, "cryptmd5", RUBY_METHOD_FUNC(crypt_md5), 1);
    rb_define_singleton_method( rb_mBuiltins, "cryptblowfish", RUBY_METHOD_FUNC(crypt_blowfish), 1);
    rb_define_singleton_method( rb_mBuiltins, "cryptsha256", RUBY_METHOD_FUNC(crypt_sha256), 1);
    rb_define_singleton_method( rb_mBuiltins, "cryptsha512", RUBY_METHOD_FUNC(crypt_sha512), 1);
    rb_define_singleton_method( rb_mBuiltins, "regexpmatch", RUBY_METHOD_FUNC(regexpmatch), 2);
    rb_define_singleton_method( rb_mBuiltins, "regexppos", RUBY_METHOD_FUNC(regexppos), 2);
    rb_define_singleton_method( rb_mBuiltins, "regexpsub", RUBY_METHOD_FUNC(regexpsub), 3);
    rb_define_singleton_method( rb_mBuiltins, "regexptokenize", RUBY_METHOD_FUNC(regexptokenize), 2);
    rb_define_singleton_method( rb_mBuiltins, "strftime_wrapper", RUBY_METHOD_FUNC(strftime_wrapper), 2);
  }
}
