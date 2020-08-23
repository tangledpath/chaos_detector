require 'set'
require 'chaos_detector/atlas'
require 'chaos_detector/options'
require 'chaos_detector/stack_frame'
require 'chaos_detector/utils'

class ChaosDetector::Navigator
  REGEX_MODULE_UNDECORATE = /#<(Class:)?([a-zA-Z\:]*)(.*)>/.freeze
  DEFAULT_GROUP="default".freeze
  FRAME_ACTIONS = [:call, :return]

  class << self
    extend ChaosDetector::Utils::ChaosAttr
    chaos_attr (:options) { ChaosDetector::Options.new }
    attr_reader :app_root_path
    attr_reader :domain_hash
    attr_reader :module_module_hash
    attr_reader :fn_fn_hash
    attr_reader :atlas

    def full_path_skip?(path)
      !(@app_root_path && path.start_with?(@app_root_path))
    end

    def prepare_options
      Kernel.with(@options.root_label) do |root_label|
        @atlas.root_node.define_singleton_method(:label) { root_label }
      end

      @app_root_path = ChaosDetector::Utils.with(@options.app_root_path) {|p| Pathname.new(p)&.to_s}
      @domain_hash = {}
      @options.path_domain_hash && options.path_domain_hash.each do |path, group|
        dpath = Pathname.new(path.to_s).cleanpath.to_s
        @domain_hash[dpath] = group
      end

    end

    def record(options: nil)
      @options = options if options

      @atlas = ChaosDetector::Atlas.new(options: @options)
      prepare_options
      puts("Detecting chaos at #{@app_root_path}")

      # setup_domain_hash(@options.path_domain_hash)

      @trace = TracePoint.new(*FRAME_ACTIONS) do |tracepoint|
        next if full_path_skip?(tracepoint.path)
        frame = frame_at_trace(tracepoint)

        next unless frame.mod_name && !frame.mod_name&.start_with?("ChaosDetector")
        # puts "FRame: #{frame}"

        # perform_frame_action(frame, action: tracepoint.event)
        tracepoint.disable do
          perform_frame_action(frame, action: tracepoint.event)
        end
      end

      @trace.enable
    end

    def perform_frame_action(frame, action:)
      if action == :call
        @atlas.open_frame(frame: frame)
      elsif action == :return
        @atlas.close_frame(frame: frame)
      else
        raise ArgumentError("Action should be one of: #{FRAME_ACTIONS.inspect}.  Actual value: #{action.inspect}")
      end
    end

    def frame_at_trace(tracepoint)
      fn_name = tracepoint.method_id
      mod_info = module_from_tracepoint(tracepoint)
      # puts("MOD_INFO: #{mod_info}")
      domain_name = domain_from_path(local_path: mod_info.mod_path)
      line_num = tracepoint.lineno

      # frame.note = "class: #{tracepoint.defined_class} / #{tracepoint.defined_class&.name} / #{mod_name}"
      ChaosDetector::StackFrame.new(
        mod_info: mod_info,
        domain_name: domain_name,
        fn_name: fn_name,
        line_num: line_num)
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

    def check_name(mod_nm)
      !(ChaosDetector::Utils.naught?(mod_nm) || mod_nm.start_with?('#'))
    end

    def module_from_tracepoint(tp)
      # if check_name?tp.defined_class.name
      # elsif if check_name?tp.defined_class.name

      clz = tp.defined_class #&.class #
      mod_name = clz.name
      # mod_name = tp.self.to_s if !check_name(mod_name) && check_name(tp.self.to_s)
      mod_name = clz.to_s if !check_name(mod_name)
      mod_name = undecorate_module_name(mod_name)

      mod_type = case clz
        when Class
          :class
        when Module
          :module
        else
          puts "Unknown mod_type: #{tp&.defined_class&.class}"
          :nil
        end

      mod_path = localize_path(tp.path)
      ChaosDetector::ModInfo.new(mod_name, mod_path: mod_path, mod_type: mod_type)
    end

    def stop
      @trace&.disable
      @atlas.stop
    end

    def localize_path(path)
      # @app_root_path.relative_path_from(Pathname.new(path).cleanpath).to_s
      p = Pathname.new(path).cleanpath.to_s
      p.sub!(@app_root_path, '') unless ChaosDetector::Utils.naught?(@app_root_path)
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
