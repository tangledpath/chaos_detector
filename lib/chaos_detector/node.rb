module ChaosDetector
  class Node
    attr_reader :mod_name
    attr_reader :path
    attr_reader :domain_name

    def initialize(mod_name:, path:, domain_name:nil)
      super()
      @mod_name = mod_name
      @path = path
      @domain_name = domain_name
    end

    def ==(other)
      self.domain_name == other.domain_name &&
      self.mod_name == other.mod_name &&
      self.path == other.path
    end

    def to_s(scope=nil)
      self.class.human_key(path: @path, mod_name: @mod_name, domain_name: @domain_name)
    end

    def label
      m = @mod_name.split("::").last(2).join("::")
      "#{m}\n#{@domain_name}"
    end

    def self.human_key(path:nil, mod_name:nil, domain_name:nil)
      hkey = "["
      hkey << "(#{domain_name}) " unless domain_name.nil? || domain_name.empty?
      hkey << mod_name unless mod_name.nil? || mod_name.empty?
      hkey << " '#{path}'" unless path.nil? || path.empty?
      hkey << "]"
    end
  end
end