#! /usr/bin/perl -w
# Martin Vidner
# $Id: YCP.pm 33405 2006-10-13 13:12:42Z mvidner $

=head1 NAME

YaST::YCP - a binary interface between Perl and YCP

=head1 SYNOPSIS

 use YaST::YCP qw(:DATA :LOGGING);

 YaST::YCP::Import ("SCR");
 my $m = SCR->Read (".sysconfig.displaymanager.DISPLAYMANAGER");
 SCR->Write (".sysconfig.kernel.CRASH_OFTEN", Boolean (1));

=head1 DATA TYPES

YaST has a richer and stricter data type system than Perl.

Note that the stdio-communicating agents, based on the modules
L<YaST::SCRAgent|YaST::SCRAgent> and L<ycp|ycp>, have a similar but
not the same data type mapping.

When the language binding knows what type to expect, eg. when passing
an argument to a YCP function, it will convert a Perl scalar to the
desired type.

On the other hand, if the type is not known, expressed
in YCP as C<any>, scalars will be passed as strings. If you want
a specific data type, use one of the data classes like
L<YaST::YCP::Integer|/Integer>. Of course these work also when
the type is known.

=over 4

=item void

Has only one value, C<nil>, which is represented as C<undef>.
Any data type can have C<nil> as a value.

=item any

A union of all data types. Any data type can be assigned to it.

=item string, integer, float, boolean

B<YCP to Perl:> Becomes a scalar

B<Perl to YCP:> Any scalar will become a string
(even if it looks like a number).
Use L</String>, L</Integer>, L</Float> or L</Boolean>
if you want a specific data type.

=item list E<lt>TE<gt>

B<YCP to Perl:> A list becomes a reference to an array.
(Note that it refers to a B<copy>.)

B<Perl to YCP:> A reference to an array becomes a list.
I<This was different before SL9.1 Beta1:>
Perl functions returning multiple values should not return a list
but a reference to it. YCP will always set a scalar calling context,
even if the result is assigned to a list.

=item map E<lt>T1, T2E<gt>

B<YCP to Perl:> A map becomes a reference to a hash.
(Note that it refers to a B<copy>.)

B<Perl to YCP:> A reference to a hash becomes a map.

=item path

B<YCP to Perl:> NOT IMPLEMENTED YET.

B<Perl to YCP:> If a path is expected, a scalar like C<".foo.bar">
will be converted to C<.foo.bar>.
Otherwise use L</Path> (which is NOT IMPLEMENTED YET).

=item symbol

B<YCP to Perl:> Becomes a L</Symbol>.

