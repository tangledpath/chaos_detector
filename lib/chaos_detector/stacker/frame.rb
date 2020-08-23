require 'chaos_detector/refined_utils'
using ChaosDetector::RefinedUtils

# A single stack (tracepoint) frame
module ChaosDetector
  module Stacker
    class Frame
      attr_reader :domain_name
      attr_reader :mod_name
      attr_reader :mod_type
      attr_reader :fn_path
      attr_reader :fn_name
      attr_reader :callee
      attr_reader :line_num

      def initialize(mod_name: nil, mod_type: nil, fn_path: nil, domain_name:nil, fn_name:nil, line_num: nil, callee: nil)
        raise ArgumentError, "fn_name is required" if naught?(fn_name)
          # raise ArgumentError, "fn_name is required"

            #{naught(:foo).parameters.values
            #{naught(:foo).parameters

          #   %s :: %s - %s" % [
          #   decorate(domain_name),
          #   decorate(fn_name),
          #   decorate(fn_path)
          # ])
        #   raise ArgumentError, msg
        # end

        @mod_type = mod_type
        @mod_name = mod_name

        @fn_path = fn_path
        @domain_name = domain_name
        @fn_name = fn_name
        @line_num = line_num
        @callee = callee
      end

      def ==(other)
        # self.domain_name == other.domain_name &&
        self.fn_name == other.fn_name &&
        self.fn_path == other.fn_path
      end

      def to_mod_info
        ChaosDetector::ChaosGraphs::ModInfo.new(mod_name:mod_name, mod_path: fn_path, mod_type: mod_type)
      end

      def to_k
        [fn_name, fn_path].inspect
      end

      def to_s
        hkey = decorate(@domain_name, clamp: :parens)
        hkey << decorate(@mod_type.to_s[0].upcase, clamp: :angle, prefix: ' ')
        hkey << decorate(@mod_name, clamp: :bracket, prefix: ' ')
        hkey << decorate(@fn_name, clamp: :brace, prefix: ' -> ')
        hkey << decorate(@callee, clamp: :parens, prefix: '/')
        hkey << decorate(@fn_path, clamp: :none, prefix: ' ')
        hkey << decorate(@line_num, clamp: :none, prefix: ':L')
      end
    end
  end
end