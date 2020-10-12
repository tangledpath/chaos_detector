# Maintains all nodes and edges as stack calls are pushed and popped via Frames.
module ChaosDetector
  module GraphTheory
    class Graph
      # extend Forwardable
      attr_reader :root_node
      attr_reader :nodes
      attr_reader :edges

      # def_delegator :@nodes, :length, :node_count
      # def_delegator :@edges, :length, :edge_count

      def node_count
        @nodes.length
      end

      def edge_count
        @edges.length
      end

      def initialize(root_node:, nodes: nil, edges: nil)
        raise ArgumentError, 'Root node required.' unless root_node

        @root_node = root_node
        @nodes = nodes || []
        @edges = edges || []
      end

      # Return a new Graph object that only includes the given nodes and matching edges:
      def arrange_with(nodes:)
        gnodes = nodes.map(&:clone)
        gnodes << root_node unless(gnodes.include?(root_node))
        gedges = edges.filter do |edge|
          gnodes.any?{|node| edge.src_node==node || edge.dep_node==node }
        end

        ChaosDetector::GraphTheory::Graph.new(
          root_node: root_node,
          nodes: gnodes,
          edges: gedges
        )
      end

      def traversal
        to_enum(:traverse).map(&:itself) # {|n| puts "TNode:#{n}"; n.label}
      end

      # Possibly useful:
      # def traversal(loop_detector: nil)
      #   trace_nodes = []

      #   traverse do |node|
      #     if loop_detector.nil? || loop_detector.tolerates?(trace_nodes, node)
      #       trace_nodes << node
      #     end
      #   end

      #   trace_nodes
      # end

      ### Depth-first traversal
      # Consumes each edge as it used
      def traverse(origin_node: nil)
        raise ArgumentError, 'traverse requires block' unless block_given?
        edges = @edges
        nodes_to_visit = [origin_node || root_node]
        while nodes_to_visit.length > 0
          node = nodes_to_visit.shift
          yield(node)
          out_edges, edges = edges.partition { |e| e.src_node == node }
          child_nodes = out_edges.map(&:dep_node)
          nodes_to_visit = child_nodes + nodes_to_visit
        end
      end

      def children(node)
        @edges.select { |e| e.src_node == node }.map(&:dep_node).inject do |child_nodes|
          puts "Found children for #{node.label}: #{child_nodes}"
        end
      end

      def node_for(obj)
        raise ArgumentError, '#node_for requires obj' unless obj

        node_n = @nodes.index(obj)
        if node_n
          @nodes[node_n]
        else
          yield.tap { |n| @nodes << n }
        end
      end

      def edges_for_node(node)
        edges.filter do |e|
          e.src_node == node || e.dep_node == node
        end
      end

      def edge_for_nodes(src_node, dep_node)
        # puts "EEEDGE_FOR_NODES::: #{src_node.to_s} / #{dep_node.class.to_s}"
        edge = edges.find do |e|
          e.src_node == src_node && e.dep_node == dep_node
        end

        edges << edge = ChaosDetector::GraphTheory::Edge.new(src_node, dep_node) if edge.nil?

        edge
      end

      def ==(other)
        root_node == other.root_node &&
          nodes == other.nodes &&
          edges == other.edges
      end

      def to_s
        format('Nodes: %d, Edges: %d', @nodes.length, @edges.length)
      end

      def inspect
        buffy = []
        buffy << "\tNodes (#{nodes.length})"
        buffy.concat(nodes.map { |n| "\t\t#{n.title}"})

        # buffy << "Edges (#{@edges.length})"
        # buffy.concat(@edges.map {|e|"\t\t#{e.to_s}"})

        buffy.join("\n")
      end
    end
  end
end
