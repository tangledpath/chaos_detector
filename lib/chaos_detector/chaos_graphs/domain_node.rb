require 'chaos_detector/chaos_graphs/chaos_graphs'

# Domain node
class ChaosDetector::ChaosGraphs::DomainNode < GraphTheory::Node
  alias_method :domain_name, :name
  attr_reader :fn_node_count

  def initialize(domain_name:, node_origin:, fn_node_count: nil)
    super(name: domain_name)
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
end