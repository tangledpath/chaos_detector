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
require 'fixtures/fixture_relations'

shared_examples_for 'playback traverses fn_calls' do |expected_traversal_str|
  it 'should match traversal' do
    options = ChaosDetector::Options.new
    options.app_root_path = File.expand_path(__dir__)
    options.log_root_path = File.join('tmp', 'chaos_logs')
    options.path_domain_hash = { 'fixtures': 'FuDomain' }

    tracker = ChaosDetector::Tracker.new(options: options)
    nav = ChaosDetector::Navigator.new(options: options)

    tracker.record
    fn_calls
    tracker.stop

    nav_graph, mod_rel_graph = nav.playback
    traversal_str = nav_graph.traversal.map(&:fn_name).join(' -> ')
    puts "Found traversal string: #{traversal_str}"
    expect(traversal_str).to eq(expected_traversal_str)
  end
end

describe 'ChaosGrapher' do
  let(:chaos_options) do
    ChaosDetector::Options.new.tap do |opts|
      opts.app_root_path = File.expand_path(__dir__)
      opts.log_root_path = File.join('tmp', 'chaos_logs')
      opts.path_domain_hash = { 'fixtures': 'FuDomain' }
      opts.graph_render_folder = File.join('render')
    end
  end

  let(:chaos_tracker) { ChaosDetector::Tracker.new(options: chaos_options) }
  let(:chaos_nav) { ChaosDetector::Navigator.new(options: chaos_options) }

  let(:simple_tracking) do
    chaos_tracker.record
    Foo.foo
    Fubarm::Foom.foom
    chaos_tracker.stop
  end

  let(:simple_tracking) do
    chaos_tracker.record
    Foo.foo
    Fubarm::Foom.foom
    chaos_tracker.stop
  end

  let(:associated_tracking) do
    chaos_tracker.record
    fracker = DerivedFracker.new
    fracker.frack
    chaos_tracker.stop
  end

  let(:graphing) do
    simple_tracking
    chaos_nav.playback
  end

  it 'domain graphs' do
    chaos_graph = ChaosDetector::ChaosGraphs::ChaosGraph.new(*graphing)
    chaos_graph.infer_all

    grapher = ChaosDetector::Graphing::Directed.new(render_folder: chaos_options.path_with_root(path: 'render'))
    grapher.create_directed_graph('domain-test')

    grapher.append_nodes(chaos_graph.domain_nodes)
    grapher.add_edges(chaos_graph.domain_edges)

    grapher.render_graph
    graph_fs = `ls spec/render/domain-test.png`
    p(ChaosUtils.decorate(graph_fs))
    expect(graph_fs).to be
    expect(graph_fs.split.first).to eq('spec/render/domain-test.png')
  end

  describe 'simple traversals' do
    it_should_behave_like 'playback traverses fn_calls', 'ROOT -> foo -> bar -> baz -> foom -> barm -> bazm' do
      let(:fn_calls) do
        Foo.foo
        Fubarm::Foom.foom
      end
    end
    it_should_behave_like 'playback traverses fn_calls', 'ROOT -> foom -> barm -> bazm -> foo -> bar -> baz' do
      let(:fn_calls) do
        Fubarm::Foom.foom
        Foo.foo
      end
    end
  end

  describe 'nested traversals' do
    # it_should_behave_like 'playback traverses fn_calls', 'ROOT -> nester1 -> nest2 -> nest3 -> nest4 -> nest4' do
    #   let(:fn_calls) do
    #     Fubarm::Bazm.nester1
    #   end
    # end

    it_should_behave_like 'playback traverses fn_calls', 'ROOT -> nester1 -> nest2 -> nest3 -> nest2 -> nest4 -> nest2 -> nest4 -> nest2' do
      let(:fn_calls) do
        Fubarm::Bazm.nester1(recurse: true)
      end

      it 'should do fn graph' do
        graphs = ChaosDetector::Graphing::Graphs.new(options: chaos_options)
        expect(graphs.navigator).to_not be_nil

        graphs.playback
        expect(graphs.chaos_graph).to_not be_nil

        graphs.render_fn_dep
      end
    end
  end

  describe 'module graphs' do
    it 'renders' do
      chaos_graph = ChaosDetector::ChaosGraphs::ChaosGraph.new(*graphing)
      chaos_graph.infer_all

      grapher = ChaosDetector::Graphing::Directed.new(render_folder: chaos_options.path_with_root(path: 'render'))
      grapher.create_directed_graph('module-test')

      grapher.append_nodes(chaos_graph.module_nodes)

      chaos_graph.module_nodes.each do |n|
        p("ModNode: #{ChaosUtils.decorate(n.label)}")
      end

      chaos_graph.module_edges.each do |e|
        p("ModEdge: #{ChaosUtils.decorate(e.src_node.class)} -> #{ChaosUtils.decorate(e.dep_node.class)}")
      end
      grapher.add_edges(chaos_graph.module_edges)

      grapher.render_graph
      graph_fs = `ls spec/render/module-test.png`
      p(ChaosUtils.decorate(graph_fs))
      expect(graph_fs).to be
      expect(graph_fs.split.first).to eq('spec/render/module-test.png')
    end

    it 'module deps using graphs' do
      walkman = simple_tracking
      expect(walkman).to_not be_nil

      # Playback should graph:
      graphs = ChaosDetector::Graphing::Graphs.new(options: chaos_options)
      expect(graphs.navigator).to_not be_nil

      graphs.playback
      expect(graphs.chaos_graph).to_not be_nil

      graphs.render_mod_dep
      graph_fs = `ls spec/render/module-dep.png`
      p(ChaosUtils.decorate(graph_fs))
      expect(graph_fs).to be
      expect(graph_fs.split.first).to eq('spec/render/module-dep.png')
    end


    it 'is discovered' do
      walkman = associated_tracking
      expect(walkman).to_not be_nil

      # Playback should graph:
      graphs = ChaosDetector::Graphing::Graphs.new(options: chaos_options)
      expect(graphs.navigator).to_not be_nil

      graphs.playback
      expect(graphs.chaos_graph).to_not be_nil

      graphs.render_mod_dep(graph_name: 'module-rel-dep')
      graph_fs = `ls spec/render/module-rel-dep.png`
      p(ChaosUtils.decorate(graph_fs))
      expect(graph_fs).to be
      expect(graph_fs.split.first).to eq('spec/render/module-rel-dep.png')
    end
  end

  describe 'domain dependencies' do
    it 'domain deps using graphs' do
      walkman = simple_tracking
      expect(walkman).to_not be_nil

      # Playback should graph:
      graphs = ChaosDetector::Graphing::Graphs.new(options: chaos_options)
      expect(graphs.navigator).to_not be_nil

      graphs.playback
      expect(graphs.chaos_graph).to_not be_nil

      graphs.render_domain_dep
      graph_fs = `ls spec/render/domain-dep.png`
      p(ChaosUtils.decorate(graph_fs))
      expect(graph_fs).to be
      expect(graph_fs.split.first).to eq('spec/render/domain-dep.png')
    end

    # TODO: maybe extract all unique paths from graph struture?
    # chaos_tracker.record
    # fracker = DerivedFracker.new
    # fracker.frack
    # chaos_tracker.stop

    # super_event = chaos_walkman.frames_within.find{|f| f.event==:superclass}
    # expect(super_event).to_not be_nil
    # expect(super_event.event).to eq(:superclass)
    # expect(super_event.caller_info).to_not be_nil
    # expect(super_event.caller_info.mod_name).to eq('SuperFracker')
    # expect(super_event.caller_info.class).to eq(ChaosDetector::Stacker::ModInfo)


    # ab_frame = chaos_walkman.frames_within.find do |f|
    #   f.caller_info&.mod_name == 'MixinAB' rescue nil
    # end

    # cd_frame = chaos_walkman.frames_within.find do |f|
    #   f.caller_info&.mod_name == 'MixinCD' rescue nil
    # end

    # ad_frame = chaos_walkman.frames_within.find do |f|
    #   f.caller_info&.mod_name == 'MixinAD' rescue nil
    # end

    # expect(ab_frame).to_not be_nil
    # expect(ad_frame).to_not be_nil
    # expect(cd_frame).to_not be_nil

    # expect(ab_frame.event).to eq(:association)
    # expect(ad_frame.event).to eq(:association)
    # expect(cd_frame.event).to eq(:class_association)

    # puts 'TOTAL FRAMES: %d' % chaos_walkman.count
    # chaos_walkman.playback { |r,f| puts("#{r}: #{f}") }

  end
end
