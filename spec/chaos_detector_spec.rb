require 'chaos_detector/navigator'
require 'chaos_detector/tracker'
require 'chaos_detector/stacker/frame'
require 'chaos_detector/graphing/directed'
require 'chaos_detector/graphing/graphs'
require 'chaos_detector/options'
require 'chaos_detector/chaos_graphs/chaos_graph'
require 'chaos_detector/chaos_utils'

require 'chaos_detector/graph_theory/appraiser'

require 'fixtures/foobar'
require 'fixtures/fubarm'

describe "ChaosDetector" do
  let (:opts) {
    opts = ChaosDetector::Options.new
    opts.app_root_path = __dir__
    opts.log_root_path = File.join('tmp', 'chaos_logs')
    opts.path_domain_hash = { 'fixtures': 'FuDomain' }
    opts
  }

  let (:chaos_tracker) { ChaosDetector::Tracker.new(options: opts) }
  let (:chaos_nav) { ChaosDetector::Navigator.new(options: opts) }

  describe "Tracker" do
    let (:dec1) { "#<Class:Authentication>"}
    let (:dec2) { "#<Class:Person(id: integer)>"}
    let (:dec3) { "#<ChaosDetector::Node:0x00007fdd5d2c6b08>"}
    # a="#<Class:Authentication>"
    # b="#<Class:Person(id: integer, first"
    # c="#<ChaosDetector::Node:0x00007fdd5d2c6b08>"
    it "should undecorate module names" do
      expect(chaos_tracker.undecorate_module_name(dec2)).to eq("Person")
      expect(chaos_tracker.undecorate_module_name(dec1)).to eq("Authentication")
      expect(chaos_tracker.undecorate_module_name(dec3)).to eq("ChaosDetector::Node")
    end

    it "should record" do
      chaos_tracker.record()
      Foo.foo
      Fubarm::Foom.foom
      chaos_tracker.stop
    end

    it "should save recording to walkman" do
      chaos_tracker.record()
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
      csv_lines = csv_content.split
      puts csv_lines.length
      puts '-' * 50
      puts csv_lines
      puts '-' * 50
      expect(csv_lines.length).to eq(13)

    end
  end

  describe "Navigator" do
    it "should playback from file" do
      chaos_tracker.record()
      Foo.foo
      Fubarm::Foom.foom
      chaos_tracker.stop

      playback_nav = ChaosDetector::Navigator.new(options: opts)
      playback_graph = playback_nav.playback()
      expect(playback_graph).to_not be_nil
      expect(playback_graph.nodes.length).to eq(6)
    end
  end

  describe "Grapher" do
    let (:graphing) do
      chaos_tracker.record()
      Foo.foo
      Fubarm::Foom.foom
      chaos_tracker.stop
      chaos_nav.playback
    end

    it "domain graphs" do
      grapher = ChaosDetector::Graphing::Directed.new()
      grapher.create_directed_graph("domain-test")

      chaos_graph = ChaosDetector::ChaosGraphs::ChaosGraph.new(graphing)
      chaos_graph.infer_all
      grapher.append_nodes(chaos_graph.domain_nodes)
      grapher.add_edges(chaos_graph.domain_edges)

      grapher.render_graph
      graph_fs = `ls domain-test.png`
      p(ChaosUtils::decorate(graph_fs))
      expect(graph_fs).to be
      expect(graph_fs.split.first).to eq("domain-test.png")
    end

    it "module graphs" do
      grapher = ChaosDetector::Graphing::Directed.new()
      grapher.create_directed_graph("module-test")

      chaos_graph = ChaosDetector::ChaosGraphs::ChaosGraph.new(graphing)
      chaos_graph.infer_all
      grapher.append_nodes(chaos_graph.module_nodes)

      chaos_graph.module_nodes.each do |n|
        p("ModNode: #{ChaosUtils::decorate(n.label)}")
      end

      chaos_graph.module_edges.each do |e|
        p("ModEdge: #{ChaosUtils::decorate(e.src_node.class)} -> #{ChaosUtils::decorate(e.dep_node.class)}")
      end
      grapher.add_edges(chaos_graph.module_edges)

      grapher.render_graph
      graph_fs = `ls module-test.png`
      p(ChaosUtils::decorate(graph_fs))
      expect(graph_fs).to be
      expect(graph_fs.split.first).to eq("module-test.png")
    end

    it "graphs using graphs" do
      chaos_tracker.record()
      Foo.foo
      Fubarm::Foom.foom
      graph = chaos_tracker.stop
      expect(graph).to_not be_nil

      # Playback should graph:
      graphs = ChaosDetector::Graphing::Graphs.new(options: opts)
      expect(graphs.navigator).to_not be_nil

      graphs.playback()
      expect(graphs.chaos_graph).to_not be_nil

      graphs.render_mod_dep()
      graph_fs = `ls spec/render/module-dep.png`
      p(ChaosUtils::decorate(graph_fs))
      expect(graph_fs).to be
      expect(graph_fs.split.first).to eq("spec/render/module-dep.png")
    end

  end

  describe "Utils" do
    it "should self-test" do
      ChaosDetector::Utils::CoreUtil.test
    end
  end
end
