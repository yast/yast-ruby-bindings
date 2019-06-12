# typed: true
module Yast
  module ExampleInclude
    def initialize_example(_target)
      @test = 15
    end

    def test_plus_five
      @test + 5
    end
  end
end
