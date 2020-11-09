require "shellwords"

# Drive interactive TUI (textual user interface) with tmux.
# https://github.com/tmux/tmux
class TerminalTui
  class Error < RuntimeError
  end

  def self.new_session(*args)
    new(*args)
  end

  attr_reader :session_name

  # @param session_name [String]
  def initialize(session_name: nil)
    @session_name = session_name || new_session_name
  end

  def new_session_name
    "tui-#{rand 10000}"
  end

  # Wait about 10 seconds for *pattern* to appear.
  # @param pattern [String,Regexp] a literal String or a regular expression
  # @raise [Error] if it does not appear
  # @return [void]
  def await(pattern)
    pattern = Regexp.new(Regexp.quote(pattern)) if pattern.is_a? String

    sleeps = [0.1, 0.2, 0.2, 0.5, 1, 2, 2, 5]
    txt = ""
    sleeps.each do |sl|
      txt = capture_pane
      if txt =~ pattern
        sleep 0.1 # draw the rest of the screen
        return nil
      else
        sleep sl
      end
    end
    raise Error, "Timed out waiting for #{pattern.inspect}. Seen:\n#{txt}"
  end


end

class ScreenTui < TerminalTui

  # Keys as understood by terminals (and terminal emulators)
  class Key
    attr_reader :terminfo_capname

    def initialize(terminfo_capname)
      @terminfo_capname = terminfo_capname
      @value = nil
    end

    def value
      @value ||= init_value
    end

    private

    # @return [String]
    def init_value
      # -T $TERM ?
      `tput #{terminfo_capname}`
    end

    K_LEFT   = Key.new "kcub1"
    K_DOWN   = Key.new "kcud1"
    K_UP     = Key.new "kcuu1"
    K_RIGHT  = Key.new "kcuf1"
    K_HOME   = Key.new "khome"
    K_END    = Key.new "kend"

    K_PGUP   = K_PAGEUP = Key.new "kpp"
    K_PGDN   = K_PAGEDOWN = Key.new "knp"

    K_INSERT = Key.new "kich1"
    K_DELETE = Key.new "kdch1"

    K_F1     = Key.new "kf1"
    K_F2     = Key.new "kf2"
    K_F3     = Key.new "kf3"
    K_F4     = Key.new "kf4"
    K_F5     = Key.new "kf5"
    K_F6     = Key.new "kf6"
    K_F7     = Key.new "kf7"
    K_F8     = Key.new "kf8"
    K_F9     = Key.new "kf9"
    K_F10    = Key.new "kf10"
    K_F11    = Key.new "kf11"
    K_F12    = Key.new "kf12"
  end

  def new_session(shell_command,
    xy: [80, 24], detach: true, remain_on_exit: true)
    raise ArgumentError unless block_given?

    # FIXME insecure
    @capture_fifo = "/tmp/#{@session_name}.fifo"
    out = `mkfifo #{@capture_fifo.shellescape}`
    raise out unless $?.success?

    @shell_command = shell_command
    @x, @y = xy
    @detach = detach

    detach_args = @detach ? ["-d", "-m"] : []
    remain_on_exit_args = if remain_on_exit
                            []
      # ["set-hook", "-g", "session-created", "set remain-on-exit on", ";"]
    else
      []
    end

    tmux_ret = system "screen",
                      "-c", "#{__dir__}/myscreenrc",
      * remain_on_exit_args,
      "-S", @session_name,
      * detach_args,
      "sh", "-c", shell_command
    raise "oops #{tmux_ret}" unless tmux_ret

    system "screen", "-ls"

    yield
    ensure_no_session
  end

  def capture_pane(color: false, sleep_s: 0.3)
    sleep(sleep_s)
    # FIXME: failure of the command?
    `screen -S #{session_name.shellescape} -X hardcopy #{@capture_fifo.shellescape}; cat #{@capture_fifo.shellescape}`
  end

  def capture_pane_to(filename)
    mux_command "hardcopy", "#{filename}.out.txt"
  end

  # @param key [Key]
  def send_keys(key)
    if key.is_a? Key
      stuff_string = key.value
    elsif key.start_with? "C-"
      stuff_string = "^" + key[2]
    elsif key.start_with? "M-"
      stuff_string = "^[" + key[2]
    elsif key == "Enter"
      stuff_string = "^m"
    else
      raise ArgumentError
    end

    mux_command "stuff", stuff_string
  end

  def kill_session
    mux_command "quit"
  end

  def ensure_no_session
    kill_session
    File.delete @capture_fifo
  end

  private

  def mux_command(*commands)
    system "screen", "-S", session_name, "-X", *commands
  end
end

class TmuxTui < TerminalTui
  # @param shell_command [String]
  # @param xy [(Integer, Integer)]
  # @param detach [Boolean]
  # @param remain_on_exit [Boolean] useful if shell_command may unexpectedly
  #   fail quickly. In that case we can still capture the pane
  #   and read the error messages.
  def new_session(shell_command,
    xy: [80, 24], detach: true, remain_on_exit: true)

    @shell_command = shell_command
    @x, @y = xy
    @detach = detach

    detach_args = @detach ? ["-d"] : []
    remain_on_exit_args = if remain_on_exit
      ["set-hook", "-g", "session-created", "set remain-on-exit on", ";"]
    else
      []
    end

    tmux_ret = system "tmux",
      * remain_on_exit_args,
      "new-session",
      "-s", @session_name,
      "-x", @x.to_s,
      "-y", @y.to_s,
      * detach_args,
      "sh", "-c", shell_command

    return tmux_ret unless block_given?

    yield
    ensure_no_session
  end

  # @param color [Boolean] include escape sequences to reproduce the colors
  # @param sleep [Numeric] in seconds; by default it is useful to wait a bit
  #   to give the program time to react to user input
  # @return [String]
  def capture_pane(color: false, sleep_s: 0.3)
    sleep(sleep_s)
    esc = color ? "-e" : ""
    # FIXME: failure of the command?
    `tmux capture-pane -t #{session_name.shellescape} -p #{esc}`
  end

  # Capture the pane to filename.out.txt (plain)
  # and filename.out.esc (color using terminal escapes)
  # @param filename [String]
  # @return [void]
  def capture_pane_to(filename)
    # FIXME: two separate captures could end up with different screen content.
    # If that ends up being a problem we will need to produce plain text
    # by filtering the color version

    txt = capture_pane(color: false)
    esc = capture_pane(color: true, sleep_s: 0)
    File.write("#{filename}.out.txt", txt)
    File.write("#{filename}.out.esc", esc)
  end

  # @param keys [String] "C-X" for Ctrl-X, "M-X" for Alt-X, think "Meta";
  #   for details see:
  #     man tmux | less +/"^KEY BINDINGS"
  def send_keys(keys)
    system "tmux", "send-keys", "-t", session_name, keys
  end

  def has_session? # rubocop:disable Style/PredicateName
    # the method name mimics the tmux command
    system "tmux", "has-session", "-t", session_name
  end

  def kill_session
    system "tmux", "kill-session", "-t", session_name
  end

  def ensure_no_session
    kill_session if has_session?
  end
end

class YastTui < TmuxTui
  def example(basename, &block)
    basename += ".rb" unless basename.end_with? ".rb"
    yast_ncurses = "#{__dir__}/yast_ncurses"
    example_dir = "/usr/share/doc/packages/yast2-ycp-ui-bindings/examples"

    new_session("#{yast_ncurses} #{example_dir}/#{basename}", &block)
  end
end
