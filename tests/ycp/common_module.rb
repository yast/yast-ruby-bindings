require "ycp"

module YCP
  class CommonModuleClass
    extend Exportable

    publish :function => :method_a, :type => "string(integer,integer)"
    def method_a first, second
      (first+second).to_s
    end

    publish :variable => :name, :type => "string"
    def initialize
      @name = "Cool name"
    end

    publish :function => :formated_name, :type => "string()"
    def formated_name
      return name+" Fancy Formated!!!"
    end
  end

  CommonModule = CommonModuleClass.new
end
