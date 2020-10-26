require "shellwords"

class TmuxTui
  class Error < RuntimeError
  end

  def self.new_session(*args)
    new(*args)
  end

  attr_reader :session_name

  def initialize(shell_command,
    xy: [80, 24], detach: true, remain_on_exit: true, session_name: nil)

    @shell_command = shell_command
    @x, @y = xy
    @detach = detach
    @session_name = session_name || new_session_name

    detach_args = @detach ? ["-d"] : []
    # "remain-on-exit" is useful if shell_command may unexpectedly fail quickly.
    # In that case we can still capture the pane and read the error messages.
    remain_on_exit_args = if remain_on_exit
      ["set-hook", "-g", "session-created", "set remain-on-exit on", ";"]
    else
      []
    end

    system "tmux",
      * remain_on_exit_args,
      "new-session",
      "-s", @session_name,
      "-x", @x.to_s,
      "-y", @y.to_s,
      * detach_args,
      "sh", "-c", shell_command
  end

  def new_session_name
    "tmux-tui-#{rand 10000}"
  end

  # @return [String]
  def capture_pane(color: false)
    esc = color ? "-e" : ""
    # FIXME: failure of the command?
    `tmux capture-pane -t #{session_name.shellescape} -p #{esc}`
  end

  def capture_pane_to(filename)
    txt = capture_pane(color: false)
    esc = capture_pane(color: true)
    File.write("#{filename}.out.txt", txt)
    File.write("#{filename}.out.esc", esc)
  end

  def await(pattern)
    sleeps = [0.1, 0.2, 0.2, 0.5, 1, 2, 2, 5]
    txt = ""
    sleeps.each do |sl|
      txt = capture_pane
      case txt
      when pattern
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
