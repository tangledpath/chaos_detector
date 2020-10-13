require 'chaos_detector/utils/str_util'
require 'chaos_detector/chaos_utils'

module ChaosDetector
  module GraphTheory
    class Node
      ROOT_NODE_NAME = 'ROOT'.freeze

      attr_reader :is_root
      attr_accessor :node_origin
      attr_reader :reduction
      attr_accessor :graph_props

      def root?
        !!is_root
      end

      def initialize(name: nil, root: false, node_origin: nil, reduction: nil)
        raise ArgumentError, "Must have name or be root (name=#{name})" unless ChaosUtils.aught?(name) || root

        @is_root = root
        @name = @is_root ? ROOT_NODE_NAME : name
        @node_origin = node_origin
        @reduction = reduction
        @graph_props = {}
      end

      def ==(other)
        name == other.name &&
          is_root == other.is_root
      end

      # Should be a reusable unique hash key for node:
      def to_k
        ChaosDetector::Utils::StrUtil.snakeize(name)
      end

      def to_s(_scope=nil)
        name
      end

      def name
        @is_root ? ROOT_NODE_NAME : @name
      end

      def title
        name
      end

      def subtitle
        nil
      end

      def root?
        !!is_root
      end


      # Mutate this Edge; combining attributes from other:
      def merge!(other)
        @reduction = ChaosDetector::GraphTheory::Reduction.combine(@reduction, other.reduction)
        self
      end
    end
  end
end
