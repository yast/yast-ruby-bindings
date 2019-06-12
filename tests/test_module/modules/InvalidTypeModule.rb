# typed: ignore
module Yast
  class InvalidTypeModuleClass < Module
    def a
      puts "Fail"
    end

    publish function: :a, type: "feels_good ()"
  end

  InvalidTypeModule = InvalidTypeModuleClass.new
end

Yast::InvalidTypeModule
