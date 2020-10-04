require 'fileutils'
require 'pathname'
require_relative 'core_util'

module ChaosDetector
  module Utils
    module FSUtil
      class << self

        # Relative path:
        def rel_path(dir_path, from_path:)
          pathname = Pathname.new(dir_path)
          base_path = Pathname.new(from_path).cleanpath
          pathname.relative_path_from(base_path).to_s
        end

        # Ensure directory and all its parents exist, like (mkdir -p):
        def ensure_dirpath(dirpath)
          raise ArgumentError, '#ensure_paths_to_file requires dirpath' if nay? dirpath

          FileUtils.mkdir_p(dirpath)
        end

        # Ensure file's directory and all its parents exist, like (mkdir -p):
        def ensure_paths_to_file(filepath)
          raise ArgumentError, '#ensure_paths_to_file requires filepath' if nay? filepath

          dirpath = File.split(filepath).first
          raise "dirpath couldn't be obtained from #{filepath}" if nay? dirpath

          ensure_dirpath(dirpath)
        end

        def nay?(obj)
          ChaosDetector::Utils::CoreUtil.naught?(obj)
        end
      end
    end
  end
end
