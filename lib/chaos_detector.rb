require 'graphviz'
require 'chaos_detector/navigator'

module ChaosDetector
  # Add struct or class to encapsulate include/exclude rules:
  #   include_paths:, exclude_paths:, include_classes:, exclude_classes:
  def self.record(app_root_path:, domain_hash:)#, include_paths:, exclude_paths:, include_classes:, exclude_classes:)
    puts("Detecting chaos at #{app_root_path}")
    puts("  Domains #{domain_hash.inspect}")
    ChaosDetector::Navigator.record(
      app_root_path: app_root_path,
      domain_hash: domain_hash
    )
  end
end
