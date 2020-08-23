require 'chaos_detector/chaos_graphs/chaos_graphs'

# Encapsulate and aggregates graphs for dependency tracking
#   * Function directed graph
#   * Module directed graph - derived from function graph
#   * Domain directed graph - derived from function graph
class ChaosDetector::ChaosGraphs::ChaosGraph
  attr_reader :function_graph

  def initialize(function_graph)
    @function_graph = function_graph
    @domain_nodes = nil
    @module_modes = nil

    @domain_edges = nil
    @module_edges = nil
    @module_domain_edges = nil
    @domain_module_edges = nil
    @function_domain_edges = nil
    @domain_function_edges = nil
    # @module_graph = nil
    # @domain_graph = nil
  end

  def build_derived_graphs
    build_domain_graph
    build_module_graph
  end

  ## Derive domain-level graph from function-based graph
  def build_domain_graph

  end

  ## Derive module-level graph from function-based graph
  def build_module_graph
  end

  def build_domain_nodes
    @domain_nodes = @function_graph.nodes.group_by(&:domain_name).map do |dom_nm, fn_nodes|
      ChaosDetector::ChaosGraphs::DomainNode.new(dom_name: dom_nm, fn_node_count: fn_nodes.length)
    end
  end

  def build_module_nodes
    @module_nodes = @function_graph.nodes.group_by(&:mod_info_prime).map do |dom_nm, fn_nodes|
      ChaosDetector::ChaosGraphs::ModuleNode.new(dom_name: dom_nm, fn_node_count: fn_nodes.length)
    end
  end

  def build_inferred_edges
    edges = @function_graph.edges
    @domain_edges = group_edges_by(edges, :domain_name, :domain_name)
    @module_edges = group_edges_by(edges, :mod_info_prime, :mod_info_prime)
    @module_domain_edges = group_edges_by(edges, :mod_info_prime, :domain_name)
    @domain_module_edges = group_edges_by(edges, :domain_name, :mod_info_prime)
    @function_domain_edges = group_edges_by(edges, nil, :domain_name)
    @domain_function_edges = group_edges_by(edges, :domain_name, nil)
  end

  private
    def self.group_edges_by(edges, src, dep)
      group_edges(edges) do |src_node, dep_node|
        [(src ? src_node.send(src) : src_node), (dep ? dep_node.send(dep) : dep_node)]
      end
    end

    def self.group_edges(edges)
      raise ArgumentError, "edges argument required" unless edges
      raise ArgumentError, "Block required" unless block_given?

      groupedges = edges.group_by { |e| yield(e.src_node, e.dep_node) }
      groupedges.map do |src_dep_pair, g_edges|
        raise "Pair should have two exactly items." unless src_dep_pair.length==2
        GraphTheory::Edge.new(src_dep_pair.first, src_dep_pair.last, reduce_cnt: g_edges.length)
      end
    end

    # Edges crossing domains:
    def self.edges_x_domains(edges)
      edges.select do |e|
        aught?(e.src_domain_name) && aught?(e.dep_domain_name) &&
        e.src_domain_name != e.dep_domain_name
    end

    def log(msg)
      TCS::Utils::Util.log(msg, subject: "ChaosGraph")
    end

    def measure_cyclomatic_complexity
      @circular_paths = []
      @full_paths = []
      traverse_nodes([@function_graph.root_node])
      @path_count_uniq = @circular_paths.uniq.count + @full_paths.uniq.count
      @cyclomatic_complexity = @function_graph.edges.count - @function_graph.nodes.count + (2 * @path_count_uniq)
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
      @function_graph.edges.find_all{|e| e.src_node==node }
    end

    def fan_out_nodes(node)
      @function_graph.edges.find_all{|e| e.src_node==node }.map(&:dep_node)
    end

    def fan_in_nodes(node)
      @function_graph.edges.find_all{|e| e.dep_node==node }.map(&:src_node)
    end

    def appraise_nodes
      @node_metrics = @function_graph.nodes.map do |node|
        [node, appraise_node(node)]
      end.to_h
    end

    # For each node, measure fan-in(Ca) and fan-out(Ce)
    # TODO: Make edges parameter and appraise from different aspects
    def appraise_node(node)
      ChaosDetector::ChaosGraph::NodeMetrics.new(
        afferent_couplings: @function_graph.edges.count{|e| e.dep_node==node },
        efferent_couplings: @function_graph.edges.count{|e| e.src_node==node }
      )
    end

    def appraise_edge(edge)
    end

    def adjacency_matrix
    end

    #  Coupling: Each node couplet (Example for 100 nodes, we'd have 100 * 99 potential couplets)
    #  Capture how many other nodes depend upon both nodes in couplet [directly, indirectly]
    #  Capture how many other nodes from other domains depend upon both [directly, indirectly]
    def node_matrix
      node_matrix = Matrix.build(@function_graph.nodes.length) do |row, col|

      end
      node_matrix
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
