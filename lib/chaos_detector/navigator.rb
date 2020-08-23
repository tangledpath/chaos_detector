require 'pathname'
require_relative 'atlas'
require_relative 'options'
require_relative 'chaos_graphs/module_node'
require_relative 'stacker/frame'
require_relative 'walkman'
require 'tcs/refined_utils'
using TCS::RefinedUtils

# The main interface for intercepting tracepoints,
# and converting them into recordable and playable
# stack/trace frames

class ChaosDetector::Navigator
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

  def initialize(options:)
    raise ArgumentError, "#initialize requires options" if options.nil?
    @options = options
    @stopped = false
    apply_options
  end

  ### Playback of walkman CSV file:
  def playback()
    log("Detecting chaos in playback via walkman")
    @walkman.playback do |action, frame|
      log("Performing :#{action} on frame: #{frame}")
      frame_act = case action.to_sym
        when :open
          :call
        when :close, :pop
          :return
      end
      perform_frame_action(frame, action: frame_act, record: false)
    end
    @atlas
  end

  def record()
    log("Detecting chaos at #{@app_root_path}")

    @walkman.record_start
    @total_traces = 0
    @trace = TracePoint.new(*FRAME_ACTIONS) do |tracepoint|
      if @stopped
        @trace.disable
        log("Tracing stoped; stopping immediately.")
        next
      end

      if [:class, :end].include?tracepoint.event
        # puts tracepoint.inspect
        # FUN: TODO.
        next
      end

      next if full_path_skip?(tracepoint.path)
      tracepoint.disable do
        @total_traces += 1
        frame = frame_at_trace(tracepoint)

        # Generic module exclusion:
        if module_skip?(frame.mod_name)
          puts "Skipping module #{frame.mod_name}"
          break
        end

        # DISABLE MORE OF ABOVE?
        perform_frame_action(frame, action: tracepoint.event, record: true)
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
  def undecorate_module_name(mod_name)
    return '' if TCS::Utils::CoreUtil.naught?(mod_name)
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

    # puts "!!!!!!!!!!!!!!!!!!!! #{mod_name} -> #{plain_name}" unless TCS::Utils::CoreUtil.naught?(plain_name)
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
        puts "Offset is #{offset} closing frame #{frame}"
        @walkman.write_frame(frame, action: frame_act, frame_offset: offset) if record
      else
        raise ArgumentError, "Action should be one of: #{FRAME_ACTIONS.inspect}.  Actual value: #{action.inspect}"
      end
    end

    def frame_at_trace(tracepoint)
      mod_class = tracepoint.defined_class
      mod_name = mod_name_from_class(mod_class)
      mod_type = mod_type_from_class(mod_class)
      fn_path = localize_path(tracepoint.path)
      domain_name = domain_from_path(local_path: fn_path)

      ChaosDetector::Stacker::Frame.new(
        callee: tracepoint.callee_id,
        domain_name: domain_name,
        fn_path: fn_path,
        fn_name: tracepoint.method_id,
        line_num: tracepoint.lineno,
        mod_name: mod_name,
        mod_type: mod_type
      )
    end

    def full_path_skip?(path)
      !(@app_root_path && path.start_with?(@app_root_path))
    end

    def module_skip?(mod_name)
      Kernel.naught?(mod_name) || @options.ignore_modules.any? { |m| mod_name.include?(m) }
    end

    def apply_options
      @options = options

      @atlas = ChaosDetector::Atlas.new
      @walkman = ChaosDetector::Walkman.new(atlas: @atlas, options: @options)

      Kernel.with(@options.root_label) do |root_label|
        @atlas.graph.root_node.define_singleton_method(:label) { root_label }
      end

      @app_root_path = TCS::Utils::CoreUtil.with(@options.app_root_path) {|p| Pathname.new(p)&.to_s}
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
          log "Unknown mod_type: #{tp&.defined_class&.class}"
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
      p.start_with?('/') ? p[1..-1] : p
    end

    def log(msg)
      log_msg(msg, subject: "Navigator")
    end

    def domain_from_path(local_path:)
      key = domain_hash.keys.find{|k| local_path.start_with?(k)}
      key ? domain_hash[key] : DEFAULT_GROUP
    end

    def check_name(mod_nm)
      Kernel.aught?(mod_nm) && !mod_nm.strip.start_with?('#')
    end
end
