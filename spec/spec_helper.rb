require 'rspec'
require 'rspec/autorun'

def tmp_dirs
  [
    File.join(__dir__, 'tmp'),
    File.join(__dir__, 'csv'),
    File.join(__dir__, 'render')
  ]
end

def whack_temp_files
  puts "Cleaning temporary files from: #{tmp_dirs.inspect}..."
  puts `rm -rfv #{tmp_dirs.join(" ")}`
end

RSpec.configure do |config|
  config.default_formatter = 'doc'

  config.before(:suite) do
    whack_temp_files
  end

  config.after(:suite) do
    # Leave for debugging
    # whack_temp_files
  end
end
