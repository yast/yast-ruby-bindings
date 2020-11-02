require "shellwords"

# Drive interactive TUI (textual user interface) with tmux.
# https://github.com/tmux/tmux
class TmuxTui
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

  def new_session_name
    "tmux-tui-#{rand 10000}"
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
