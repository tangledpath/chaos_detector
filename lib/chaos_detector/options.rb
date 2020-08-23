require 'tcs/refined_utils'
using TCS::RefinedUtils

module ChaosDetector
  class Options
    extend TCS::Utils::CoreUtil::ChaosAttr

    IGNORE_CHAOS = 'ChaosDetector::'
    IGNORE_RSPEC = 'RSpec::'
    # chaos_attr (:options) { ChaosDetector::Options.new }
    chaos_attr(:app_root_path, Dir.getwd)
    chaos_attr(:log_root_path, "logs")
    chaos_attr(:graph_render_folder, "render")
    chaos_attr(:path_domain_hash)
    chaos_attr(:ignore_modules, [IGNORE_CHAOS, IGNORE_RSPEC])
    chaos_attr(:module_filter, "todo")
    chaos_attr(:root_label, "App Container")
    chaos_attr(:frame_csv_path, "csv/chaos_frames.csv")
    chaos_attr(:walkman_buffer_length, 1000)

    def path_with_root(subpath)
      File.join(self.app_root_path, self.send(subpath))
    end

    def path_with_log_root(subpath)
      logroot = path_with_root(:log_root_path)
      File.join(logroot, self.send(subpath))
    end
  end
end