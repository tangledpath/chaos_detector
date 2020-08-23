module ChaosDetector
  class Node
    attr_reader :mod_name
    attr_reader :mod_path
    attr_reader :domain_name

    def initialize(mod_name:, mod_path:, domain_name:nil)
      super()
      @mod_name = mod_name
      @mod_path = mod_path
      @domain_name = domain_name
    end

    def ==(other)
      self.domain_name == other.domain_name &&
      self.mod_name == other.mod_name &&
      self.mod_path == other.mod_path
    end

    def to_s(scope=nil)
      self.class.human_key(mod_path: @mod_path, mod_name: @mod_name, domain_name: @domain_name)
    end

    def label
      m = @mod_name.split("::").last(2).join("::")
      "#{m}\n#{@domain_name}"
    end

    def self.human_key(mod_path:nil, mod_name:nil, domain_name:nil)
      hkey = "["
      hkey << "(#{domain_name}) " unless domain_name.nil? || domain_name.empty?
      hkey << mod_name unless mod_name.nil? || mod_name.empty?
      hkey << " '#{mod_path}'" unless mod_path.nil? || mod_path.empty?
      hkey << "]"
    end
  end
end