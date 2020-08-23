require 'ruby-graphviz'

require 'chaos_detector/atlas'
require 'chaos_detector/options'
require 'chaos_detector/stack_frame'
require 'chaos_detector/utils'

class ChaosDetector::Grapher
  extend ChaosDetector::Utils::ChaosAttr

  CLR_BLACK='black'
  CLR_DARKRED = 'red4'
  CLR_DARKGREEN = 'darkgreen'
  CLR_BRIGHTGREEN = 'yellowgreen'
  CLR_CYAN = 'cyan'
  CLR_GREY = 'snow3'
  CLR_ORANGE = 'orange'
  CLR_NICEGREY = 'snow4'
  CLR_PALEGREEN = 'palegreen'
  CLR_PINK = 'deeppink1'
  CLR_PURPLE = '#662D91'
  CLR_SLATE = "#778899"
  CLR_WHITE='white'

  GRAPH_OPTS = {
    type: :digraph,
    bgcolor: CLR_SLATE,
    center: 'true',
    color: CLR_WHITE,
    compound: 'true',
    # # concentrate: 'true',
    # # engine: 'dot',
    fontcolor: CLR_WHITE,
    fontname: 'Georgia',
    fontsize: '48',
    labelloc: 't',
    # pencolor: CLR_WHITE,
    # # ordering: 'out',
    # outputorder: 'nodesfirst',
    # nodesep: '0.25',
    # newrank: 'true',
    # rankdir: 'LR',
    # ranksep: '1.0',
    # size: '10,8',
    # splines: 'spline',
    # strict: 'true'
  }


  NODE_ATTR={
    shape: 'egg',
    fontname: 'Verdana',
    fontsize: '12',
    color: CLR_WHITE,
    fontcolor: CLR_BLACK,
    color: CLR_BLACK
  }

  def initialize(atlas)
    @atlas = atlas
  end

  def create_directed_graph
    g = GraphViz.new( :G, GRAPH_OPTS )
    # g["compound"] = "true"
  end


  def build_graphs
    raise "Atlas isn't present!  Call record first." if @atlas.nil?

    # Create a new graph
    g = create_directed_graph
    nodes = {}
    domain_graphs = @atlas.nodes.group_by(&:domain_name).map do |domain, dnodes|
      subg = g.add_graph("cluster_#{domain}")
      dnodes.each do |domain_node|
        nodes[domain_node] = build_graph_node(subg, domain_node)
      end
      [domain, subg]
    end

    # nodes = graph.nodes.zip(viz_nodes).to_h

    graph_edges = {}
    @atlas.edges.each do |edge|
      src = nodes.fetch(edge.src_node) do |n|
        puts "src edge not found: #{n}"
        # TODO: Look up domain if necessarry.
        build_graph_node(g, n)
      end

      dep = nodes.fetch(edge.dep_node) do |n|
        puts "Dep edge not found: #{n}"
        build_graph_node(g, n)
      end

      edge_key = [src, dep]
      unless graph_edges.has_key?(edge_key)
        graph_edges[edge_key] = g.add_edges(src, dep)
      end
      # puts "SRC: #{src}"
      # puts "DEP: #{dep}"

      # puts "-------------------------------------"
    end

     # Generate output image
    g.output( :png => "mod_dep.png" )

    build_domain_graph
  end

  def build_domain_graph
    dg = GraphViz.new( :G, :type => :digraph )
    domain_edges = @atlas.domain_deps
    domain_edges.each do |k, count|
      puts "Edge: #{k.src_domain} -> #{k.dep_domain}: #{count}"
      src = dg.add_nodes(k.src_domain.to_s)
      dep = dg.add_nodes(k.dep_domain.to_s)
      dg.add_edges(src, dep)
    end
    dg.output( :png => "domain_dep.png" )
  end

  def build_graph_node(graph, node)
    graph.add_nodes(node.label, NODE_ATTR)
  end
end