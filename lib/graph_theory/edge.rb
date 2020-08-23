require 'forwardable'
require 'graph_theory/graph_theory'
class GraphTheory::Edge
  extend Forwardable

  FnCall = Struct.new(:fn_name, :line_num)
  DEFAULT_FN = 'Root'.freeze

  attr_reader :src_node
  attr_reader :dep_node
  def_instance_delegator :@src_node, :domain_name, :src_domain
  def_instance_delegator :@dep_node, :domain_name, :dep_domain

  def initialize(src_node, dep_node)
    @src_node = src_node
    @dep_node = dep_node
  end

  def ==(other)
    self.src == other.src &&
    self.dep == other.dep
  end

  def to_s()
    "[%s] -> [%s]" % [src_node.label, dep_node.label]
  end
end