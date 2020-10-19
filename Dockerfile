FROM registry.opensuse.org/yast/head/containers/yast-cpp:latest
# Install tmux to make sure the libyui+YaST integration tests are run
RUN zypper --non-interactive in tmux

# Enable installing docs...
RUN sed -i 's/\(rpm\.install\.excludedocs =\).*/\1 no/' /etc/zypp/zypp.conf
# ... and reinstall the RPM containing the examples we use for tests
RUN zypper --non-interactive in --force yast2-ycp-ui-bindings-devel

COPY . /usr/src/app
