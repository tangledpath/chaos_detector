require 'rspec'
require 'rspec/autorun'

def tmp_dir
  File.join(__dir__, 'tmp')
end

def whack_temp_files
  puts "Cleaning temporary files from #{tmp_dir}..."
  puts `rm -rfv #{tmp_dir}`
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
