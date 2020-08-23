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
    TRACE_METHOD_EVENTS = %i[call return].freeze

    attr_reader :options
    attr_reader :walkman

    def initialize(options:)
      raise ArgumentError, '#initialize requires options' if options.nil?

      @options = options
      @total_frames = 0
      @total_traces = 0
      apply_options
    end

    def record
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

        tp_path = tracepoint.path
        next if full_path_skip?(tp_path)

        tp_class = tracepoint.defined_class

        # trace_mod_details(tracepoint)
        mod_info = mod_info_at(tp_class, mod_full_path: tp_path)
        # puts "mod_info: #{mod_info} #{tp_class.respond_to?(:superclass) && tp_class.superclass}"
        next unless mod_info

        fn_info = fn_info_at(tracepoint)
        e = tracepoint.event
        @trace.disable do
          @total_traces += 1
          caller_info = extract_caller(tracepoint, fn_info)
          write_event_frame(e, fn_info: fn_info, mod_info: mod_info, caller_info: caller_info)

          # Detect superclass association:
          ChaosUtils.with(superclass_mod_info(tp_class)) do |super_mod_info|
            # puts "Would superclass #{mod_info} with  #{super_mod_info}"
            write_event_frame(:superclass, fn_info: fn_info, mod_info: mod_info, caller_info: super_mod_info)
          end

          # Detect associations:
          # puts "UGGGGG: #{tp_class.singleton_class.included_modules}"
          ancestor_mod_infos(tp_class, tp_class.included_modules).each do |agg_mod_info|
            # puts "Would ancestors with #{agg_mod_info}"
            write_event_frame(:association, fn_info: fn_info, mod_info: mod_info, caller_info: agg_mod_info)
          end

          # DerivedFracker.singleton_class.included_modules # MixinCD, Kernel
          ancestor_mod_infos(tp_class, tp_class.singleton_class.included_modules).each do |agg_mod_info|
            # puts "WOULD CLASS ancestors with #{agg_mod_info}"
            write_event_frame(:class_association, fn_info: fn_info, mod_info: mod_info, caller_info: agg_mod_info)
          end

          # Detect class associations:
          # ancestor_mod_infos(tp_class).each do |agg_mod_info|
          #   puts "Would ancestors with #{agg_mod_info}"
          #   write_event_frame(:association, fn_info: fn_info, mod_info: mod_info, caller_info: super_mod_info)
          # end
        end
      end
      @trace.enable
      true
    end

    def write_event_frame(event, fn_info:, mod_info:, caller_info:)
      ChaosDetector::Stacker::Frame.new(
        event: event,
        mod_info: mod_info,
        fn_info: fn_info,
        caller_info: caller_info
      ).tap do |frame|
        @walkman.write_frame(frame)
        @total_frames += 1
      end
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
        caps.delete('Class:')
        caps.compact!
        plain_name = caps.first
        plain_name&.chomp!(':')
      end

      plain_name || mod_name
    end

  private

    def apply_options
      @walkman = ChaosDetector::Walkman.new(options: @options)
      @app_root_path = ChaosUtils.with(@options.app_root_path) { |p| Pathname.new(p)&.to_s}
    end

    def extract_caller(tracepoint, fn_info)
      callers = tracepoint.self.send(:caller_locations)
      callers = callers.select do |bt|
        !full_path_skip?(bt.absolute_path) &&
          ChaosUtils.aught?(bt.base_label) &&
          !bt.base_label.start_with?('<')
      end

      frame_at = callers.index { |bt| bt.base_label == fn_info.fn_name && localize_path(bt.absolute_path) == fn_info.fn_path }
      bt_caller = frame_at.nil? ? nil : callers[frame_at + 1]
      ChaosUtils.with(bt_caller) do |bt|
        ChaosDetector::Stacker::FnInfo.new(
          fn_name: bt.base_label,
          fn_line: bt.lineno,
          fn_path: localize_path(bt.absolute_path)
        )
      end
    end

    def superclass_mod_info(clz)
      return nil unless clz&.respond_to?(:superclass)

      sup_clz = clz.superclass

      # puts "BOOOO::: #{clz.superclass} <> #{sup_clz} ~> ChaosUtils.aught?(sup_clz)"
      return nil unless ChaosUtils.aught?(sup_clz)

      # puts "DDDDDDDDDDD::: #{sup_clz&.name}"

      mod_info_at(sup_clz)
    end

    def ancestor_mod_infos(clz, clz_modules)
      sup_clz = clz.superclass rescue nil

      ancestors = clz_modules.filter_map do |c|
        if c != clz && (sup_clz.nil? || c != sup_clz)
          mod_info_at(c)
        end
      end

      ancestors.compact
    end

    def mod_info_at(mod_class, mod_full_path: nil)
      return nil unless mod_class

      mod_name = mod_name_from_class(mod_class)
      if ChaosUtils.aught?(mod_name)
        mod_type = mod_type_from_class(mod_class)
        mod_fp = ChaosUtils.aught?(mod_full_path) ? mod_full_path : nil
        mod_fp ||= mod_class.const_source_location(mod_name)&.first
        safe_mod_info(mod_name, mod_type, mod_fp)
      end
    end

    def fn_info_at(tracepoint)
      ChaosDetector::Stacker::FnInfo.new(fn_name: tracepoint.callee_id.to_s, fn_line: tracepoint.lineno, fn_path: localize_path(tracepoint.path))
    end

    # TODO: MAKE more LIKE module_skip below:
    def full_path_skip?(path)
      return true unless ChaosUtils.aught?(path)

      if !(@app_root_path && path.start_with?(@app_root_path))
        true
      else
        rel_path = localize_path(path)
        @options.ignore_paths.any? { |p| rel_path.start_with?(p)}
        # false
      end
    end

    def module_skip?(mod_name)
      ChaosUtils.with(mod_name) do |mod|
        @options.ignore_modules.any? { |m| mod.start_with?(m)}
      end
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
      mod_name = clz.to_s unless check_name(mod_name)

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
      ChaosUtils.log_msg(msg, subject: 'Tracker', **opts)
    end

    def trace_mod_details(tp, label: 'ModDetails')
      log format('Tracepoint [%s] (%s): %s / %s [%s / %s]', label, tp.event, tp.defined_class, tp.self.class, tp.defined_class&.name, tp.self.class&.name)
    end

    def check_name(mod_nm)
      ChaosUtils.aught?(mod_nm) && !mod_nm.strip.start_with?('#')
    end

    def safe_mod_info(mod_name, mod_type, mod_full_path)
      return nil if full_path_skip?(mod_full_path)
      return nil if module_skip?(mod_name)
      # puts ['mod_full_path', mod_full_path].inspect

      ChaosDetector::Stacker::ModInfo.new(
        mod_name: mod_name,
        mod_path: localize_path(mod_full_path),
        mod_type: mod_type
      )
    end
  end
end
