FROM registry.opensuse.org/yast/sle-15/sp2/containers/yast-cpp
# Install tmux to make sure the libyui+YaST integration tests are run
RUN zypper --non-interactive in tmux

COPY . /usr/src/app
