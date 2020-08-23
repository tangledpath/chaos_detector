require 'set'
require 'chaos_detector/atlas'
require 'chaos_detector/options'
require 'chaos_detector/stack_frame'
require 'chaos_detector/utils'

module ChaosDetector
class Navigator
  REGEX_MODULE_UNDECORATE = /#<(Class:)?([a-zA-Z\:]*)(.*)>/.freeze
  DEFAULT_GROUP="default".freeze
  require 'ruby-graphviz'

  class << self
    # extend ChaosDetector::Utils::ChaosAttr
    attr_reader :options  #) { ChaosDetector::Options.new }
    attr_reader :app_root_path
    attr_reader :domain_hash
    attr_reader :module_module_hash
    attr_reader :fn_fn_hash
    attr_reader :graph

    def record(app_root_path:, domain_hash: nil, options: nil)
      # Put all options in optinos
      @options = options
      puts("  LOG_ROOT_PATH??? ")
      puts("  LOG_ROOT_PATH #{@options.log_root_path}") if @options


      @app_root_path = Pathname.new(app_root_path)
      @domain_hash = {}
      domain_hash && domain_hash.each do |path, group|
        dpath = Pathname.new(path).cleanpath.to_s
        @domain_hash[dpath] = group
        puts ("Setting #{dpath} : #{group}")
      end

      @graph = ChaosDetector::Atlas.new(options: @options)

      trace = TracePoint.new(:call, :return) do |tp|
        next unless app_root_path && tp.path.start_with?(app_root_path.to_s)

        mod_path = localize_path(path: tp.path)
        mod_name, mod_type = get_module(tp:tp)
        next if mod_name.start_with?('ChaosDetector')


        domain_name = domain_from_path(local_path: mod_path)

        if tp.method_id != tp.callee_id
          puts "XXXXX {%s} (%s)[%s] :: [%s] <> {%s}" % [domain_name, mod_type, mod_name, tp.method_id, tp.callee_id]
        end

        frame = StackFrame.new(mod_type:mod_type, mod_name: mod_name, domain_name: domain_name, path: mod_path, fn_name: tp.method_id, line_num: tp.lineno)
        frame.note = "class: #{tp.defined_class} / #{tp.defined_class&.name} / #{mod_name}"
        if tp.event == :call
          @graph.open_frame(frame: frame)
        elsif tp.event == :return
          @graph.close_frame(frame: frame)
        end
      end

      trace.enable
    end


    def build_domain_graph
      dg = GraphViz.new( :G, :type => :digraph )
      domain_edges = graph.domain_deps
      domain_edges.each do |k, count|
        puts "Edge: #{k.src_domain} -> #{k.dep_domain}: #{count}"
        src = dg.add_nodes(k.src_domain.to_s)
        dep = dg.add_nodes(k.dep_domain.to_s)
        dg.add_edges(src, dep)
      end
      dg.output( :png => "domain_dep.png" )
    end

    def build_graph_node(graph, node)
      graph.add_nodes(node.label)
    end

    def build_graph
      raise "Graph isn't present!  Call record first." if @graph.nil?

      # Create a new graph
      g = GraphViz.new( :G, :type => :digraph )

      nodes = {}
      domain_graphs = graph.nodes.group_by(&:domain_name).map do |domain, dnodes|
        subg = g.subgraph("cluster_#{domain}") do |sg|
          dnodes.each do |domain_node|
            nodes[domain_node] = build_graph_node(sg, domain_node)
          end
        end
        [domain, subg]
      end

      # nodes = graph.nodes.zip(viz_nodes).to_h

      graph.edges.each do |edge|
        src = nodes.fetch(edge.src_node) do |n|
          puts "src edge not found: #{n}"
          # TODO: Look up domain if necessarry.
          build_graph_node(g, n)
        end

        dep = nodes.fetch(edge.dep_node) do |n|
          puts "Dep edge not found: #{n}"
          build_graph_node(g, n)
        end

        # puts "SRC: #{src}"
        # puts "DEP: #{dep}"
        g.add_edges(src, dep)
        # puts "-------------------------------------"
      end

       # Generate output image
      g.output( :png => "dep.png" )

      build_domain_graph
    end

    def extract_module(tp:)
      mod_name = tp.defined_class.name

      if ChaosDetector::Utils.naught?(mod_name)
        mod_name = undecorate_module_name(tp.defined_class.to_s)
      end

      mod_name
    end

    # Undecorate all this junk:
    # a="#<Class:Authentication>"
    # b="#<Class:Person(id: integer, first"
    # c="#<ChaosDetector::Node:0x00007fdd5d2c6b08>"
    def undecorate_module_name(mod_name)
      return '' if ChaosDetector::Utils.naught?(mod_name)
      return mod_name unless mod_name.start_with?('#')

      plain_name = nil
      caps = mod_name.match(REGEX_MODULE_UNDECORATE)&.captures
      # puts "CAP #{mod_name}: #{caps}"
      if caps && caps.length > 0
        # {"#<Class:Authentication>"=>["Class:", "Authentication", ""]}
        caps.delete("Class:")
        caps.compact!
        plain_name = caps.first
        plain_name&.chomp!(':')
      end

      # puts "!!!!!!!!!!!!!!!!!!!! #{mod_name} -> #{plain_name}" unless ChaosDetector::Utils.naught?(plain_name)
      plain_name || mod_name
    end

    def get_module(tp:)
      mod_name = tp.defined_class.name
      mod_name ||= tp.defined_class.to_s
      mod_name = undecorate_module_name(mod_name)

      mod_type = case tp&.defined_class&.class
        when Class
          :class
        when Module
          :module
        else
          puts "Unknown mod_type: #{tp&.defined_class&.class}"
          :nil
        end

      [mod_name, mod_type]

      # TODO
      # WEIRD CLASS: #<Parslet::Context:0x00007fb922bbf160 vs. word
      # [#>>>CLOSE([(default) #<Parslet::Context:0x00007fb922bbf160::word <'lib/email_parser.rb'>](L#106))] Stack depth: 5 / Node count: 16

      # Pop Mismatch: [(default) #<Parslet::Context:0x00007fb922bbf160::word <'lib/email_parser.rb'>](L#106) <> [(default) EmailParser::sanitize <'lib/email_parser.rb'>](L#114)
      # POPPING from frame stack: [(default) #<Parslet::Context:0x00007fb922bbf160::word <'lib/email_parser.rb'>](L#106)

      # (clz && clz.length > 0) ? clz : tp.callee_id&.to_s
    end

    def stop
    end

    def localize_path(path:)
      # @app_root_path.relative_path_from(Pathname.new(path).cleanpath).to_s
      p = Pathname.new(path).cleanpath.to_s.sub(@app_root_path.to_s, '')
      p.start_with?('/') ? p[1..-1] : p
    end

    def domain_from_path(local_path:)
      # puts "Looking for #{local_path} in [#{domain_hash.keys.join(',')}]"
      key = domain_hash.keys.find{|k| local_path.start_with?(k)}
      key ? domain_hash[key] : DEFAULT_GROUP
      # p=@app_root_path.relative_path_from(path)

      # p = path.lstrip(app_root_path)
      # @app_root_path.relative_path_from(path)
      # domain_hash.fetch(local_path, DEFAULT_GROUP)
    end
  end
end
end