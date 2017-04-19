#
# spec file for package yast2-ruby-bindings
#
# Copyright (c) 2014 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-ruby-bindings
Version:        3.2.11
Url:            https://github.com/yast/yast-ruby-bindings
Release:        0
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        yast2-ruby-bindings-%{version}.tar.bz2
Prefix:         /usr

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  yast2-core-devel
BuildRequires:  yast2-devtools >= 3.1.10
%if 0%{suse_version} == 1310
BuildRequires:  rubygem-fast_gettext
BuildRequires:  rubygem-rspec
Requires:       rubygem-fast_gettext
%else
BuildRequires:  rubygem(%{rb_default_ruby_abi}:fast_gettext)
BuildRequires:  rubygem(%{rb_default_ruby_abi}:rspec)
Requires:       rubygem(%{rb_default_ruby_abi}:fast_gettext)
%endif
BuildRequires:  ruby-devel
Requires:       yast2-core >= 3.2.2
BuildRequires:  yast2-core-devel >= 3.2.2
# UI.SetApplicationTitle
Requires:       yast2-ycp-ui-bindings       >= 3.2.0
BuildRequires:  yast2-ycp-ui-bindings-devel >= 3.2.0
# The test suite includes a regression test (std_streams_spec.rb) for a
# libyui-ncurses bug fixed in 2.47.3
BuildRequires:  libyui-ncurses >= 2.47.3
# The mentioned test requires to check if tmux is there, because tmux is
# needed to execute the test in headless systems
BuildRequires:  which

# FIXME make it optional
BuildRequires:  rubygem(%{rb_default_ruby_abi}:ruby-lint)

# only a soft dependency, the Ruby debugger is optional
Suggests:       rubygem(%{rb_default_ruby_abi}:byebug)

# Unfortunately we cannot move this to macros.yast,
# bcond within macros are ignored by osc/OBS.
%bcond_with yast_run_ci_tests
%if %{with yast_run_ci_tests}
BuildRequires: rubygem(yast-rake-ci)
%endif

Requires:       ruby
Summary:        Ruby bindings for the YaST platform
License:        GPL-2.0
Group:          System/YaST

%description
The bindings allow YaST modules to be written using the Ruby language
and also Ruby scripts can use YaST agents, APIs and modules.

%prep
%setup -n yast2-ruby-bindings-%{version}
%build
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=%{prefix} \
      -DLIB=%{_lib} \
      -DCMAKE_C_FLAGS="%{optflags}" \
      -DCMAKE_CXX_FLAGS="%{optflags}" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_SKIP_RPATH=1 \
      ..
make %{?jobs:-j %jobs} VERBOSE=1

%install
cd build
make install DESTDIR=$RPM_BUILD_ROOT

export RLREQUIRE=yast
export RLCONST=Yast
export RLDIR=$RPM_BUILD_ROOT/%{_libdir}/ruby/vendor_ruby/%{rb_ver}/ruby-lint/definitions/rpms/%{name}
mkdir -p $RLDIR
ruby -r ruby-lint -r ruby-lint/definition_generator \
  -I $RPM_BUILD_ROOT/%{_libdir}/ruby/vendor_ruby/%{rb_ver} \
  -I $RPM_BUILD_ROOT/%{_libdir}/ruby/vendor_ruby/%{rb_ver}/%{rb_arch} \
  -r $RLREQUIRE \
  -e 'RubyLint::DefinitionGenerator.new(ENV["RLCONST"], ENV["RLDIR"]).generate'

# fixup https://github.com/YorickPeterse/ruby-lint/issues/190
sed -i -e '/define_(/d' $RLDIR/*.rb

cat >> $RLDIR/yast.rb <<EOS
# Fixup definitions created by ruby-lint-2.2.0
yast_block = RubyLint.registry.get("Yast")

RubyLint.registry.register("Yast") do |defs|
  yast_block.call(defs)

  klass = defs.lookup(:const, "Yast").lookup(:const, "Module")

  # For some reason, RubyLint defines Yast::Module#publish (instance method)
  # but in fact we need               Yast::Module.publish (class method)
  klass.define_method('publish') do |method|
    method.define_argument('options')
  end
end
EOS

# now lint yourself with the help of the definitions just created
ruby -e '
File.open("ruby-lint.yml", "w") do |f|
  f.puts "presenter: emacs"
  f.puts "requires:"
  Dir.glob(ENV["RLDIR"] + "/*.rb").each do |r|
    f.puts "  - #{r}"
  end
end
'
# the pipe also masks exit codes
ruby-lint ../src/ruby | tee $RLDIR/report.log
echo -n "Total ruby-lint reports: "
wc -l $RLDIR/report.log

cd -

%check
cd build
make test ARGS=-V
cd -

# run extra CI checks (in Jenkins)
%if %{with yast_run_ci_tests}
%yast_ci_check
%endif

%files
%defattr (-, root, root)
%{yast_ybindir}/y2start
%{_libdir}/YaST2/plugin/libpy2lang_ruby.so
%{_libdir}/ruby/vendor_ruby/%{rb_ver}/*.rb
%{_libdir}/ruby/vendor_ruby/%{rb_ver}/yast
%{_libdir}/ruby/vendor_ruby/%{rb_ver}/%{rb_arch}/*x.so
%{_libdir}/ruby/vendor_ruby/%{rb_ver}/%{rb_arch}/yast
%dir %{_libdir}/ruby/vendor_ruby/%{rb_ver}/ruby-lint
%dir %{_libdir}/ruby/vendor_ruby/%{rb_ver}/ruby-lint/definitions
%dir %{_libdir}/ruby/vendor_ruby/%{rb_ver}/ruby-lint/definitions/rpms
%dir %{_libdir}/ruby/vendor_ruby/%{rb_ver}/ruby-lint/definitions/rpms/%{name}
%{_libdir}/ruby/vendor_ruby/%{rb_ver}/ruby-lint/definitions/rpms/%{name}

%changelog
