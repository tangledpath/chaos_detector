require 'chaos_detector/chaos_utils'
require_relative 'comp_info'
module ChaosDetector
  module Stacker
    class FnInfo < ChaosDetector::Stacker::CompInfo
      alias_method :fn_name, :name
      alias_method :fn_line, :info
      alias_method :fn_path, :path

      def initialize(fn_name:, fn_line: nil, fn_path: nil)
        super(name:fn_name, path: fn_path, info: fn_line)
      end

      def ==(other)
        ChaosDetector::Stacker::FnInfo.match?(self, other)
      end

      def fn_info
        self
      end

      def to_s
        "##{fn_name}: #{fn_path}:L#{fn_line}"
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