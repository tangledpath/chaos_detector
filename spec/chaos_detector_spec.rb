require 'chaos_detector/navigator'
require 'chaos_detector/tracker'
require 'chaos_detector/stacker/frame'
require 'chaos_detector/graphing/directed_graphs'
require 'chaos_detector/graphing/graphs'
require 'chaos_detector/options'
require 'chaos_detector/chaos_graphs/chaos_graph'
require 'chaos_detector/chaos_utils'

require 'fixtures/foobar'
require 'fixtures/fubarm'
require 'fixture_external'

describe 'ChaosDetector' do
  let(:chaos_options) do
    ChaosDetector::Options.new.tap do |opts|
      opts.app_root_path = File.expand_path(__dir__)
      opts.log_root_path = File.join('tmp', 'chaos_logs')
      opts.path_domain_hash = { 'fixtures': 'FuDomain' }
    end
  end

  let(:chaos_tracker) { ChaosDetector::Tracker.new(options: chaos_options) }

  let(:simple_tracking) do
    chaos_tracker.record
    Foo.foo
    Fubarm::Foom.foom
    chaos_tracker.stop
  end

  describe 'Navigator' do
    it 'should playback from file' do
      simple_tracking
      playback_nav = ChaosDetector::Navigator.new(options: chaos_options)
      fn_graph, _mod_rel_graph = playback_nav.playback
      expect(fn_graph).to_not be_nil

      # includes root node
      expect(fn_graph.nodes.length).to eq(7)
    end

    it 'uses default domain' do
      chaos_tracker.record
      FixtureExternal.invoke
      chaos_tracker.stop

      playback_nav = ChaosDetector::Navigator.new(options: chaos_options)
      fn_graph, _mod_rel_graph = playback_nav.playback
      expect(fn_graph).to_not be_nil
      puts(["fn_graph", fn_graph].inspect)
    end

  end

  describe 'Utils' do
    it 'should self-test' do
      ChaosDetector::Utils::CoreUtil.test
    end
  end
end
