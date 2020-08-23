require 'set'
require 'chaos_detector/graph'
require 'chaos_detector/stack_frame'
require 'chaos_detector/utils'

module ChaosDetector
class Navigator
  DEFAULT_GROUP="default"
  class << self
    attr_reader :app_root_path
    attr_reader :domain_hash
    attr_reader :module_module_hash
    attr_reader :fn_fn_hash
    attr_reader :module_counter

    def record(app_root_path:, domain_hash: nil)
      @module_counter = Hash.new(0)
      @app_root_path = Pathname.new(app_root_path)
      @domain_hash = {}
      domain_hash && domain_hash.each do |path, group|
        @domain_hash[Pathname.new(path).cleanpath.to_s] = group
      end

      graph = ChaosDetector::Graph.new

      trace = TracePoint.new(:call, :return) do |tp|
        next unless app_root_path && tp.path.starts_with?(app_root_path.to_s)

        mod_path = localize_path(path: tp.path)
        mod_name, mod_type = get_module(tp:tp)
        next if mod_name.starts_with?('ChaosDetector')

        @module_counter[mod_name] +=1

        # caller = tp.binding.eval("caller_locations(4, 1).first.label")
        #caller = caller_locations().join(" -> ")
        # callers = caller_locations(1, 4)
        # callers = tp.binding.eval("eval('caller_locations')")

        domain_name = domain_from_path(local_path: mod_path)

        # puts "XXXXX ([%s]) [%s] :: [%s] ccc {%s}" % [group, mod_name, tp.method_id, tp.callee_id]
        if tp.method_id != tp.callee_id
          puts "XXXXX {%s} (%s)[%s] :: [%s] <> {%s}" % [domain_name, mod_type, mod_name, tp.method_id, tp.callee_id]
        end

        frame = StackFrame.new(mod_type:mod_type, mod_name: mod_name, domain_name: domain_name, path: mod_path, fn_name: tp.method_id, line_num: tp.lineno)
        if tp.event == :call
          graph.open_frame(frame: frame)
        elsif tp.event == :return
          graph.close_frame(frame: frame)
        end
      end

      trace.enable
    end

    def report_module_counter

      mods = @module_counter.sort_by {|k, v| -v}

      total_mods = 0

      msg = []

      mods.each do |k,v|
        msg << "#{k}: #{v} items"
        total_mods += v
      end

      msg<<"Encountered #{@module_counter.length} unique modules."
      msg<<"Encountered #{@total_mods} total modules."
      p(msg.join)
    end


    def extract_module(tp:)
      mod_name = tp.defined_class.name

      if ChaosDetector::Utils.naught?(mod_name)
        mod_name = undecorate_module_name(tp.defined_class.to_s)
      end
    end

    REGEX_MODULE_UNDECORATE = /#<(Class:)?([a-zA-Z\:]*)(.*)>/

    # Undecorate all this junk:
    # a="#<Class:Authentication>"
    # b="#<Class:Person(id: integer, first"
    # c="#<ChaosDetector::Node:0x00007fdd5d2c6b08>"
#     exp3 = /#<(Class:)?([a-zA-Z\:]*)(.*)>/
# mods = [dec1,dec2,dec3].map{|m| {m => m&.match(exp3)&.captures}}
# mods.each {|m| p(m)}

    def undecorate_module_name(mod_name)
      # puts "MOD!!!!!!!!! #{mod_name}"
      return '' if ChaosDetector::Utils.naught?(mod_name)
      # return mod_name unless mod_name.start_with?('#')

      plain_name = nil
      caps = mod_name.match(REGEX_MODULE_UNDECORATE)&.captures
      puts "CAP #{mod_name}: #{caps}"
      if caps && caps.length > 0
        # {"#<Class:Authentication>"=>["Class:", "Authentication", ""]}
        # {"#<Class:Person(id: integer)>"=>["Class:", "Person", "(id: integer)"]}
        # {"#<ChaosDetector::Node:0x00007fdd5d2c6b08>"=>[nil, "ChaosDetector::Node:", "0x00007fdd5d2c6b08"]}
        caps.delete("Class:")
        caps.compact!
        plain_name = caps.first
        plain_name&.chomp!(':')
      end

      puts "!!!!!!!!!!!!!!!!!!!! #{mod_name} -> #{plain_name}" unless ChaosDetector::Utils.naught?(plain_name)
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
      p.starts_with?('/') ? p[1..-1] : p
    end

    def domain_from_path(local_path:)
      # puts "Looking for #{local_path} in [#{domain_hash.keys.join(',')}]"
      key = domain_hash.keys.find{|k| local_path.starts_with?(k)}
      key ? domain_hash[key] : DEFAULT_GROUP
      # p=@app_root_path.relative_path_from(path)

      # p = path.lstrip(app_root_path)
      # @app_root_path.relative_path_from(path)
      # domain_hash.fetch(local_path, DEFAULT_GROUP)
    end
  end
end
end