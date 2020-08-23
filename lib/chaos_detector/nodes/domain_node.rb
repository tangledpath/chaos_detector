# Domain node
class ChaosDetector::Nodes::DomainNode
  attr_reader :fn_node_count
  attr_reader :dom_name

  def initialize(dom_name:, fn_node_count: nil)
    @dom_name = dom_name
    @fn_node_count = fn_node_count
  end

  def ==(other)
    self.dom_name == other&.dom_name
  end

  def domain_name
    @domain_name
  end

  def label
    @dom_name
  end

  def to_s
    "Domain #{@dom_name} [#{@fn_node_count} Fn Nodes]"
  end
end
