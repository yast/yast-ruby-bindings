require "forwardable"

require 'yast/yast'
require 'yast/builtins'
require 'yast/ops'

module Yast
  # Represents YCP type term enhanced by some ruby convenient methods
  #
  # Terms can be compared and can act like array of params with mark alias value.
  class Term
    include Comparable
    extend Forwardable
    include Enumerable

    def_delegators :@params, :each, :size, :empty?, :[], :[]=, :<<

    # term symbol
    attr_reader :value
    # term parameters
    attr_reader :params

    def initialize value, *params
      @value = value
      @params = params
    end

    # Find Object that match block even if it is in deep structure
    # of nested terms
    # @return [Object, nil] returns nil if doesn't find matching element
    # @example how to find widget in complex term
    #   # UIShortcuts included
    #   content = VBox(
    #               HBox(
    #                 VBox(
    #                   Hbox(
    #                     InputField(Id(:input1), "Input1"),
    #                     InputField(Id(:input2), "Input2")
    #                   )
    #                 )
    #               )
    #             )
    #  last_hbox = content.nested_find do |t|
    #                t.all? { |i| i.value == :InputField }
    #              end
    #  last_hbox << InputField(Id(:input3), "Input3") if more_info?
    #
    def nested_find(&block)
      res = find(&block)
      return res if res

      each do |o|
        next unless o.respond_to?(:nested_find)
        res = o.nested_find(&block)
        break if res
      end

      res
    end

    def clone
      Yast::Term.new value, *Yast.deep_copy(params)
    end

    def to_s
      "`#{value} (#{params.map{|p| Yast::Builtins.inside_tostring p}.join ', '})"
    end

    def <=> (other)
      res = value <=> other.value
      return res if res != 0

      list = Ops.comparable_object(params)
      return list <=> other.params
    end
  end
end
