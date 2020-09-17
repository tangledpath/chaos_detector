require 'chaos_detector/tracker'
require 'chaos_detector/options'
require 'chaos_detector/chaos_utils'

require 'fixtures/foobar'
require 'fixtures/fubarm'
require 'fixtures/fixture_mixed_in'
require 'fixtures/fixture_relations'

describe 'Tracker' do
  let(:chaos_options) do
    ChaosDetector::Options.new.tap do |opts|
      opts.app_root_path = File.expand_path(__dir__)
      opts.log_root_path = File.join('tmp', 'chaos_logs')
      opts.path_domain_hash = { 'fixtures': 'FuDomain' }
      opts.frame_csv_path = 'csv/chaos_tracking.csv'
    end
  end

  let(:chaos_tracker) { ChaosDetector::Tracker.new(options: chaos_options) }
  let(:chaos_walkman) { ChaosDetector::Walkman.new(options: chaos_options) }
  # let(:tracked_csv_path) { @options.path_with_log_root(:frame_csv_path) }

  describe 'internal' do
    let(:dec1) { '#<Class:Authentication>'}
    let(:dec2) { '#<Class:Person(id: integer)>'}
    let(:dec3) { '#<ChaosDetector::Node:0x00007fdd5d2c6b08>'}
    # a='#<Class:Authentication>'
    # b='#<Class:Person(id: integer, first'
    # c='#<ChaosDetector::Node:0x00007fdd5d2c6b08>'
    it 'should undecorate module names' do
      expect(chaos_tracker.undecorate_module_name(dec2)).to eq('Person')
      expect(chaos_tracker.undecorate_module_name(dec1)).to eq('Authentication')
      expect(chaos_tracker.undecorate_module_name(dec3)).to eq('ChaosDetector::Node')
    end
  end

  describe 'basic' do
    it 'should record' do
      chaos_tracker.record
      Fubarm::Foom.foom
      Foo.foo
      chaos_tracker.stop
    end
  end

  describe 'integrates with walkman' do
    it 'should persist' do
      chaos_tracker.record
      Foo.foo
      Fubarm::Foom.foom
      chaos_tracker.stop

      expect(chaos_tracker.walkman).to_not be_nil
      walkman = chaos_tracker.walkman
      expect(walkman).to_not be_nil
      expect(walkman.csv_path).to_not be_nil
      expect(walkman.csv_path).to_not be_empty
      csv_content = `cat #{walkman.csv_path}`
      expect(csv_content).to_not be_nil
      expect(csv_content).to_not be_empty
      csv_lines = csv_content.split
      expect(csv_lines.length).to eq(13)
    end
  end

  describe 'Metaprogramming' do
    describe 'mixins' do
      it 'should record mixed-in module' do
        chaos_tracker.record
        mixed = FixtureMixedIn.new
        mixed.mixed_foo(2112)
        chaos_tracker.stop
        foo_frame = chaos_walkman.frame_at(row_index: 0)

        expect(foo_frame).to_not be_nil
        expect(foo_frame.mod_info).to_not be_nil
        expect(foo_frame.fn_info).to_not be_nil

        expect(foo_frame.fn_info.fn_name).to eq('mixed_foo')
        expect(foo_frame.fn_info.fn_path).to eq('fixtures/fixture_mixed_in.rb')
        expect(foo_frame.mod_info.mod_name).to eq('FixtureModule')
        expect(foo_frame.mod_info.mod_path).to eq('fixtures/fixture_mixed_in.rb')
        expect(foo_frame.mod_info.mod_type).to eq('module')
      end
    end
  end
end
