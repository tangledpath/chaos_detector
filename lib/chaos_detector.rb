require 'graphviz'
require 'chaos_detector/navigator'
require 'chaos_detector/options'

module ChaosDetector
  class << self
    def options
      @options ||= ChaosDetector::Options.new
    end

    # Add struct or class to encapsulate include/exclude rules:
    #   include_paths:, exclude_paths:, include_classes:, exclude_classes:
    def record(app_root_path:, domain_hash:)#, include_paths:, exclude_paths:, include_classes:, exclude_classes:)
      puts("Detecting chaos at #{app_root_path}")
      puts("  Domains #{domain_hash.inspect}")
      options.log_root_path = app_root_path
      puts("  log_root_path #{options.log_root_path}")
      ChaosDetector::Navigator.record(
        app_root_path: app_root_path,
        domain_hash: domain_hash,
        options: options
      )
    end

    def build_graph
      ChaosDetector::Navigator.build_graph
    end
  end
end
