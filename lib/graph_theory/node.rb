require 'tcs/utils/str_util'
require 'tcs/refined_utils'
using TCS::RefinedUtils

module GraphTheory
  class Node
    ROOT_NODE_NAME = "ROOT".freeze

    attr_reader :name
    attr_reader :is_root
    attr_accessor :node_origin

    def initialize(name: nil, root: false, node_origin: nil)
      unless aught?(name) || root
        raise ArgumentError, "Must have name or be root (name=#{name})"
      end
      @is_root = root
      @name = @is_root ? ROOT_NODE_NAME : name
      @node_origin = node_origin
    end

    def ==(other)
      name == other.name &&
        is_root == other.is_root
    end

    # Should be a reusable unique hash key for node:
    def to_k
      self.name
    end

    def to_s(scope=nil)
      mod = TCS::Utils::StrUtil.humanize_module(self.class.name, max_segments:1)
      decorate_tuple(mod, name)
    end

    def label
      nm = name
      nm ||= ROOT_NODE_NAME if is_root
      nm
    end

  end
end