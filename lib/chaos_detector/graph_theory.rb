require 'matrix'

require 'chaos_detector/graph_theory/domain_metrics'
require 'chaos_detector/graph_theory/edge_metrics'
require 'chaos_detector/graph_theory/node_metrics'
require 'chaos_detector/graph_theory/stack_metrics'

module ChaosDetector::GraphTheory
  class GraphMetrics
    DomainEdge = Struct.new(:src_domain, :dep_domain, :dep_count, :dep_count_norm)
    attr_reader :cyclomatic_complexity
    attr_reader :domain_edges
    attr_reader :node_metrics
    attr_reader :edge_metrics

    def initialize(nodes:, edges:)
      @nodes = nodes
      @edges = edges
      @cyclomatic_complexity = nil
      @domain_edges = []
      @node_metrics = {}
      @edge_metrics = {}
    end

    def appraise
      log("Appraising nodes.")
      appraise_nodes
      log("Appraising edges.")
      appraise_edges
      log("Measuring domain dependencies.")
      measure_domain_deps
      log("Measuring cyclomatic complexity.")
      measure_cyclomatic_complexity
      log("Performed appraisal: #{report}")
    end

    def to_s
      msg = "N: %d, E: %d" % [@nodes.length, @edges.length]
      if @cyclomatic_complexity.nil?
        msg << "(Please run #appraise to gather metrics.)"
      else
        msg << " M: %d(cyclomatic_complexity), path_count = %d/%d(uniq), circular_paths = %d" % [
          @cyclomatic_complexity,
          @full_paths.length,
          @path_count_uniq,
          @circular_paths.length,
        ]
      end
    end

    def report
      buffy = [to_s]

      buffy << "Circular References #{@circular_paths.length} / #{@circular_paths.uniq.length}"
      buffy.concat(@circular_paths.map do |p|
        "  " + p.map(&:label).join(' -> ')
      end)

      # Gather nodes:
      buffy << "Nodes:"
      buffy.concat(@node_metrics.map{|n, m| "  (#{n.domain_name})#{n.label}: #{m}" })

      # Gather edges:
      # buffy << "Edges:"
      # buffy.append(@edge_metrics.map{|e, m| "  #{e}: #{m}" })

      buffy.join("\n")
    end

    def measure_domain_deps
      @edges.each do |edge|
        src_domain = edge.src_node&.domain_name
        dep_domain = edge.dep_node&.domain_name

        # log("Checking edge: #{edge} : #{src_domain && dep_domain && src_domain != dep_domain}")
        if src_domain && dep_domain && src_domain != dep_domain
          domain_edge = @domain_edges.find do |dedge|
            dedge.src_domain == src_domain && dedge.dep_domain == dep_domain
          end
          if domain_edge.nil?
            @domain_edges << DomainEdge.new(src_domain, dep_domain, 1)
          else
            domain_edge.dep_count += 1
          end
          # @domain_edges[domain_edge] = @domain_edges.fetch(domain_edge, 0) + 1
        end
      end

      normalize(domain_edges, :dep_count, :dep_count_norm)
    end

    def domain_names
      @nodes.reduce(Set[]){|set, node| set << node.domain_name}
    end

    def domain_nodes(domain)
      @nodes.find_all{|node|node.domain_name==domain}
    end

    private
      def log(msg)
        ChaosDetector::Utils.log(msg, subject: "GraphTheory")
      end

      def measure_cyclomatic_complexity
        @circular_paths = []
        @full_paths = []
        traverse_nodes
        @path_count_uniq = @circular_paths.uniq.count + @full_paths.uniq.count
        @cyclomatic_complexity = @edges.count - @nodes.count + (2 * @path_count_uniq)
      end

      # TODO: Use edgestack instead of nodestack for easier debugging?:
      def traverse_nodes(nodestack=[get_root_node])
        node = nodestack.last
        if nodestack.index(node) < nodestack.length-1
          # if (@circular_paths.length % 100).zero?
          #   p("@CCCCCCCCcircular_paths.length: #{@circular_paths.length} (#{@circular_paths.uniq.length}) / Nodestack [#{nodestack.length}]: #{nodestack.map(&:mod_name).join(' -> ')}")

          # end
          # LAST NODE IS IN STACK...CIRCULAR
          # log("Node stack is circular: #{nodestack}")
          @circular_paths << nodestack

          if (@circular_paths.length % 100).zero?
            log("Circular deps@#{@circular_paths.length}")
          end
          if @circular_paths.length > 20000
            log("Circular deps@#{@circular_paths.length} exceeded threshold; exiting!")
            puts(report)
          end
        else
          out_edges = fan_out_edges(node)
          if out_edges.none?
            @full_paths << nodestack
            # nodestack
          else
            out_edges.each do |edge|
              traverse_nodes(nodestack + [edge.dep_node])
              # if nodestack.include?(edge.dep_node)
              #   @circular_paths << nodestack + [edge.dep_node]

              #   # p("@circular_paths.length: #{@circular_paths.length} (#{@circular_paths.uniq.length})")
              #   # p("Nodestack [#{nodestack.length}]: #{nodestack.map(&:mod_name).join(' -> ') }")
              #   # p(edge)
              #   # puts
              #   # puts

              #   # if @circular_paths.length > 1000
              #   #   puts("CIRCULAR_ROUTES")
              #   #   @circular_paths.each do |p|
              #   #     puts(p.map{|n|"#{n.domain_name}:#{n.mod_name}"}.join(' -> '))
              #   #   end
              #   #   exit(true)
              #   # end
              # else
              #   traverse_nodes(nodestack + [edge.dep_node])
              # end
            end
          end

          # out_nodes = fan_out_nodes(node)
          # if out_nodes.none?
          #   @full_paths << nodestack
          #   # nodestack
          # else
          #   out_nodes.each { |out_node| traverse_nodes(nodestack + [out_node]) }
          # end
        end
      end

      def fan_out_edges(node)
        @edges.find_all{|e| e.src_node==node }
      end

      def fan_out_nodes(node)
        @edges.find_all{|e| e.src_node==node }.map(&:dep_node)
      end

      def fan_in_nodes(node)
        @edges.find_all{|e| e.dep_node==node }.map(&:src_node)
      end

      def appraise_nodes
        @node_metrics = @nodes.map do |node|
          [node, appraise_node(node)]
        end.to_h
      end

      def appraise_edges
        @edge_metrics = @edges.map do |edge|
          [edge, appraise_edge(edge)]
        end.to_h
      end

      # For each node, measure fan-in(Ca) and fan-out(Ce)
      def appraise_node(node)
        ChaosDetector::GraphTheory::NodeMetrics.new(
          afferent_couplings: @edges.count{|e| e.dep_node==node },
          efferent_couplings: @edges.count{|e| e.src_node==node }
        )
      end

      def appraise_edge(edge)
      end

      def get_root_node
        root_nodes = @nodes.find_all(&:is_root)
        raise "Root node not found!" unless root_nodes.any?
        raise "Multiple root nodes found: #{root_nodes.inspect}" if root_nodes.length > 1
        root_nodes[0]
      end

      def adjacency_matrix
      end

      #  Coupling: Each node couplet (Example for 100 nodes, we'd have 100 * 99 potential couplets)
      #  Capture how many other nodes depend upon both nodes in couplet [directly, indirectly]
      #  Capture how many other nodes from other domains depend upon both [directly, indirectly]
      def node_matrix
        node_matrix = Matrix.build(@nodes.length) do |row, col|

        end
        node_matrix
      end

      # Calculate
      def edge_metrics
      end

      # @return positive integer indicating distance in number of edges
      # from node_src to node_dep.  If multiple routes, calculate shortest:
      def node_distance(node_src, node_dep)

      end

      def normalize(ary, property, norm_property)
        vector = Vector.elements(ary.map{|obj| obj.send(property)})
        vector = vector.normalize
        ary.each_with_index do |obj, i|
          obj.send("#{norm_property}=", vector[i])
        end
        ary
      end


    #   Report edge on relative difference in its nodes:
    #   domain, path, package?
    # domain, path, package?
    # Coupling
    #
    # Overall check for
    # Edges that have a
    # Engines that call back to t
    # Report for all edges

  end
end