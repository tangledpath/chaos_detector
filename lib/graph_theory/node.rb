require 'graph_theory/graph_theory'
class GraphTheory::Node
  ROOT_NODE_NAME = "ROOT".freeze

  attr_reader :name
  attr_reader :is_root
  attr_reader :node_origin

  def initialize(name: nil, root: false, node_origin: nil)
    unless Kernel.aught?(name) || root
      raise ArgumentError, "Must have name or be root (name=#{name})"
    end
    @is_root = root
    @name = name
    @node_origin = node_origin
  end

  def ==(other)
    self.name == other.name &&
    self.is_root == other.is_root
  end

  def to_s(scope=nil)
    self.name
  end

  def label
    self.name
  end
end
