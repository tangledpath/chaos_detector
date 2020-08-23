module ChaosDetector
  # TODO: grade edge on relative difference in its nodes:
  #   domain, path, package?
  # Coupling
  #
  # Overall check for
  # Edges that have a
  # Engines that call back to t
  class Edge
    FnCall = Struct.new(:fn_name, :line_num)
    DEFAULT_FN = 'Root'.freeze

    class FnCallCouplet
      attr_reader :src
      attr_reader :dep

      def initialize(src:, dep:)
        @src = safe_fn_call(src)
        @dep = safe_fn_call(dep)
      end

      def safe_fn_call(fn_call)
        fn_call || FnCall.new(DEFAULT_FN, nil)
      end
    end

    attr_reader :src_node
    attr_reader :dep_node
    attr_reader :fn_call_pairs

    def initialize(src_node:, dep_node:, fn_call_src:nil, fn_call_dep:nil)
      super()
      @src_node = src_node
      @dep_node = dep_node
      @fn_call_pairs = []
      add_fn_couplet(fn_call_src: fn_call_src, fn_call_dep: fn_call_dep)
    end

    def ==(other)
      self.src == other.src &&
      self.dep == other.dep
    end

    def add_fn_couplet(fn_call_src:, fn_call_dep:)
      if fn_call_src || fn_call_dep
        fn_call_pairs << FnCallCouplet.new(src: fn_call_src, dep: fn_call_dep)
      end
      #unless fn_name.nil? && line_num.nil?
      # @fn_calls[fn_call] += 1
      # cnt = @fn_calls.fetch(fn_call, 0)
      # @fn_calls[fn_call] = cnt + 1
    end

    def self.arrowize_pair(src:, dest:, indent:0, style: :brace)
      indented = (indent && indent > 0) ? "\t" * indent : nil
      open, close = case(style)
        when :bracket
          ['[', ']']
        else
          ['{', '}']
      end


      "#{indented+open*2}`#{src}`#{close} -> #{open}`#{dest}`#{close*2}"
    end

    def to_s(show_nodes: true)

      buffy = []
      buffy << arrowize_pair(src:src_node, dest:dest_node) if show_nodes

      if @fn_call_pairs.any?
        @fn_call_pairs.each do |f|
          buffy << arrowize_pair(
            src: "#{f.src.fn_name}:L##{f.src.line_num}",
            dest: "#{f.dep.fn_name}:L##{f.dep.line_num}",
            indent: 1
          )
        end
      end

      buffy.join("\n")
    end
  end
end