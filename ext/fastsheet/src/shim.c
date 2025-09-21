#if defined(__clang__)
#  pragma clang diagnostic push
#  pragma clang diagnostic ignored "-Wunused-parameter"
#endif
#include "ruby.h"
#if defined(__clang__)
#  pragma clang diagnostic pop
#endif

VALUE rb_shim_Qnil(void) {
  return Qnil;
}

VALUE rb_shim_Qtrue(void) {
  return Qtrue;
}

VALUE rb_shim_Qfalse(void) {
  return Qfalse;
}


