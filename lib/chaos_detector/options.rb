require 'chaos_detector/chaos_utils'

module ChaosDetector
  class Options
    extend ChaosDetector::Utils::CoreUtil::ChaosAttr

    # TODO: Ability to run on self:
    IGNORE_MODULES = %w[
      ChaosDetector
      ChaosUtils
      RSpec
      FactoryBot
    ].freeze

    IGNORE_PATHS = [

    ]

    # chaos_attr (:options) { ChaosDetector::Options.new }
    chaos_attr(:app_root_path, Dir.getwd)
    chaos_attr(:log_root_path, 'logs')
    chaos_attr(:graph_render_folder, 'render')
    chaos_attr(:path_domain_hash)
    chaos_attr(:ignore_modules, IGNORE_MODULES.dup)
    chaos_attr(:ignore_paths, IGNORE_PATHS.dup)
    chaos_attr(:module_filter, 'todo')
    chaos_attr(:root_label, 'App Container')
    chaos_attr(:frame_csv_path, 'csv/chaos_frames.csv')
    chaos_attr(:walkman_buffer_length, 1000)

    def path_with_root(key:nil, path:nil)
      raise ArgumentError, "key: OR path: must be set" if key.nil? && path.nil?

      subpath = key ? send(key.to_sym) : path.to_s
      File.join(app_root_path, subpath)
    end
  end
end
