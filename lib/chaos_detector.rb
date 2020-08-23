require 'chaos_detector/navigator'
require 'chaos_detector/grapher'
require 'chaos_detector/options'

# module ChaosDetector
#   # class << self
#   #   # Add struct or class to encapsulate include/exclude rules:
#   #   #   include_paths:, exclude_paths:, include_classes:, exclude_classes:
#   #   def record(options=nil)#, include_paths:, exclude_paths:, include_classes:, exclude_classes:)


#   #     # puts("  Domains #{domain_hash.inspect}")
#   #     # # options.log_root_path = app_root_path
#   #     # puts("  log_root_path #{options.log_root_path}")
#   #     ChaosDetector::Navigator.record(options: options || ChaosDetector::Options.new)
#   #   end

#   #   def stop
#   #     ChaosDetector::Navigator.stop
#   #   end

#   #   def build_graphs
#   #     raise "Atlas isn't present!  Call record first." if ChaosDetector::Navigator.atlas.nil?

#   #     grapher = ChaosDetector::Graphing::Grapher.new(ChaosDetector::Navigator.atlas)
#   #     grapher.build_graphs()
#   #   end
#   # end
# end
