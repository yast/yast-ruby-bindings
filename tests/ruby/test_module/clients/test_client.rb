module Yast
  class TestClient
    def main
      Yast.include "example.rb"
      @test
    end
  end
end

Yast.TestClient.new
