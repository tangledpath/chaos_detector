require 'chaos_detector/options'
require 'chaos_detector/navigator'
require 'chaos_detector/stacker/frame'
require 'chaos_detector/graph_theory/appraiser'
require 'chaos_detector/graph_theory/graph'
require 'chaos_detector/graphing/directed'
require 'chaos_detector/chaos_graphs/chaos_graph'
require 'chaos_detector/utils/str_util'
require 'chaos_detector/chaos_utils'
require 'rubyvis'

module ChaosDetector
  module Graphing
    ### Top-level Chaos-detection graphing and rendering
    class Graphs
      attr_reader :navigator
      attr_reader :chaos_graph

      def initialize(options: nil)
        @options = options || ChaosDetector::Options.new
        @render_folder = @options.path_with_root(key: :graph_render_folder)
        # @render_folder = @options.graph_render_folder
        ChaosDetector::Utils::FSUtil.ensure_dirpath(@render_folder)
        @navigator = ChaosDetector::Navigator.new(options: @options)
      end

      def playback(row_range: nil)
        fn_graph, mod_graph = @navigator.playback(row_range: row_range)
        @chaos_graph = ChaosDetector::ChaosGraphs::ChaosGraph.new(fn_graph, mod_graph)
        @chaos_graph.infer_all
      end

      GRAPH_TYPE_ATTRS = {
        domain: {
          ratio: 'auto',
          size: '8, 8',
        },
        function: {

        },
        module: {
          rankdir: 'TB',
          packmode: 'clust'
        },
      }

      def adjacency_graph(graph_type, graph:nil, name: nil)
        rgraph = graph || chaos_graph
        g, appraiser = rgraph.graph_data_for(graph_type: graph_type)
        # rgraph = graph ? graph : g
        # graph_name = name ? name : "#{graph_type}-dep"

        # graph_attrs = GRAPH_TYPE_ATTRS[graph_type]
        matrix = appraiser.adjacency_matrix.to_a
        puts "MATRIX COUNT: #{matrix.count} / #{matrix.length}"
        w = Math.sqrt(matrix.count)
        h = w

        vis = pv.Panel.new()
          .width(w)
          .height(h)
          .bottom(0)
          .left(0)
          .right(0)
          .top(0)

          vis.add(Rubyvis::Layout::Grid).rows(matrix.to_a).
            cell.add(Rubyvis::Bar).
            fill_style(Rubyvis.ramp("white", "black")).anchor("center").
            add(Rubyvis::Label).
            text_style(Rubyvis.ramp("black","white")).
            text(lambda{|v| "%0.2f" % v })

        vis.render();
        svg = vis.to_svg()
        File.write("foo.svg", svg)
      end


      def render_dep_graph(graph_type, graph:nil, as_cluster: false, domains: false, name: nil, root: true, metrics_table: true)
        g, _appraiser = chaos_graph.graph_data_for(graph_type: graph_type)
        rgraph = graph ? graph : g
        graph_name = name ? name : "#{graph_type}-dep"

        graph_attrs = GRAPH_TYPE_ATTRS[graph_type]

        dgraph = if domains #&& graph_type != :cluster
          build_domain_dgraph(graph_name, rgraph.nodes, rgraph.edges, graph_attrs: graph_attrs, metrics_table: metrics_table)
        else
          build_dgraph(graph_name, rgraph.nodes, rgraph.edges, as_cluster: as_cluster, graph_attrs: graph_attrs, metrics_table: metrics_table)
        end

        dgraph.rendered_path
      end

      def render_domain_dep(graph_name: 'domain-dep', domain_graph: nil)
        render_dep_graph(:domain, as_cluster: true, graph: domain_graph, name: graph_name)
      end

      def render_fn_dep(graph_name: 'fn-dep', function_graph: nil, domains: false)
        render_dep_graph(:function, as_cluster: true, graph: function_graph, domains: domains, name: graph_name)
      end

      def render_mod_dep(graph_name: 'module-dep', module_graph: nil, domains: false)
        render_dep_graph(:module, graph: module_graph, domains: domains, name: graph_name)
      end

      private

        def build_dgraph(label, nodes, edges, as_cluster: false, render: true, graph_attrs: nil, metrics_table: false)
          # nodes.each do |n|
          #   p("#{label} Nodes: #{ChaosUtils.decorate(n.title)}")
          # end

          # edges.each do |e|
          #   p("#{label} Edges: #{ChaosUtils.decorate(e.src_node.title)} -> #{ChaosUtils.decorate(e.dep_node.title)}")
          # end

          dgraph = ChaosDetector::Graphing::Directed.new(render_folder: @render_folder)
          dgraph.create_directed_graph(label, graph_attrs: graph_attrs)
          dgraph.append_nodes(nodes, as_cluster: as_cluster, metrics_table: metrics_table)
          dgraph.add_edges(edges)
          dgraph.render_graph if render
          dgraph
        end

        def build_domain_dgraph(graph_name, nodes, edges, render: true, graph_attrs: nil, metrics_table: false)
          # Add domains as cluster/subgraph nodes:
          domain_nodes = nodes.map{|node| chaos_graph.domain_node_for(name: node.domain_name) }
          dgraph = build_dgraph(graph_name, domain_nodes, [], as_cluster: true, render: false, graph_attrs: graph_attrs, metrics_table: metrics_table)

          # Add nodes to domains:
          dgraph.append_nodes(nodes, metrics_table: false) do |node|
            chaos_graph.domain_node_for(name: node.domain_name)
          end
          dgraph.add_edges(edges)
          dgraph.render_graph if render
          dgraph
          # dgraph.rendered_path

          # fn_nodes = chaos_graph.function_graph.nodes.group_by(&:domain_name)
          # fn_nodes.map do |dom_nm, fn_nodes|
          #   dom_node = ChaosUtils.aught?(dom_nm) && chaos_graph.domain_node_for(name: dom_nm)
          #   dgraph.add_node_to_parent(fn_node, dom_node)
          # end
        end

    end
  end
end
