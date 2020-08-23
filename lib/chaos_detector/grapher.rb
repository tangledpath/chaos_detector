require 'ruby-graphviz'

require_relative 'atlas'
require_relative 'options'
require_relative 'stacker/frame'
require 'graph_theory/appraiser'
require 'tcs/refined_utils'
using TCS::RefinedUtils

class ChaosDetector::Grapher
  extend TCS::Utils::CoreUtil::ChaosAttr

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
    # engine: 'dot',
    fontcolor: CLR_WHITE,
    fontname: 'Georgia',
    fontsize: '48',
    labelloc: 't',
    pencolor: CLR_WHITE,
    # ordering: 'out',
    # outputorder: 'nodesfirst',
    nodesep: '0.25',
    # newrank: 'true',
    # rankdir: 'LR',
    ranksep: '1.0',
    # size: '10,8',
    # splines: 'spline',
    strict: 'true'
  }

  SUBDOMAIN_ATTRS = {
    bgcolor: CLR_NICEGREY,
    fontsize: '16',
    rank: 'same',
    fontname: 'Verdana',
    labelloc: 't',
    pencolor: CLR_GREY,
    penwidth: '2'
  }

  NODE_ATTR={
    shape: 'egg',
    fontname: 'Verdana',
    fontsize: '12',
    # fillcolor: CLR_WHITE,
    fontcolor: CLR_WHITE,
    color: CLR_WHITE
  }

  # TODO: integrate options as needed:
  def initialize(atlas, options=nil)
    raise ArgumentError, "Atlas is required." if atlas.nil?
    @atlas = atlas
    @options = options
    @graph_metrics = GraphTheory::Appraiser.new(@atlas.graph)
  end

  def create_directed_graph(label)
    GraphViz.digraph(:G, label: label, **GRAPH_OPTS)
  end

  def add_domain_subgraph(graph, domain_name)
    domain_label = "#{domain_name.capitalize} Domain"
    graph.add_graph("cluster_#{domain_name}", label: domain_label, **SUBDOMAIN_ATTRS)
  end

  def build_graphs
    raise "Atlas isn't present!  Call record first." if @atlas.nil?
    log("Graphing from Atlas: #{@atlas.inspect}")
    log("Gathering graph metrics...")
    @graph_metrics.appraise
    log("Building module graph...")
    build_module_graph
    log("Building domain graph...")
    build_domain_graph
    log("Graph metrics")
    log(@graph_metrics.report)
  end

  def log(msg)
    log_msg(msg, subject: "Grapher")
  end

  # TODO: This has moved to chaos_graphs/....
  def build_module_graph
    # Create a new top-level graph:

    log("Creating a module-level dependency graph from atlas: #{@atlas}")
    graph = create_directed_graph("Module Dependencies")
    nodes = {}
    domain_graphs = @atlas.graph.nodes.group_by(&:domain_name).map do |domain, dnodes|
      subg = add_domain_subgraph(graph, domain)
      dnodes.each do |domain_node|
        nodes[domain_node] = build_graph_node(subg, domain_node)
      end
      [domain, subg]
    end

    log("Graph Domains: #{domain_graphs.length}")

    # nodes = graph.nodes.zip(viz_nodes).to_h

    graph_edges = {}
    @atlas.graph.edges.each do |edge|
      src = nodes.fetch(edge.src_node) do |n|
        log "src edge not found: #{n}"
        # TODO: Look up domain if necessarry.
        build_graph_node(graph, n)
      end

      dep = nodes.fetch(edge.dep_node) do |n|
        log "Dep edge not found: #{n}"
        build_graph_node(graph, n)
      end

      edge_key = [src, dep]
      unless graph_edges.has_key?(edge_key)
        log("Edge: #{src} -> #{dep}")
        graph_edges[edge_key] = graph.add_edges(src, dep, color: CLR_WHITE)
      end
      # puts "SRC: #{src}"
      # puts "DEP: #{dep}"

      # puts "-------------------------------------"
    end

    log("Writing module dependencies")
    # Generate output image
    graph.output( :png => "module_deps.png" )
  end

  def build_domain_graph
    return
    # dg = GraphViz.new( :G, type: :digraph, label: "Domain dependencies")
    dg = create_directed_graph("Domain Dependencies")

    # TODO: Add subgraph (clusters) and edges between them:

    domain_graph_nodes = @graph_metrics.domain_names.map do |dom_name|
      [dom_name, add_domain_subgraph(dg, dom_name)]
    end.to_h

    log("Domain dependencies #{@graph_metrics.domain_edges.length}")
    @graph_metrics.domain_edges.each do |k|
      src = domain_graph_nodes[k.src_domain]
      dep = domain_graph_nodes[k.dep_domain]
      log("DOMAIN EDGE: #{k.src_domain} -> #{k.dep_domain}: #{k.dep_count} (#{k.dep_count_norm.round(2)})")
      dg.add_edges(src, dep, {label: k.dep_count, penwidth: 0.5 + k.dep_count_norm * 7.5})
    end
    dg.output( :png => "domain_dep.png" )
  end

  def build_graph_node(graph, node)
    graph.add_nodes(node.label, **NODE_ATTR)
    # graph.add_nodes(label: node.label, **NODE_ATTR)
  end
end