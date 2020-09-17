require 'chaos_detector/chaos_utils'

module ChaosDetector
  module Stacker
    # Base class for Component (Module, FN) Infos
    COMPONENT_TYPES = %i[function module domain].freeze
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
        name == other.name &&
          path == other.path &&
          info == other.info
      end

      def to_s
        "#{name}: #{path} - #{info}"
      end

      def component_type
        raise NotImplementedError, 'Deriving class should implement #component_type'
      end
    end
  end
end
