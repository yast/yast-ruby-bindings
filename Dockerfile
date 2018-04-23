FROM yastdevel/cpp:sle12-sp4

# Install tmux to make sure the libyui+YaST integration tests are run
RUN zypper --non-interactive in tmux

COPY . /usr/src/app
