require 'chaos_detector/chaos_utils'

module ChaosDetector
  module Stacker
    class FnInfo
      attr_accessor :fn_path
      attr_accessor :fn_name
      attr_accessor :fn_line

      def initialize(fn_name:, fn_line: nil, fn_path: nil)
        @fn_name = fn_name
        @fn_line = fn_line
        @fn_path = fn_path
      end

      def ==(other)
        ChaosDetector::Stacker::FnInfo.match?(self, other)
      end

      def to_s
        "#{fn_name}: #{fn_path}:L#{fn_line}"
      end

      class << self
        def match?(obj1, obj2, line_matching:false)
          obj1.fn_path == obj2.fn_path && obj1.fn_name == obj2.fn_name
          # (obj1.fn_name == obj2.fn_name || line_match?(obj1.fn_line, obj2.fn_line))
        end

        def line_match?(l1, l2)
          return false if l1.nil? || l2.nil?

          (l2 - l1).between?(0, 1)
        end
      end
    end
  end
end