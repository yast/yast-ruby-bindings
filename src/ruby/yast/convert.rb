require "yast/ops"
require "yast/path"
require "yast/term"
require "yast/logger"

module Yast
  module Convert

    #generate shortcuts
    Ops::SHORTCUT_TYPES.each do |type|
      eval <<END
        def self.to_#{type}(object)
          convert object, :from => "any", :to => "#{type}"
        end
END
    end

    def self.convert(object, options)
      from = options[:from].dup
      to = options[:to].dup

      #ignore whitespaces and specialization in types
      to.gsub!(/<.*>/, "")
      to.gsub!(/\s+/, "")
      from.gsub!(/<.*>/, "")
      from.gsub!(/\s+/, "")

      # reference to function
      to = "function" if to =~ /\(.*\)/

      raise "missing parameter :from" unless from
      raise "missing parameter :to" unless to

      return nil if object.nil?
      return object if from == to

      if from == "any" && allowed_type(object,to)
        return object 
      elsif to == "float"
        return nil unless (object.is_a? Fixnum) || (object.is_a? Bignum)
        return object.to_f
      elsif to == "integer"
        return nil unless object.is_a? Float
        Yast.y2warning "Conversion from integer to float lead to loose precision."
        return object.to_i
      elsif to == "locale" && from == "string"
        return object
      elsif to == "string" && from == "locale"
        return object
      else
        Yast.y2warning "Cannot convert #{object.class} from '#{from}' to '#{to}'"
        return nil
      end
    end

    def self.allowed_type(object, to)
      types = Ops::TYPES_MAP[to]
      raise "Unknown type '#{to}' for conversion" if types.nil?

      types = [types] unless types.is_a? Array
    
      return types.any? {|t|  object.is_a? t }
    end
  end
end

