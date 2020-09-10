require 'set'
require 'pathname'
require_relative 'options'
require_relative 'stacker/mod_info'
require_relative 'chaos_graphs/module_node'
require_relative 'stacker/frame'
require_relative 'walkman'
require 'chaos_detector/chaos_utils'

# The main interface for intercepting tracepoints,
# and converting them into recordable and playable
# stack/trace frames

module ChaosDetector
  class Tracker
    REGEX_MODULE_UNDECORATE = /#<(Class:)?([a-zA-Z\:]*)(.*)>/.freeze
    DEFAULT_GROUP = 'default'.freeze
    TRACE_METHOD_EVENTS = %i[call return].freeze

    attr_reader :options
    attr_reader :walkman

    def initialize(options:)
      raise ArgumentError, '#initialize requires options' if options.nil?
      @options = options
      @total_traces = 0
      # ModInfo -> Set(ModInfo)?
      @class_supers = Hash.new([])
      @class_mixins = Hash.new([])
      apply_options
    end

    def publish_association(mod_info, mod_info_assoc, association)
    end

    def publish_super_relation(mod_info, mod_info_super)
    end

    def record()
      log("Detecting chaos at #{@app_root_path}")
      # log(caller_locations.join("\n\t->\t"))
      # log("")
      @stopped = false
      @walkman.record_start
      @total_traces = 0
      @trace = TracePoint.new(*TRACE_METHOD_EVENTS) do |tracepoint|
        if @stopped
          @trace.disable
          log('Tracing stopped; stopping immediately.')
          next
        end

        next if full_path_skip?(tracepoint.path)

        # trace_mod_details(tracepoint)
        mod_info = mod_info_at(tracepoint)
        next if module_skip?(mod_info)
        mod_info_super = mod_info_superclass(tracepoint.defined_class)
        fn_info = fn_info_at(tracepoint)
        e = tracepoint.event
        @trace.disable do
          caller_info = extract_caller(tracepoint, fn_info)
          @total_traces += 1
          frame = ChaosDetector::Stacker::Frame.new(
            event: e,
            mod_info: mod_info,
            fn_info: fn_info,
            caller_info: caller_info
          )
          @walkman.write_frame(frame)
        end

      end
      @trace.enable
      true
    end

    def stop
      @stopped = true
      @trace&.disable
      log("Stopping after total traces: #{@total_traces}")
      @walkman.stop
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

      def extract_caller(tracepoint, fn_info)
        callers = tracepoint.self.send(:caller_locations)
        callers = callers.select do |bt|
          !full_path_skip?(bt.absolute_path) &&
          ChaosUtils.aught?(bt.base_label) &&
          !bt.base_label.start_with?('<')
        end

        cc =  callers.map do |bt|
          "(%s) (%s:%d)" % [
            bt.base_label,
            bt.path,
            bt.lineno
          ]
        end
        # log(fn_info)
        # log(cc.join("\n\t->\t"))
        frame_at = callers.index{|bt| bt.base_label==fn_info.fn_name && localize_path(bt.absolute_path)==fn_info.fn_path }
        bt_caller = frame_at.nil? ? nil : callers[frame_at+1]
        ChaosUtils.with(bt_caller) do |bt|
          ChaosDetector::Stacker::FnInfo.new(
            fn_name: bt.base_label,
            fn_line: bt.lineno,
            fn_path: localize_path(bt.absolute_path)
          )
        end
      end

      def mod_info_superclass(clz)
        return nil unless clz&.respond_to?(:superclass)

        sup_clz = clz.superclass
        if sup_clz
          mod_name = mod_name_from_class(sup_clz)
          mod_type = mod_type_from_class(sup_clz)
          mod_path = localize_path(sup_clz.const_source_location(mod_name)&.last)

          ChaosDetector::Stacker::ModInfo.new(
            mod_name: mod_name,
            mod_path: mod_path,
            mod_type: mod_type
          )
        end
      end

      def mod_info_ancestors(clz)
      end

      # TODO: Also store tracepoint.self.class&.name
      # as "associated module" under the following conditions:
      # * mod_type is 'MODULE' vs. 'CLASS'
      # * not the same as tracepoint.defined_class
      # * valid name
      def mod_info_at(tracepoint)
        mod_info = nil
        mod_class = tracepoint.defined_class
        ancestry = mod_class&.ancestors
        if ancestry.any?
          puts '-' * 50
          puts ancestry.first&.class
          puts ancestry.inspect
          puts ancestry.class&.superclass
          puts '-' * 50
        end

        mod_name = mod_name_from_class(mod_class)
        if mod_name
          mod_type = mod_type_from_class(mod_class)
          mod_path = localize_path(tracepoint.path)
          mod_info = ChaosDetector::Stacker::ModInfo.new(
            mod_name: mod_name,
            mod_path: mod_path,
            mod_type: mod_type
          )
        end
        mod_info
      end

      def fn_info_at(tracepoint)
        ChaosDetector::Stacker::FnInfo.new(fn_name: tracepoint.callee_id.to_s, fn_line: tracepoint.lineno, fn_path: localize_path(tracepoint.path))
      end

      def full_path_skip?(path)
        return true unless ChaosUtils.aught?(path)

        if !(@app_root_path && path.start_with?(@app_root_path))
          true
        elsif path.start_with?("/Users/stevenmiers/src/sci-ex/sciex3/lib/mixins")
          true
        else
          false
        end
      end

      def module_skip?(mod_info)
        ChaosUtils.with(mod_info&.mod_name) do |modname|
          @options.ignore_modules.any? {|m| modname.start_with?(m)}
        end
      end

      def apply_options
        @walkman = ChaosDetector::Walkman.new(options: @options)
        @app_root_path = ChaosUtils.with(@options.app_root_path) {|p| Pathname.new(p)&.to_s}
      end

      def mod_type_from_class(clz)
        case clz
          when Class
            :class
          when Module
            :module
          else
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
        return '' unless ChaosUtils.aught?(path)
        p = Pathname.new(path).cleanpath.to_s
        p.sub!(@app_root_path, '') if @app_root_path
        local_path = p.start_with?('/') ? p[1..-1] : p
        local_path.to_s
      end

      def log(msg, **opts)
        ChaosUtils::log_msg(msg, subject: 'Tracker', **opts)
      end

      def trace_mod_details(tp, label: 'ModDetails')
        log 'Tracepoint [%s] (%s): %s / %s [%s / %s]' % [
          label,
          tp.event,
          tp.defined_class,
          tp.self.class,
          tp.defined_class&.name,
          tp.self.class&.name
        ]
      end

      def check_name(mod_nm)
        ChaosUtils.aught?(mod_nm) && !mod_nm.strip.start_with?('#')
      end
  end
end