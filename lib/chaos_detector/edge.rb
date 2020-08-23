module ChaosDetector
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

      def to_s
        ChaosDetector::Utils.decorate_pair(
          "#{@src.fn_name}:L##{@src.line_num}",
          "#{@dep.fn_name}:L##{@dep.line_num}"
        )
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

    def to_s()
      s = ChaosDetector::Utils.decorate_pair(src_node.label, dep_node.label, clamp: :angle)
      Kernel.with(@fn_call_pairs.first) {|f| s << "#{f.src.fn_name}:L##{f.src.line_num}" }
      s
    end

    def inspect(show_nodes: true, show_fn_pairs: false)
      buffy = []

      buffy << to_s if show_nodes
      if show_fn_pairs && @fn_call_pairs.any?
        buffy.concat(@fn_call_pairs.map {|f| ChaosDetector::Utils.indent(f, 2) })
      end

      buffy.join("\n")
    end
  end
end