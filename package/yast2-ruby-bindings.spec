#
# spec file for package yast2-ruby-bindings
#

Name:           yast2-ruby-bindings
Version:        3.1.7
Release:        0
License:        GPL-2.0
Group:          System/YaST
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        yast2-ruby-bindings-%{version}.tar.bz2
Prefix:         /usr

BuildRequires:	cmake gcc-c++ yast2-core-devel
BuildRequires:  yast2-devtools >= 3.1.10
# libzypp-devel is missing .la requires
BuildRequires:	ruby-devel
BuildRequires:	rubygem-fast_gettext
BuildRequires:  rubygem-rspec
Requires:	rubygem-fast_gettext
Requires:     	yast2-core >= 2.24.0
BuildRequires:  yast2-core-devel >= 2.24.0
Requires:       yast2-ycp-ui-bindings       >= 2.21.9
BuildRequires:  yast2-ycp-ui-bindings-devel >= 2.21.9
Requires:	ruby
Summary:	Ruby bindings for the YaST platform

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
