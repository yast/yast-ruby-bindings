require "ycp"

module YCP
  module CommonModule
    include Exportable

    publish :method => :method_a, :type => "string(integer,integer)"
    def self.method_a first, second
      (first+second).to_s
    end

    publish :variable => :name, :type => "string"
    self.name = "Cool name"

    publish :method => :formated_name, :type => "string()"
    def self.formated_name
      return exhibit+" Fancy Formated!!!"
    end
  end
end
