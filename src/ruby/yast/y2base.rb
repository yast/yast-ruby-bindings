module Yast
  module Y2Base

    # Parses ARGV of y2base. it returns map with keys:
    #
    # - :generic_options [Hash]
    # - :client_name [String, nil]
    # - :client_options [Hash]
    # - :server_name [String, nil]
    # - :server_options [Array] ( of unparsed options as server parse it on its own)
    # @raise RuntimeError when unknown option appear or used wrongly
    def self.parse_arguments(args)
      ret = {}

      ret[:generic_options] = parse_generic_options(args)
      ret[:client_name] = args.shift
      ret[:client_options] = parse_client_options(args)
      ret[:server_name] = args.shift
      ret[:server_options] = args

      ret
    end

    private_class_method def self.parse_generic_options(args)
      res = {}
      loop do
        return res unless option?(args.first)

        raise "Unknown option #{args.first}"
      end
    end

    private_class_method def self.parse_client_options(args)
      res = {}
      string_param = false
      params = []
      loop do
        return res unless option?(args.first)

        arg = args.shift
        case arg
        when "-S"
          string_param = true
        when /^\(/
          raise "Only string client parameters supported" unless string_param

          params << arg[1..-1]
        else
          raise "Unknown option #{arg}"
        end
      end
      res[:params] = params

      res
    end

    private_class_method def self.option?(arg)
      return true if arg[0] == "-"
      return true if arg[0] == "(" && arg[-1] == ")"

      return false
    end
  end
end
