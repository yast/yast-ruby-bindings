module Yast
  class TestClient
    def main
      Yast.include "example.rb"
      test_plus_five
      @test
      5
    end
  end
end

Yast.TestClient.new.main
