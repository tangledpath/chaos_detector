require 'chaos_detector/atlas'
require 'chaos_detector/navigator'
require 'chaos_detector/stacker/frame'
require 'chaos_detector/graphing/directed'
require 'chaos_detector/graphing/graphs'
require 'chaos_detector/options'
require 'chaos_detector/chaos_graphs/chaos_graph'
require 'tcs/refined_utils'
using TCS::RefinedUtils

require 'graph_theory/appraiser'

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

  let (:chaos_nav) { ChaosDetector::Navigator.new(options: opts) }

  describe "Navigator" do
    let (:dec1) { "#<Class:Authentication>"}
    let (:dec2) { "#<Class:Person(id: integer)>"}
    let (:dec3) { "#<ChaosDetector::Node:0x00007fdd5d2c6b08>"}
    # a="#<Class:Authentication>"
    # b="#<Class:Person(id: integer, first"
    # c="#<ChaosDetector::Node:0x00007fdd5d2c6b08>"
    it "should undecorate module names" do
      expect(chaos_nav.undecorate_module_name(dec2)).to eq("Person")
      expect(chaos_nav.undecorate_module_name(dec1)).to eq("Authentication")
      expect(chaos_nav.undecorate_module_name(dec3)).to eq("ChaosDetector::Node")
    end

    it "should record" do
      chaos_nav.record()
      Foo.foo
      Fubarm::Foom.foom
      expect(chaos_nav.atlas).to_not be_nil

      atlas = chaos_nav.stop
      puts ("Nodes: #{atlas.node_count}")
      expect(atlas.node_count).to eq(6)

      expect(atlas).to eq(chaos_nav.atlas)
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
      grapher = ChaosDetector::Graphing::Directed.new()
      # grapher.build_graphs()
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

  describe "Grapher" do
    let (:atlas) do
      chaos_nav.record()
      Foo.foo
      Fubarm::Foom.foom
      chaos_nav.stop
    end

    it "domain graphs" do
      grapher = ChaosDetector::Graphing::Directed.new()
      grapher.create_directed_graph("domain-test")

      chaos_graph = ChaosDetector::ChaosGraphs::ChaosGraph.new(atlas.graph)
      chaos_graph.infer_all
      grapher.append_nodes(chaos_graph.domain_nodes)
      grapher.add_edges(chaos_graph.domain_edges)

      # grapher.add_nodes(atlas.nodes)
      # grapher.add_nodes(atlas.nodes)
      grapher.render_graph
      graph_fs = `ls domain-test.png`
      p(decorate(graph_fs))
      expect(graph_fs).to be
      expect(graph_fs.split.first).to eq("domain-test.png")
    end

    it "module graphs" do
      grapher = ChaosDetector::Graphing::Directed.new()
      grapher.create_directed_graph("module-test")

      chaos_graph = ChaosDetector::ChaosGraphs::ChaosGraph.new(atlas.graph)
      chaos_graph.infer_all
      grapher.append_nodes(chaos_graph.module_nodes)

      chaos_graph.module_nodes.each do |n|
        p("ModNode: #{decorate(n.label)}")
      end

      chaos_graph.module_edges.each do |e|
        p("ModEdge: #{decorate(e.src_node.class)} -> #{decorate(e.dep_node.class)}")
      end
      grapher.add_edges(chaos_graph.module_edges)

      # grapher.add_nodes(atlas.nodes)
      # grapher.add_nodes(atlas.nodes)
      grapher.render_graph
      graph_fs = `ls module-test.png`
      p(decorate(graph_fs))
      expect(graph_fs).to be
      expect(graph_fs.split.first).to eq("module-test.png")
    end

    it "graphs using graphs" do
      chaos_nav.record()
      Foo.foo
      Fubarm::Foom.foom
      recorded_atlas = chaos_nav.stop
      expect(recorded_atlas).to_not be_nil

      # Playback should graph:
      graphs = ChaosDetector::Graphing::Graphs.new(options: opts)
      expect(graphs.navigator).to_not be_nil

      graphs.playback()
      expect(graphs.atlas).to_not be_nil

      graphs.render_mod_dep()
      graph_fs = `ls module-dep.png`
      p(decorate(graph_fs))
      expect(graph_fs).to be
      expect(graph_fs.split.first).to eq("module-dep.png")
    end

  end

  describe "Utils" do
    it "should self-test" do
      TCS::Utils::CoreUtil.test
    end
  end
end
