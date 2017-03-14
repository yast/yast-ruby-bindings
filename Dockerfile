FROM yastdevel/cpp
COPY . /usr/src/app

# Install tmux to make sure the libyui+YaST integration tests are run
RUN zypper --non-interactive in tmux
