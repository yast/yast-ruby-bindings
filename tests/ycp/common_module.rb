require "yast"

module Yast
  class CommonModuleClass < Module
    publish function: :method_a, type: "string(integer,integer)"
    def method_a(first, second)
      (first + second).to_s
    end

    publish variable: :name, type: "string"
    def initialize
      @name = "Cool name"
    end

    publish function: :formated_name, type: "string()"
    def formated_name
      name + " Fancy Formated!!!"
    end
  end

  CommonModule = CommonModuleClass.new
end
