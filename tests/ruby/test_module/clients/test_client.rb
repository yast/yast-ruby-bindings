module Yast
  class TestClient
    A_CONSTANT = 1

    def main
      Yast.include self, "example.rb"
      @test
    end
  end
end

Yast::TestClient.new.main
