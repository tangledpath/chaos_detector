require_relative 'mod_info'
require 'forwardable'
require 'graph_theory/edge'
require 'graph_theory/node'

require 'tcs/refined_utils'
using TCS::RefinedUtils

module ChaosDetector
  module ChaosGraphs
    class FnInfo
      attr_accessor :domain_name
      attr_accessor :fn_path
      attr_accessor :fn_name

      def initialize(fn_name:, fn_path: nil, domain_name:nil)
        @domain_name = domain_name
        @fn_name = fn_name
        @fn_path = fn_path
      end

      def ==(other)
        raise "Domains differ, but fn_info is the same.  Weird." if \
          self.fn_name == other.fn_name \
          && self.fn_path == other.fn_path \
          && self.domain_name != other.domain_name

        self.domain_name == other.domain_name &&
          self.fn_name == other.fn_name &&
          self.fn_path == other.fn_path
          # && (!match_line_num || self.line_num == other.line_num)
      end
    end
  end
end