require 'chaos_detector/chaos_utils'

module ChaosDetector
  module Stacker
    # Base class for Component (Module, FN) Infos
    class CompInfo
      attr_accessor :path
      attr_accessor :name
      attr_accessor :info

      def initialize(name:, path: nil, info: nil)
        @name = name
        @path = path
        @info = info
      end

      def ==(other)
        self.name == other.name &&
        self.path == other.path &&
        self.info == other.info
      end

      def to_s
        "#{name}: #{path} - #{info}"
      end

    end
  end
end