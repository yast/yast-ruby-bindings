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
Version:        3.1.13
Release:        0
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        yast2-ruby-bindings-%{version}.tar.bz2
Prefix:         /usr

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  yast2-core-devel
BuildRequires:  yast2-devtools >= 3.1.10
# libzypp-devel is missing .la requires
BuildRequires:  ruby-devel
BuildRequires:  rubygem-fast_gettext
BuildRequires:  rubygem-rspec
Requires:       rubygem-fast_gettext
Requires:       yast2-core >= 2.24.0
BuildRequires:  yast2-core-devel >= 2.24.0
Requires:       yast2-ycp-ui-bindings       >= 2.21.9
BuildRequires:  yast2-ycp-ui-bindings-devel >= 2.21.9
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
cd ..

%check
cd build/tests/ruby
make test ARGS=-V
cd -

%files
%defattr (-, root, root)
%{_libdir}/YaST2/plugin/libpy2lang_ruby.so
%{_libdir}/ruby/vendor_ruby/%{rb_ver}/*.rb
%{_libdir}/ruby/vendor_ruby/%{rb_ver}/yast
%{_libdir}/ruby/vendor_ruby/%{rb_ver}/%{rb_arch}/*x.so
%{_libdir}/ruby/vendor_ruby/%{rb_ver}/%{rb_arch}/yast

%changelog
