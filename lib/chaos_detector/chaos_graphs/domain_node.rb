require 'chaos_detector/chaos_graphs/chaos_graphs'

# Domain node
class ChaosDetector::ChaosGraphs::DomainNode < GraphTheory::Node
  alias_method :domain_name, :name
  attr_reader :fn_node_count

  def initialize(domain_name:, is_root: false, node_origin:, fn_node_count: nil)
    super(name: domain_name, root: is_root, node_origin: node_origin)
    @fn_node_count = fn_node_count
  end

  def ==(other)
    self.domain_name == other&.domain_name
  end

  def label
    domain_name
  end

  def to_s
    "Domain #{domain_name} [#{@fn_node_count} Fn Nodes]"
  end

  class << self
    attr_reader :root_node
    def root_node(force_new: false)
      @root_node = self.new(is_root: true) if force_new || @root_node.nil?
      @root_node
    end
  end
end
