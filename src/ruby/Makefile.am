#
# Makefile.am for perl-bindings/src
#

AM_CXXFLAGS = -DY2LOG=\"Perl\" -DMODULEDIR=\"$(moduledir)\"

MY_PERL_VENDORARCH = $(subst /usr,$(prefix),$(PERL_VENDORARCH))
perlpmdir = $(MY_PERL_VENDORARCH)/YaST
perlsodir = $(MY_PERL_VENDORARCH)/auto/YaST/YCP

perlpm_DATA = YCP.pm

# plugin, libtool forces 'lib' prefix
plugin_LTLIBRARIES = libpy2lang_perl.la
noinst_LTLIBRARIES = liby2lang_perl.la
perlso_LTLIBRARIES = libYCP.la

# binary part of the Perl module
libYCP_la_SOURCES =				\
	$(liby2lang_perl_la_SOURCES)		\
	YCP.cc					\
	PerlLogger.cc PerlLogger.h


# are there enough yast libraries?
# check with y2base, integrate them like y2pm does
# Originally, of the py2* there was only py2plugin here
# with the assumption that it would bring in the other plugins.
# But it does not work.
libYCP_la_LDFLAGS = $(PERL_LDFLAGS)		\
		-L$(libdir) -L$(plugindir)	\
		-Xlinker --whole-archive	\
		-lpy2scr			\
		-lpy2wfm			\
		-lscr -lyui			\
		-lycp -ly2			\
		-Xlinker --no-whole-archive	\
		${ZYPP_LIBS} -ly2util		\
		-version-info 2:0


libpy2lang_perl_la_LDFLAGS = -version-info 2:0

liby2lang_perl_la_LDFLAGS = -version-info 2:0


# the yast libraries are apparently necessary when we're loaded by perl.
libpy2lang_perl_la_LIBADD = $(PERL_LDFLAGS)	\
		-L$(libdir) -L$(plugindir)	\
		-lycp -ly2 ${ZYPP_LIBS} -ly2util
#libpy2lang_perl_la_LIBADD = $(PERL_LDFLAGS)

liby2lang_perl_la_LIBADD  = $(PERL_LDFLAGS)


liby2lang_perl_la_SOURCES =				\
	YPerl.cc YPerl.h			\
	perlxsi.c

# Auto-generated stub for dynamic loading of Perl modules.
# And also register the interface to the YCP module
## which is linked in already and won't be in the standard Perl location.
#
# This results in a linker warning:
# *** Warning: Linking the shared library libpy2lang_perl.la against the
# *** static library /usr/lib/perl5/.../DynaLoader.a is not portable!
#
# According to mls@suse.de this warning can safely be disregarded:
# The SuSE DynaLoader is compiled with -fPIC for just this situation.
#
# -- sh@suse.de 2003-07-24
perlxsi.c:
	perl -MExtUtils::Embed -e xsinit -- -o perlxsi.c -std
# See "man perlembed"


# the plugin adds the liby2 component interface

libpy2lang_perl_la_SOURCES =				\
	$(liby2lang_perl_la_SOURCES)			\
	Y2CCPerl.cc Y2CCPerl.h			\
	YPerlNamespace.cc YPerlNamespace.h	\
	Y2PerlComponent.cc Y2PerlComponent.h	

CLEANFILES = \
	perlxsi.c

INCLUDES = -I$(srcdir)/include -I$(includedir) ${ZYPP_CFLAGS}

# generated from YaPI.pm.in by configure
nodist_module_DATA = YaPI.pm

EXTRA_DIST = $(perlpm_DATA) $(module_DATA)
