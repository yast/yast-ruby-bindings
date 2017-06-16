FROM yastdevel/cpp:sle12-sp3
# Install tmux to make sure the libyui+YaST integration tests are run
RUN zypper --non-interactive in tmux

COPY . /usr/src/app
