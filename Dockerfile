FROM registry.opensuse.org/yast/head/containers/yast-cpp:latest
# Install tmux to make sure the libyui+YaST integration tests are run
RUN zypper --non-interactive in tmux

COPY . /usr/src/app
