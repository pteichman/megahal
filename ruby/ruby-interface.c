#include "ruby.h"
#include "../megahal.h"

static VALUE
hal_initbrain (VALUE self)
{
        megahal_initialize();
        return Qnil;
}

static VALUE
hal_doreply (VALUE self, VALUE msg)
{
        char *input;
        char *output;
        VALUE ret;

        input = STR2CSTR (msg);
        output = megahal_do_reply(input, 1);
        ret = rb_str_new2 (output);
        return ret;
}

static VALUE
hal_learn (VALUE self, VALUE msg)
{
        char *input;

        input = STR2CSTR (msg);
        megahal_learn_no_reply (input, 1);

        return Qnil;
}

static VALUE
hal_cleanup (VALUE self)
{
        megahal_cleanup();
        return Qnil;
}

VALUE rb_cHal;

void Init_Hal() {
        rb_cHal = rb_define_class("Hal", rb_cObject);
        rb_define_method(rb_cHal, "initbrain", hal_initbrain, 0);
        rb_define_method(rb_cHal, "doreply", hal_doreply, 1);
        rb_define_method(rb_cHal, "cleanup", hal_cleanup, 0);
        rb_define_method(rb_cHal, "learn", hal_learn, 1);
}
