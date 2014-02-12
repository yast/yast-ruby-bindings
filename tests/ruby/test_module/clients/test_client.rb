module Yast
  class TestClient
    def main
      Yast.include self, "example.rb"
      @test
    end
  end
end

Yast::TestClient.new.main
