require 'chaos_detector/utils'
class ChaosDetector::Options
  extend ChaosDetector::Utils::ChaosAttr

  # chaos_attr (:options) { ChaosDetector::Options.new }
  chaos_attr(:log_root_path, ".")
  chaos_attr(:atlas_log_path, "atlas_status.csv")
  chaos_attr(:path_domain_hash)
  chaos_attr(:app_root_path)
  chaos_attr(:root_label, "App Container")
  chaos_attr(:frame_csv_path, "chaos_frames.csv")
end
