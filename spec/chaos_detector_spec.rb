require 'chaos_detector/atlas'
require 'chaos_detector/navigator'
require 'chaos_detector/stacker/frame'
require 'chaos_detector/grapher'
require 'chaos_detector/options'
require 'tcs/refined_utils'
using TCS::RefinedUtils

require 'graph_theory/appraiser'

require 'fixtures/foobar'
require 'fixtures/fubarm'

describe "ChaosDetector" do
  describe "Navigator" do
    let (:dec1) { "#<Class:Authentication>"}
    let (:dec2) { "#<Class:Person(id: integer)>"}
    let (:dec3) { "#<ChaosDetector::Node:0x00007fdd5d2c6b08>"}
    let (:opts) {
      opts = ChaosDetector::Options.new
      opts.app_root_path = __dir__
      opts.log_root_path = File.join(__dir__, 'tmp', 'chaos_logs')
      opts.path_domain_hash = { 'fixtures': 'FuDomain' }
      opts
    }

    let (:chaos_nav) { ChaosDetector::Navigator.new(options: opts) }

    # a="#<Class:Authentication>"
    # b="#<Class:Person(id: integer, first"
    # c="#<ChaosDetector::Node:0x00007fdd5d2c6b08>"
    it "should undecorate module names" do
      chaos_nav.undecorate_module_name(dec2).should eq("Person")
      chaos_nav.undecorate_module_name(dec1).should eq("Authentication")
      chaos_nav.undecorate_module_name(dec3).should eq("ChaosDetector::Node")
    end

    it "should record and graph" do
      chaos_nav.record()
      Foo.foo
      Fubarm::Foom.foom
      expect(chaos_nav.atlas).to_not be_nil

      atlas = chaos_nav.stop
      puts ("Nodes: #{atlas.node_count}")
      expect(atlas).to eq(chaos_nav.atlas)
      grapher = ChaosDetector::Grapher.new(atlas)
      grapher.build_graphs()

      atlas.graph.edges.each do |edge|
        puts "root edge: #{edge}" if edge.src_node.is_root# =='root'
      end
    end

    it "should graph theorize" do
      chaos_nav.record()
      Foo.foo
      Fubarm::Foom.foom
      atlas = chaos_nav.stop

      graph_metrics = GraphTheory::Appraiser.new(atlas.graph)
      graph_metrics.appraise
    end

    it "should save recording to walkman" do
      chaos_nav.record()
      Foo.foo
      Fubarm::Foom.foom
      _atlas = chaos_nav.stop

      expect(chaos_nav.walkman).to_not be_nil
      walkman = chaos_nav.walkman
      expect(walkman).to_not be_nil
      expect(walkman.csv_path).to_not be_nil
      expect(walkman.csv_path).to_not be_empty
      csv_content = `cat #{walkman.csv_path}`
      expect(csv_content).to_not be_nil
      expect(csv_content).to_not be_empty
      csv_lines = csv_content.split
      csv_lines = csv_content.split
      puts csv_lines.length
      puts '-' * 50
      puts csv_lines
      puts '-' * 50
      expect(csv_lines.length).to eq(13)

    end

    it "should playback from file" do
      chaos_nav.record()
      Foo.foo
      Fubarm::Foom.foom
      recorded_atlas = chaos_nav.stop
      expect(recorded_atlas).to_not be_nil

      playback_nav = ChaosDetector::Navigator.new(options: opts)
      playback_atlas = playback_nav.playback()
      expect(playback_atlas).to_not be_nil

      # Playback should graph:
      grapher = ChaosDetector::Grapher.new(playback_atlas)
      grapher.build_graphs()
    end
  end

  describe "Atlas" do
    it "should do basic frame stacking" do
      atlas = ChaosDetector::Atlas.new
      frame1 = ChaosDetector::Stacker::Frame.new(mod_type: :class, mod_name: 'Bam', domain_name: 'bar', fn_path: 'foo/bar', fn_name: 'baz', line_num: 2112)
      frame2 = ChaosDetector::Stacker::Frame.new(mod_type: :module, mod_name: 'Gork', domain_name: 'MEP', fn_path: 'foo/mepper', fn_name: 'blop', line_num: 3112)

      expect(atlas.stack_depth).to eq(0)

      atlas.open_frame(frame1)
      expect(atlas.stack_depth).to eq(1)

      atlas.open_frame(frame2)
      expect(atlas.stack_depth).to eq(2)

      atlas.close_frame(frame2)
      expect(atlas.stack_depth).to eq(1)

      atlas.close_frame(frame1)
      expect(atlas.stack_depth).to eq(0)

    end
  end

  describe "Utils" do
    it "should self-test" do
      TCS::Utils::CoreUtil.test
    end
  end
end
