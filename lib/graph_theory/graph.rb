require 'graph_theory/graph_theory'

# Maintains all nodes and edges as stack calls are pushed and popped via Frames.
class GraphTheory::Graph
  extend Forwardable
  attr_reader :root_node
  attr_reader :nodes
  attr_reader :edges

  def_delegator :@nodes, :length, :node_count
  def_delegator :@edges, :length, :edge_count

  def initialize(root_node:)
    raise ArgumentError, "Root node required." unless root_node
    @root_node = root_node
    @nodes = []
    @edges = []
  end


  def node_for(obj)
    raise ArgumentError, "#node_for requires obj" unless obj
    node_n = @nodes.index(obj)
    if node_n
      @nodes[node_n]
    else
      yield.tap {|n| @nodes << n }
    end
  end

  def edge_for_nodes(src_node, dep_node)
    puts "EEEDGE_FOR_NODES::: #{src_node.to_s} / #{dep_node.class.to_s}"
    edge = edges.find do |e|
      e.src_node == src_node && e.dep_node == dep_node
    end

    if edge.nil?
      edges << edge=GraphTheory::Edge.new(src_node, dep_node)
    end

    edge
  end

  def to_s
    "Nodes: %d, Edges: %d" % [@nodes.length, @edges.length]
  end

  def inspect
    buffy = []
    buffy << "\tNodes (#{nodes.length})"
    buffy.concat(nodes.map {|n|"\t\t#{n.label}"})

    # buffy << "Edges (#{@edges.length})"
    # buffy.concat(@edges.map {|e|"\t\t#{e.to_s}"})

    buffy.join("\n")
  end

end