B<Perl to YCP:> If a symbol is expected, a scalar like C<"foo">
will be converted to C<`foo>.
Otherwise use L</Symbol>.

=item term

B<YCP to Perl:> Becomes a L</Term>.

B<Perl to YCP:> Use L</Term>.

=item byteblock

B<YCP to Perl:> Becomes a scalar.

B<Perl to YCP:> If a byteblock is expected, a scalar like C<"\0\1">
will be converted to C<#[0001]>.
Otherwise use L</Byteblock>.

=item locale, block E<lt>TE<gt>, ...

Not implemented.

=back

=head1 YaST::YCP

The DATA tag (in C<use YaST::YCP qw(:DATA)>) imports the data
constructor functions such as Boolean, Symbol or Term.

=cut

package YaST::YCP;
use strict;
use warnings;
use diagnostics;

require Exporter;
our @ISA = qw(Exporter);
my @e_data = qw(Boolean Byteblock Integer Float String Symbol Term);
my @e_logging = qw(y2debug y2milestone y2warning y2error y2security y2internal);
our @EXPORT_OK = (@e_data, @e_logging, "sformat");
our %EXPORT_TAGS = ( DATA => [@e_data], LOGGING => [@e_logging] );

=head2 debug

 $olddebug = YaST::YCP::debug (1);
 YaST::YCP::...
 YaST::YCP::debug ($olddebug);

Enables miscellaneous unscpecified debugging

=cut

my $debug = 0;
sub debug (;$)
{
    my $param = shift;
    if (defined $param)
    {
	$debug = $param;
    }
    return $debug;
}


## calls boot_YaST__YCP
require XSLoader;
XSLoader::load ('YaST::YCP');

=head2 init_ui

 YaST::YCP::init_ui ();
 YaST::YCP::init_ui "qt";

Initializes the user interface, "ncurses" (the default) or "qt".

=cut

# ensure that the ncurses window is closed
# and wfm and its agents are closed (#39519)
END {
    close_components (); # XS
}

=head2 Import

 YaST::YCP::Import "Namespace";
 Namespace->foo ("bar");

Imports a YaST namespace (in YCP or Perl or any supported language).
Equivalent to YCP C<import>, similar to Perl C<use>.

If C<Namespace> is in YCP, its constructor is executed later than if
it were imported from YCP. This can have subtle effects, for example
in testsuites. To get closer to the YCP import behavior, call
C<Import> from a C<BEGIN> block.

=cut

sub Import ($)
{
    my $package = shift;
    print "Importing $package\n" if debug;

    no strict;
    # let it get our autoload
    *{"${package}::AUTOLOAD"} = \&YaST::YCP::Autoload::AUTOLOAD;
}

=head2 logging

These functions go via liby2util and thus use log.conf.
See also ycp::y2milestone.

The multiple arguments are simply joined by a space.

 y2debug ($message, $message2, ...)
 y2milestone ($message, $message2, ...)
 y2warning ($message, $message2, ...)
 y2error ($message, $message2, ...)
 y2security ($message, $message2, ...)
 y2internal ($message, $message2, ...)

=cut

sub y2_logger_helper ($@)
{
    my $level = shift;
    # look _two_ frames up for the subroutine
    # when called from the main script, it will be undef
    my ($package, $filename, $line, $subroutine) = caller (2);
    # look _one_ frame up for file and line
    # (is it because of optimization?)
    ($package, $filename, $line) = caller (1);
    # this is a XS:
    y2_logger ($level, "Perl", $filename, $line, $subroutine || "",
	       join (" ", @_));
}

sub y2debug (@)		{ y2_logger_helper (0, @_); }
sub y2milestone (@)	{ y2_logger_helper (1, @_); }
sub y2warning (@)	{ y2_logger_helper (2, @_); }
sub y2error (@)		{ y2_logger_helper (3, @_); }
sub y2security (@)	{ y2_logger_helper (4, @_); }
sub y2internal (@)	{ y2_logger_helper (5, @_); }

=head2 sformat

Implements the sformat YCP builtin:

C<sformat ('%2 %% %1', "a", "b")> returns C<'b % a'>

It is useful mainly for messages marked for translation.

=cut

sub sformat ($@)
{
    # don't shift
    # now the % indices can be used for @_
    my $format = $_[0];

    # g: global, replace all occurences
    # e: expression, not a string
    $format =~ s{%([1-9%])}{
	($1 eq '%') ? '%' : $_[$1]
    }ge;

    return $format;
}

# shortcuts for the data types
# for POD see packages below

sub Boolean ($)
{
    return new YaST::YCP::Boolean (@_);
}

sub Byteblock ($)
{
    return new YaST::YCP::Byteblock (@_);
}

sub Integer ($)
{
    return new YaST::YCP::Integer (@_);
}

sub Float ($)
{
    return new YaST::YCP::Float (@_);
}

sub String ($)
{
    return new YaST::YCP::String (@_);
}

sub Symbol ($)
{
    return new YaST::YCP::Symbol (@_);
}

sub Term ($@)
{
    return new YaST::YCP::Term (@_);
}

# by defining AUTOLOAD in a separate package, undefined functions in
# the main one will be detected
package YaST::YCP::Autoload;
use strict;
use warnings;
use diagnostics;

# cannot rely on UNIVERSAL::AUTOLOAD getting automatically called
# http://www.rocketaware.com/perl/perldelta/Deprecated_Inherited_C_AUTOLOAD.htm

# Gets called instead of all functions in Import'ed modules
# It assumes a normal function, not a class or instance method
sub AUTOLOAD
{
    our $AUTOLOAD;

    # strip $self on the way from Perl to YCP,
    # just as it is added in the reverse direction
    my $himself = shift;
    print "$himself $AUTOLOAD (", join (", ", @_), ")\n" if YaST::YCP::debug;

    my @components = split ("::", $AUTOLOAD);
    my $func = pop (@components);
    return YaST::YCP::call_ycp (join ("::", @components), $func, @_);
}

=head2 Boolean

 $b = YaST::YCP::Boolean (1);
 $b->value (0);
 print $b->value, "\n";
 SCR::Write (".foo", $b);

=cut

package YaST::YCP::Boolean;
use strict;
use warnings;
use diagnostics;

# a Boolean is just a blessed reference to a scalar

sub new
{
    my $class = shift;
    my $val = shift;
    return bless \$val, $class
}

# get/set
sub value
{
    # see "Constructors and Instance Methods" in perltoot
    my $self = shift;
    if (@_) { $$self = shift; }
    return $$self;
}

=head2 Byteblock

A chunk of binary data.

 use YaST::YCP qw(:DATA);

 read ($dev_random_fh, $r, 100);
 $b = Byteblock ($r);
 $b->value ("Hello\0world\0");
 print $b->value, "\n";
 return $b;

=cut

package YaST::YCP::Byteblock;
use strict;
use warnings;
use diagnostics;

# a Byteblock is just a blessed reference to a scalar
# just like Boolean, so use it!

our @ISA = qw (YaST::YCP::Boolean);

=head2 Integer

An explicitly typed integer, useful to put in heterogenous data structures.

 use YaST::YCP qw(:DATA);

 $i = Integer ("42 and more");
 $i->value ("43, actually");
 print $i->value, "\n";
 return [ $i ];

=cut

package YaST::YCP::Integer;
use strict;
use warnings;
use diagnostics;


# an Integer is just a blessed reference to a scalar
# just like Boolean, so use it!

our @ISA = qw (YaST::YCP::Boolean);

=head2 Float

An explicitly typed float, useful to put in heterogenous data structures.

 use YaST::YCP qw(:DATA);

 $f = Float ("3.41 is PI");
 $f->value ("3.14 is PI");
 print $f->value, "\n";
 return [ $f ];

=cut

package YaST::YCP::Float;
use strict;
use warnings;
use diagnostics;


# a Float is just a blessed reference to a scalar
# just like Boolean, so use it!

our @ISA = qw (YaST::YCP::Boolean);

=head2 Path

Not implemented yet.

=cut

=head2 String

An explicitly typed string, useful to put in heterogenous data structures.

 use YaST::YCP qw(:DATA);

 $s = String (42);
 $s->value (1 + 1);
 print $s->value, "\n";
 return [ $s ];

=cut

package YaST::YCP::String;
use strict;
use warnings;
use diagnostics;

# a String is just a blessed reference to a scalar
# just like Boolean, so use it!

our @ISA = qw (YaST::YCP::Boolean);

=head2 Symbol

 use YaST::YCP qw(:DATA);

 $s = Symbol ("next");
 $s->value ("back");
 print $s->value, "\n";
 return Term ("id", $s);

=cut

package YaST::YCP::Symbol;
use strict;
use warnings;
use diagnostics;


# a Symbol is just a blessed reference to a scalar
# just like Boolean, so use it!

our @ISA = qw (YaST::YCP::Boolean);

=head2 Term

 $t = new YaST::YCP::Term("CzechBox", "Accept spam", new YaST::YCP::Boolean(0));
 $t->name ("CheckBox");
 print $t->args->[0], "\n";
 UIx::OpenDialog ($t);

=cut

package YaST::YCP::Term;
use strict;
use warnings;
use diagnostics;

# a Term has a name and arguments

sub new
{
    my $class = shift;
    my $name = shift;
    my $args = [ @_ ];
    return bless { name => $name, args => $args }, $class
}

# get/set
sub name
{
    # see "Constructors and Instance Methods" in perltoot
    my $self = shift;
    if (@_) { $self->{name} = shift; }
    return $self->{name};
}

# get/set
sub args
{
    # see "Constructors and Instance Methods" in perltoot
    my $self = shift;
    if (@_) { @{ $self->{args} } = @_; }
    # HACK:
    # because I don't want to process multiple return values,
    # I return it as a reference
    return $self->{args};
}

1;
