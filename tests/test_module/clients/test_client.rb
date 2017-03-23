module Yast
  class TestClient
    A_CONSTANT = 1

    def main
      Yast.include self, "example.rb"
      @test
    end
  end unless const_defined? :TestClient
  # Clients are re-eval-ed to mimic the YCP behavior;
  # but we skip the class redefinition
  # to avoid warnings about redefined constants
end

Yast::TestClient.new.main
