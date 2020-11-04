require 'set'
require 'ruby-graphviz'
require 'rubyvis'

require 'chaos_detector/utils/str_util'
require 'chaos_detector/chaos_utils'

module ChaosDetector
  module Graphing
    class MatrixGraphs
      CELL_WIDTH = 100
      NodeStruct = Struct.new(:node_name, :node_value, :group, :index, :link_degree)
      LinkNodeStruct = Struct.new(:index, :link_degree)
      LinkStruct = Struct.new(:source, :target, :source_node, :target_node, :value, :link_value, :link_degree)

      def initialize(chaos_graph, render_folder: nil)
        @chaos_graph = chaos_graph
        @render_folder = render_folder || 'render'
      end

      def simple_graph_struct(graph)
        groupset = graph.nodes.reduce(Set.new()) { |memo, n| memo.add(n.domain_name) }
        groups = groupset.to_a.sort!

        nodes = graph.nodes.map.with_index do |node, n|
          group_index = groups.index(node.domain_name)
          NodeStruct.new(node.title, node.to_k, group_index, n)
        end

        links = graph.edges.map do |edge|
          w = edge.weight
          src = nodes.index(edge.src_node)
          dep = nodes.index(edge.dep_node)
          LinkStruct.new(src, dep, LinkNodeStruct.new(0, w), LinkNodeStruct.new(0, w), w, w )
        end

        [nodes, links]
      end

      def render_adjacency(matrix, graph_name: 'adj-matrix')

        puts "MATRIX COUNT: #{matrix.row_size} x #{matrix.column_size} = #{matrix.count}"
        matrix.row_vectors.each{|v| puts v.to_a.inspect}

        # simple_nodes, simple_links = simple_graph_struct(graph)

        w = Math.sqrt(matrix.count) * CELL_WIDTH
        h = w

        color=Rubyvis::Colors.category19

        vis = Rubyvis::Panel.new() do
          width w
          height h
          top 90
          left 90

        end

        # layout_matrix do
        #   nodes simple_nodes
        #   links simple_links
        #   # sort {|a,b| b.group<=>a.group }
        #   directed (true)
        #   link.bar do
        #     fill_style {|l| l.link_value!=0 ?
        #      ((l.target_node.group == l.source_node.group) ? color[l.source_node.group] : "#555") : "#eee"}
        #     antialias(false)
        #     line_width(1)
        #   end
        #   node_label.label do
        #     text_style {|l| color[l.group]}
        #   end
        # end

        # vis
        #   .add(Rubyvis::Layout::Grid)
        #   .rows(matrix.to_a)
        #   .cell
        #   .add(Rubyvis::Bar)
        #   .fill_style(Rubyvis.ramp("white", "black"))
        #   .anchor("center").
        #   .add(Rubyvis::Label)
        #   .text_style(Rubyvis.ramp("black","white"))
        #   .text(lambda{|v| v.is_a?(Numeric) ?  ("%0.2f" % v) : v.to_s})

        vis.render();
        svg = vis.to_svg()

        @rendered_path = File.join(@render_folder, "#{graph_name}.svg").to_s
        ChaosDetector::Utils::FSUtil.safe_file_write(@rendered_path, content: svg)
        @rendered_path
      end

      private
        def log(msg, **opts)
          ChaosUtils.log_msg(msg, subject: 'MatrixDiagram', **opts)
        end
    end
  end
end
