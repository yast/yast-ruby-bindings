require "shellwords"

class TmuxTui
  class Error < RuntimeError
  end

  def self.new_session(*args)
    new(*args)
  end

  attr_reader :session_name

  def initialize(shell_command, x: 80, y: 24, detach: true, session_name: nil)
    @shell_command = shell_command
    @x = x
    @y = y
    @detach = detach
    @session_name = session_name || new_session_name

    system "tmux", "new-session",
           "-s", @session_name,
           "-x", @x.to_s,
           "-y", @y.to_s,
           *(@detach ? ["-d"] : [] ),
           "sh", "-c", "#{@shell_command}; sleep 9999"
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
        sleep 0.1               # draw the rest of the screen
        return
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
    
  def has_session?
    system "tmux", "has-session", "-t", session_name
  end

  def kill_session
    system "tmux", "kill-session", "-t", session_name
  end
end
