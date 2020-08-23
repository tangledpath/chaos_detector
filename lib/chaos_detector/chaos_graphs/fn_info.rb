require_relative 'mod_info'
require 'forwardable'
require 'chaos_detector/graph_theory/edge'
require 'chaos_detector/graph_theory/node'

require 'chaos_detector/chaos_utils'

module ChaosDetector
  module ChaosGraphs
    class FnInfo
      attr_accessor :domain_name
      attr_accessor :fn_path
      attr_accessor :fn_name
      attr_accessor :fn_line

      def initialize(fn_name:, fn_line: nil, fn_path: nil, domain_name:nil)
        @domain_name = domain_name
        @fn_name = fn_name
        @fn_line = fn_line
        @fn_path = fn_path
      end

      def ==(other)
        ChaosDetector::ChaosGraphs::FnInfo.match?(self, other)
      end

      class << self
        def match?(obj1, obj2)
          raise "Domains differ, but fn_info is the same.  Weird." if \
            obj1.fn_name == obj2.fn_name \
            && obj1.fn_path == obj2.fn_path \
            && obj1.domain_name != obj2.domain_name

          obj1.fn_path == obj2.fn_path &&
            (obj1.fn_name == obj2.fn_name || line_match?(obj1.fn_line, obj2.fn_line))
        end

        def line_match?(l1, l2)
          return false if l1.nil? || l2.nil?

          (l2 - l1).between?(0, 1)
        end

      end
    end
  end
end