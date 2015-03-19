class String
  # Removes color and cursor escape codes (modifying the string)
  # http://en.wikipedia.org/wiki/ANSI_escape_code
  def remove_ansi_sequences
    remove_ansi_color_sequences
    remove_ansi_cursor_sequences
  end

  # Removes ANSI color escape codes (modifying the string)
  def remove_ansi_color_sequences
    gsub!(/\e\[(\d|;|\[)+m/, "")
  end

  # Removes ANSI cursor movement escape codes (modifying the string)
  def remove_ansi_cursor_sequences
    gsub!(/\e\[(\d|;)*[ABCDEFfGHiJKmnSsTu]/, "")
  end
end
