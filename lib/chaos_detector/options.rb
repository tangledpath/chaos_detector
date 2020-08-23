require 'chaos_detector/utils'
class ChaosDetector::Options
  extend ChaosDetector::Utils::ChaosAttr

  # chaos_attr (:options) { ChaosDetector::Options.new }
  chaos_attr(:app_root_path, Dir.getwd)
  chaos_attr(:log_root_path, Dir.getwd)
  chaos_attr(:path_domain_hash)
  chaos_attr(:atlas_log_path, "atlas_status.csv")
  chaos_attr(:module_filter, "todo")
  chaos_attr(:root_label, "App Container")
  chaos_attr(:frame_csv_path, "chaos_frames.csv")
  chaos_attr(:walkman_buffer_length, 1000)

  def path_with_root(subpath)
    File.join(self.app_root_path, self.send(subpath))
  end
end
