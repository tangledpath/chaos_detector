require 'chaos_detector/utils'
module ChaosDetector
class Options
  extend ChaosDetector::Utils::ChaosAttr

  # chaos_attr (:options) { ChaosDetector::Options.new }
  chaos_attr(:log_root_path, ".")
  chaos_attr(:atlas_log_path, "atlas_status.csv")
end
end