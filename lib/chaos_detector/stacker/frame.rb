require 'chaos_detector/chaos_utils'
require 'chaos_detector/chaos_graphs/mod_info'
require 'chaos_detector/chaos_graphs/fn_info'

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
      attr_reader :fn_line

      def initialize(mod_name: nil, mod_type: nil, fn_path: nil, domain_name:nil, fn_name:nil, fn_line: nil, callee: nil)
        raise ArgumentError, "fn_name is required" if ChaosUtils.naught?(fn_name)
          # raise ArgumentError, "fn_name is required"

            #{naught(:foo).parameters.values
            #{naught(:foo).parameters

          #   %s :: %s - %s" % [
          #   ChaosUtils::decorate(domain_name),
          #   ChaosUtils::decorate(fn_name),
          #   ChaosUtils::decorate(fn_path)
          # ])
        #   raise ArgumentError, msg
        # end

        @mod_type = mod_type
        @mod_name = mod_name

        @fn_path = fn_path
        @domain_name = domain_name
        @fn_name = fn_name
        @fn_line = fn_line
        @callee = callee
      end

      def ==(other)
        ChaosDetector::ChaosGraphs::FnInfo.match?(self, other)
      end

      def to_mod_info
        ChaosDetector::ChaosGraphs::ModInfo.new(mod_name:mod_name, mod_path: fn_path, mod_type: mod_type)
      end

      def to_k
        [fn_name, fn_path].inspect
      end

      def to_s
        hkey = ChaosUtils::decorate(@domain_name, clamp: :parens)
        hkey << ChaosUtils::decorate(@mod_type.to_s[0].upcase, clamp: :angle, prefix: ' ')
        hkey << ChaosUtils::decorate(@mod_name, clamp: :bracket, prefix: ' ')
        hkey << ChaosUtils::decorate(@fn_name, clamp: :brace, prefix: ' -> ')
        hkey << ChaosUtils::decorate(@callee, clamp: :parens, prefix: '/')
        hkey << ChaosUtils::decorate(@fn_path, clamp: :none, prefix: ' ')
        hkey << ChaosUtils::decorate(@fn_line, clamp: :none, prefix: ':L')
      end
    end
  end
end