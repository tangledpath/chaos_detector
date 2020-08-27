require 'rspec'
require 'rspec/autorun'

def tmp_dirs
  spec_dir = File.expand_path(__dir__)
  [
    File.join(spec_dir, 'tmp'),
    File.join(spec_dir, 'csv'),
    File.join(spec_dir, 'render')
  ]
end

def whack_temp_files
  puts "Cleaning temporary files from: #{tmp_dirs.inspect}..."
  puts `rm -rfv #{tmp_dirs.join(' ')}`
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
