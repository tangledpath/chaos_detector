require 'set'
require 'pathname'
require_relative 'atlas'
require_relative 'options'
require_relative 'chaos_graphs/mod_info'
require_relative 'chaos_graphs/module_node'
require_relative 'stacker/frame'
require_relative 'walkman'
require 'chaos_detector/chaos_utils'

# The main interface for intercepting tracepoints,
# and converting them into recordable and playable
# stack/trace frames

module ChaosDetector
  class Navigator
    REGEX_MODULE_UNDECORATE = /#<(Class:)?([a-zA-Z\:]*)(.*)>/.freeze
    DEFAULT_GROUP="default".freeze
    FRAME_ACTIONS = [:call, :return, :class, :end]

    attr_reader :options
    attr_reader :atlas
    attr_reader :app_root_path
    attr_reader :domain_hash
    attr_reader :module_module_hash
    attr_reader :fn_fn_hash
    attr_reader :walkman
    attr_reader :stopped
    attr_reader :module_stack

    def initialize(options:)
      raise ArgumentError, "#initialize requires options" if options.nil?
      @options = options
      @stopped = false
      @paused = false
      @module_stack = []
      @total_traces = 0
      apply_options
    end

    ### Playback of walkman CSV file:
    def playback()
      log("Detecting chaos in playback via walkman")
      @total_traces = 0
      @walkman.playback do |rownum, action, frame|
        log("Performing :#{action} on frame: #{frame}")
        frame_act = case action.to_sym
          when :open
            :call
          when :close, :pop
            :return
        end
        perform_frame_action(frame, action: frame_act, record: false)

        if (rownum % 50000).zero?
          log("Walkman Row# #{rownum}")
          log(@atlas.stack.inspect)
        end
      end
      @atlas
    end

    def record()
      log("Detecting chaos at #{@app_root_path}")
      @module_stack.clear
      @walkman.record_start
      @total_traces = 0
      @trace = TracePoint.new(*FRAME_ACTIONS) do |tracepoint|
        if @stopped
          @trace.disable
          log("Tracing stopped; stopping immediately.")
          next
        end

        next if @paused

        puts "BOOMPaused=#{@paused}" if @paused
        begin
          @paused = true
          if ['ChaosUtils::decorate', 'complete?'].include?(tracepoint.method_id.to_s)
            cl = tracepoint.binding.eval('caller_locations(0,19)')

            sep = tracepoint.event == :return ? '*' : '@'

            puts
            puts tracepoint.event.to_s.upcase
            puts ChaosUtils::decorate(tracepoint.inspect)
            puts sep * 50
            puts cl.join("\n\t->\t")
            puts ">" * 50
            puts
          end

          tracepoint.disable

          if [:class, :end].include?tracepoint.event
            # puts tracepoint.inspect
            # FUN: TODO.
            next
          end

          next if full_path_skip?(tracepoint.path)
          @total_traces += 1
          frame = frame_at_trace(tracepoint)

          # Generic module exclusion:
          if module_skip?(frame.mod_name)
            @skipped ||= Set[]
            puts "Skipping module #{frame.mod_name}" unless @skipped.include?frame.mod_name
            @skipped << frame.mod_name
            next
          end

          @module_stack.unshift(frame.to_mod_info) if ChaosUtils.aught?frame.mod_name

          # DISABLE MORE OF ABOVE?
          perform_frame_action(frame, action: tracepoint.event, record: true)
        ensure
          @paused = false
          tracepoint.enable
        end
      end

      @trace.enable
      @atlas
    end

    def stop
      @stopped = true
      @trace&.disable
      log("Stopping after total traces: #{@total_traces}")
      @walkman.stop
      @atlas.stop
    end

    # Undecorate all this junk:
    # a="#<Class:Authentication>"
    # b="#<Class:Person(id: integer, first"
    # c="#<ChaosDetector::Node:0x00007fdd5d2c6b08>"

    # Blank class get mod_class for tracepoint. [#<Class:#<Parslet::Context:0x00007fa90ee06c80>>]
    # MMMM >>> (word), (default), (word), (lib/email_parser.rb):L106, (#<Parslet::Context:0x00007fa90ee06c80>)
    def undecorate_module_name(mod_name)
      return nil if ChaosUtils.naught?(mod_name)
      return mod_name unless mod_name.start_with?('#')

      plain_name = nil
      caps = mod_name.match(REGEX_MODULE_UNDECORATE)&.captures
      # puts "CAP #{mod_name}: #{caps}"
      if caps && caps.length > 0
        caps.delete("Class:")
        caps.compact!
        plain_name = caps.first
        plain_name&.chomp!(':')
      end

      plain_name || mod_name
    end

    private

      def perform_frame_action(frame, action:, record: false)
        raise ArgumentError, "#perform_frame_action requires frame" if frame.nil?

        if action == :call
          @atlas.open_frame(frame)
          @walkman.write_frame(frame, action: :open) if record
        elsif action == :return
          offset = @atlas.close_frame(frame)
          frame_act = offset.nil? ? :close : :pop
          # puts "Offset is #{offset} on closing frame #{frame}" if offset && offset > 0
          @walkman.write_frame(frame, action: frame_act, frame_offset: offset) if record
        else
          raise ArgumentError, "Action should be one of: #{FRAME_ACTIONS.inspect}.  Actual value: #{action.inspect}"
        end

        if (@total_traces % 50000).zero?
          log("Frame Actions# #{@total_traces}.  Here is the stack")
          log(@atlas.frame_stack.inspect)
        end
      end

      def frame_at_trace(tracepoint)
        fn_path = localize_path(tracepoint.path)
        domain_name = domain_from_path(local_path: fn_path)

        mod_class = tracepoint.defined_class
        mod_name = mod_name_from_class(tracepoint.defined_class)
        # self_mod_name = mod_name_from_class(tracepoint.self&.class)

        mod_type = mod_type_from_class(mod_class)

        if ChaosUtils.naught?(mod_name) && (fn_path=="gems/chaos_detector/lib/chaos_detector/utils/str_util.rb")
          puts
          log ("%sMOD%s >>> %s %s, %s:L%d" % [
            ChaosUtils::decorate(domain_name, clamp: :parens),
            ChaosUtils::decorate(mod_name, clamp: :bracket),
            ChaosUtils::decorate(tracepoint.callee_id),
            ChaosUtils::decorate(tracepoint.method_id, prefix: ' / '),
            ChaosUtils::decorate(fn_path, clamp: :none, prefix: ' '),
            tracepoint.lineno,
          ])

          log (
            ChaosUtils::decorate([
              ChaosUtils::decorate(tracepoint.defined_class, clamp: :angle),
              ChaosUtils::decorate(tracepoint.defined_class&.name, clamp: :brace),
              ChaosUtils::decorate(tracepoint.self&.class, clamp: :angle),
              ChaosUtils::decorate(tracepoint.self&.class&.name, clamp: :brace),
              ChaosUtils::decorate(module_stack.first, clamp: :brace),
            ].inspect, clamp: :none, indent_length: 2)
          )
          puts
        end

        ChaosDetector::Stacker::Frame.new(
          callee: tracepoint.callee_id.to_s,
          domain_name: domain_name.to_s,
          fn_path: fn_path.to_s,
          fn_name: tracepoint.method_id.to_s,
          fn_line: tracepoint.lineno,
          mod_name: mod_name.to_s,
          mod_type: mod_type
        )
      end

      def full_path_skip?(path)
        !(@app_root_path && path.start_with?(@app_root_path))
      end

      def module_skip?(mod_name)
        return false unless ChaosUtils.aught?mod_name
        @options.ignore_modules.any? { |m| mod_name.start_with?(m) }
      end

      def apply_options
        @options = options

        @atlas = ChaosDetector::Atlas.new
        @walkman = ChaosDetector::Walkman.new(atlas: @atlas, options: @options)

        ChaosUtils.with(@options.root_label) do |root_label|
          @atlas.graph.root_node.define_singleton_method(:label) { root_label }
        end

        @app_root_path = ChaosUtils.with(@options.app_root_path) {|p| Pathname.new(p)&.to_s}
        @domain_hash = {}
        @options.path_domain_hash && options.path_domain_hash.each do |path, group|
          dpath = Pathname.new(path.to_s).cleanpath.to_s
          @domain_hash[dpath] = group
        end
      end

      def mod_type_from_class(clz)
        case clz
          when Class
            :class
          when Module
            :module
          else
            # log "Unknown mod_type: #{tp&.defined_class&.class}"
            log "Unknown mod_type: #{clz}"
            :nil
        end
      end

      def mod_name_from_class(clz)
        mod_name = clz.name
        mod_name = clz.to_s if !check_name(mod_name)

        undecorate_module_name(mod_name)
      end

      def localize_path(path)
        # @app_root_path.relative_path_from(Pathname.new(path).cleanpath).to_s
        p = Pathname.new(path).cleanpath.to_s
        p.sub!(@app_root_path, '') if @app_root_path
        local_path = p.start_with?('/') ? p[1..-1] : p
        local_path.to_s
      end

      def log(msg)
        ChaosUtils::log_msg(msg, subject: "Navigator")
      end

      def domain_from_path(local_path:)
        key = domain_hash.keys.find{|k| local_path.start_with?(k)}
        key ? domain_hash[key] : DEFAULT_GROUP
      end

      def check_name(mod_nm)
        ChaosUtils.aught?(mod_nm) && !mod_nm.strip.start_with?('#')
      end
  end
end