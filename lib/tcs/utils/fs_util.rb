require 'fileutils'
require 'tcs/utils/util'

module TCS::Utils::FSUtil
  class << self
    # Ensure directory and all its parents exist, like (mkdir -p):
    def ensure_dirpath(dirpath)
      raise ArgumentError, "#ensure_paths_to_file requires dirpath" if Kernel.naught?dirpath
      FileUtils.mkdir_p(dirpath)
    end

    # Ensure file's directory and all its parents exist, like (mkdir -p):
    def ensure_paths_to_file(filepath)
      raise ArgumentError, "#ensure_paths_to_file requires filepath" if Kernel.naught?filepath

      dirpath = File.split(filepath).first
      raise "dirpath couldn't be obtained from #{filepath}" if Kernel.naught?dirpath

      ensure_dirpath(dirpath)
    end
  end
end