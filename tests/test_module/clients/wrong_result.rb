module Yast
  class WrongResultClient
    def main
      Regexp.new(".*")
    end
  end
end

Yast::WrongResultClient.new.main

